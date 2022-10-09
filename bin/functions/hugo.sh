#!/usr/bin/env bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

__helptext=false
__usage=false

# shellcheck source=main.sh
source "${__dir}"/main.sh

function refresh_hugo() {
    # cleanup hugo logging
    npm run clean:hugo

    # update modules
    "${__scripts_hugo_cmd}" mod get -u ./...

    # tidy up modules
    "${__scripts_hugo_cmd}" mod tidy

}

function __module_replacements() {
    # create replacements via environment
    __not_first_line=false
    __hugo_module_replacements=""
    __replacements="${__dir}"/../etc/.replacements
    info "Checking for Module replacements."
    debug Replacement File: "${__replacements}"

    if test -f "${__replacements}"; then
        debug "Found some replacements"
        while read -ra __; do
            if $__not_first_line; then
                __hugo_module_replacements="${__hugo_module_replacements},${__[0]} -> ${__[1]}"
            else
                __hugo_module_replacements="${__[0]} -> ${__[1]}"
                __not_first_line=true
            fi
        done <"${__replacements}"
        # shellcheck disable=SC2015
        [[ -n "${__hugo_module_replacements}" ]] && export HUGO_MODULE_REPLACEMENTS="${__hugo_module_replacements}" || info "No replacements found"
    fi
    debug "$(env | grep ^HUGO_MODULE)"
}
function __hugo_env() {
    info "Settings up the Hugo Environment"

    __type="${SHOGINN_SCRIPTS_NETLIFY:-}"
    if [[ ${__type:-} ]]; then
        if [[ ${__type} == "URL" ]]; then
            info "Base URL Set to ${URL:-}"
            __hugo_args+=("--baseURL=${URL:-}")
        fi
        if [[ ${__type} == "DEPLOY" ]]; then
            info "Base URL Set to ${DEPLOY_PRIME_URL:-}"
            __hugo_args+=("--baseURL=${DEPLOY_PRIME_URL:-}")
        fi
    fi

    if [[ "${SHOGINN_SCRIPTS_HUGO_BASE_URL:-}" ]]; then
        info "Base URL Set to ${SHOGINN_SCRIPTS_HUGO_BASE_URL}"
        __hugo_args+=("--baseURL=${SHOGINN_SCRIPTS_HUGO_BASE_URL}")
    fi
    if [[ "${SHOGINN_SCRIPTS_HUGO_DEBUG:-}" ]]; then
        info "Debugging ON"
        __hugo_args+=("--debug")
    else
        info "Debugging OFF"
    fi
    if [[ "${SHOGINN_SCRIPTS_HUGO_VERBOSE:-true}" || "${SHOGINN_SCRIPTS_HUGO_DEBUG:-}" ]]; then
        info "Verbose ON"
        __hugo_verbose=(
            --templateMetrics
            --templateMetricsHints
            --printI18nWarnings
            --printMemoryUsage
            --printPathWarnings
            --printUnusedTemplates
            --verbose
            --verboseLog
        )
        __hugo_args+=("${__hugo_verbose[@]}")
    else
        info "Verbose OFF"
    fi

    if [[ "${SHOGINN_SCRIPTS_SERVER_FUTURE:-}" ]]; then
        info "Future Posts ON"
        __hugo_args+=("--buildFuture")
    else
        info "Future Posts OFF"
    fi
    if [[ "${SHOGINN_SCRIPTS_SERVER_EXPIRED:-}" ]]; then
        info "Expired Posts ON"
        __hugo_args+=("--buildExpired")
    else
        info "Expired Posts OFF"
    fi
    if [[ "${SHOGINN_SCRIPTS_SERVER_DRAFTS:-}" ]]; then
        info "Draft Posts ON"
        __hugo_args+=("--buildDrafts")
    else
        info "Draft Posts OFF"
    fi
    if [[ ${SHOGINN_SCRIPTS_BUILD_HUGO:-} ]]; then
        __hugo_build_args=(
            --minify
            --cleanDestinationDir
            --enableGitInfo
            --log=true
            --logFile hugo.log
        )
        __hugo_args+=("${__hugo_build_args[@]}")
        debug "Building Hugo"
    fi
    if [[ ${SHOGINN_SCRIPTS_SERVE_HUGO:-} ]]; then
        __hugo_build_args=(
            --minify
            --cleanDestinationDir
            --enableGitInfo
            --log=true
            --logFile hugo.log
        )
        __hugo_args+=("${__hugo_build_args[@]}")
        __hugo_args=("server" "${__hugo_args[@]}")
        debug "Starting the Hugo Server"
    fi
    if [[ "${SHOGINN_SCRIPTS_TEST:-}" ]]; then
        notice "Test Mode is on; Hugo commands will echo."
        export __scripts_hugo_cmd="info"
    else
        export __scripts_hugo_cmd="hugo"
    fi

    export __hugo_args
    __module_replacements
}

function start_hugo() {
    # starting hugo server
    trap "{ echo 'Terminated with Ctrl+C'; }" SIGINT
    refresh_hugo
    debug Hugo ARGS: "${__hugo_args[@]}"
    "${__scripts_hugo_cmd}" "${__hugo_args[@]}" 2>&1 | tee -a hugo.log
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export REQUIRED_TOOLS=(
        hugo
        npm
        export
        trap
    )
    required_tools "Hugo Functions"
    info "Loading Hugo functions."
    __hugo_env
else

    exit ${?}
fi
