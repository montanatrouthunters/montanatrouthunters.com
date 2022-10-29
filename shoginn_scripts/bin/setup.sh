#!/usr/bin/env bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=functions/shoginn_scripts.sh
source "${__dir}"/functions/shoginn_scripts.sh
__HUGO_SCRIPT="./${__DESTINATION_FOLDER:-shoginn_scripts/}bin/build/hugo.sh"

function _add_packages() {
    __dev_packages=(
        rimraf
        npm-run-all
        cross-env
    )
    info "Adding the required dev packages: ${__dev_packages[*]}"

    for __item in "${__dev_packages[@]}"; do
        debug "Adding ${__item}"
        npm install "$__item" --save-dev >>/dev/null
    done
}
function _copy_netlify_toml() {
    if [[ -e "${__NETLIFY_TOML}" ]]; then
        notice "This is your old Netlify Config Copy it now or forever lose it!"
        printf "\n\n"
        cat "${__NETLIFY_TOML}"
        printf "\n\n"
        notice "End of Netlify File"
    fi
    cp "${__dir}"/../etc/.netlify.template "${__NETLIFY_TOML}"
    update_netlify "${__NETLIFY_TOML}"
}
function add_package_scripts() {
    _add_packages
    if [[ "${CI:-}" ]]; then
        debug "CI environment detected. Skipping Netlify Config"
    else
        _copy_netlify_toml

    fi
    info "Setting up the npm scripts!"
    npm pkg set scripts.clean:hugo="rimraf hugo{.log,_stats.json} resources public assets/jsconfig.json .hugo_build.lock _vendor"
    npm pkg set scripts.serve="run-s serve:hugo"
    npm pkg set scripts.build="run-s build:hugo"
    npm pkg set scripts._start:_hugo="${__HUGO_SCRIPT}"
    npm pkg set scripts.serve:hugo="cross-env SHOGINN_SCRIPTS_SERVE_HUGO=1 run-s _start:_hugo"
    npm pkg set scripts.build:hugo="cross-env SHOGINN_SCRIPTS_BUILD_HUGO=1 run-s clean:hugo _start:_hugo"
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    emergency "Do not Source this file!"
else
    export REQUIRED_TOOLS=(
        npm
    )
    required_tools "NPM Functions"

    add_package_scripts
    exit ${?}
fi
