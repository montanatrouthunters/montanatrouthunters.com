#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

__helptext=false
__usage=false

# shellcheck source=main.sh
source "${__dir}"/main.sh

function required_tools() {
    if [[ -n ${REQUIRED_TOOLS[0]+x} ]]; then
        if [[ -z ${__internal_tool+x} ]]; then
            info "Checking for the required tools necessary to ${*}"
        fi
        for __tool in "${REQUIRED_TOOLS[@]}"; do
            if ! command -v "${__tool}" >/dev/null; then
                warning "${__tool} is required... "
                exit 1
            fi
        done
    fi
}
function script_env() {
    __env_file="${__dir}"/../etc/.env
    if [[ -f "${__env_file}" ]]; then
        set -a
        info "Loading Environment file"
        # shellcheck source=/dev/null
        source "${__env_file}"
        set +a
        debug "$(env -0 | sort -z | tr '\0' '\n' | grep ^SHOGINN)"
        return
    fi
}
function load_lib() {
    for __file in "${__dir}"/../bin/lib/*; do
        set -a
        # this routine ranges through a folder of files that we don't explicitly know (@davidsneighbour)
        # see https://github.com/koalaman/shellcheck/wiki/SC1090
        # shellcheck source=/dev/null
        source "${__file}"
        set +a
    done
}

function update_netlify() {
    __internal_tool=1
    local REQUIRED_TOOLS=(
        curl
        sed
        grep
    )
    __netlify_toml="./netlify.toml"
    if [ ! -f "${__netlify_toml}" ]; then
        debug "Could not find file using arg"
        __netlify_toml="${1}"
    fi
    required_tools "Update Netlify TOML"
    function __get_latest_release() {
        curl --silent "https://api.github.com/repos/gohugoio/hugo/releases/latest" |
            grep '"tag_name":' |
            sed -E 's/.*"v([^"]+)".*/\1/'
    }
    info "Attempting to get latest Hugo version from the gohugio repo..."
    __latest_version=$(__get_latest_release)
    info "Latest Hugo version is ${__latest_version}"
    # - Update Netlify.toml with required Hugo version
    if [ -f "${__netlify_toml}" ]; then
        __current_version=$(sed <"${__netlify_toml}" -n 's/^HUGO_VERSION = //p' | tr -d "\"")
        info "Current Netlify Hugo version configured is ${__current_version}"
        if [ "$__current_version" != "$__latest_version" ]; then
            info "Updating the netlify.toml to the latest Hugo version ${__latest_version}."
            sed -i.bak -e "s/HUGO_VERSION = .*/HUGO_VERSION = \"$__latest_version\"/g" "${__netlify_toml}" && rm -f "${__netlify_toml}".bak
        fi
    else
        warning "Could not check your netlify config because you dont have a netlify config"
    fi
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    script_env
    info "Loading Core functions."
else
    exit ${?}
fi
