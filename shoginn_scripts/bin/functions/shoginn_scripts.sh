#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  emergency "This is not a CLI script."
fi

# Set magic variables for current file, directory, os, etc.
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the environment variables (and their defaults) that this script depends on
LOG_LEVEL="${LOG_LEVEL:-6}" # 7 = debug -> 0 = emergency
NO_COLOR="${NO_COLOR:-}"    # true = disable color. otherwise autodetected
__ENV_FILE="${__dir}"/../etc/.env
__REPLACEMENTS="${__dir}"/../etc/.replacements
__LIB_DIR="${__dir}"/../bin/lib/
__NETLIFY_TOML="./netlify.toml"

### Functions
##############################################################################

function __b3bp_log() {
  local log_level="${1}"
  shift

  # shellcheck disable=SC2034
  local color_debug="\\x1b[35m"
  # shellcheck disable=SC2034
  local color_info="\\x1b[32m"
  # shellcheck disable=SC2034
  local color_notice="\\x1b[34m"
  # shellcheck disable=SC2034
  local color_warning="\\x1b[33m"
  # shellcheck disable=SC2034
  local color_error="\\x1b[31m"
  # shellcheck disable=SC2034
  local color_critical="\\x1b[1;31m"
  # shellcheck disable=SC2034
  local color_alert="\\x1b[1;37;41m"
  # shellcheck disable=SC2034
  local color_emergency="\\x1b[1;4;5;37;41m"

  local colorvar="color_${log_level}"

  local color="${!colorvar:-${color_error}}"
  local color_reset="\\x1b[0m"

  if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]]; } || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""
      color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_line=""

  while IFS=$'\n' read -r log_line; do
    echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%9s]" "${log_level}")${color_reset} ${log_line}" 1>&2
  done <<<"${@:-}"
}

function emergency() {
  __b3bp_log emergency "${@}"
  exit 1
}
function alert() {
  [[ "${LOG_LEVEL:-0}" -ge 1 ]] && __b3bp_log alert "${@}"
  true
}
function critical() {
  [[ "${LOG_LEVEL:-0}" -ge 2 ]] && __b3bp_log critical "${@}"
  true
}
function error() {
  [[ "${LOG_LEVEL:-0}" -ge 3 ]] && __b3bp_log error "${@}"
  true
}
function warning() {
  [[ "${LOG_LEVEL:-0}" -ge 4 ]] && __b3bp_log warning "${@}"
  true
}
function notice() {
  [[ "${LOG_LEVEL:-0}" -ge 5 ]] && __b3bp_log notice "${@}"
  true
}
function info() {
  [[ "${LOG_LEVEL:-0}" -ge 6 ]] && __b3bp_log info "${@}"
  true
}
function debug() {
  [[ "${LOG_LEVEL:-0}" -ge 7 ]] && __b3bp_log debug "${@}"
  true
}

### Validation. Error out if the things required for your script are not present
##############################################################################

[[ "${LOG_LEVEL:-}" ]] || emergency "Cannot continue without LOG_LEVEL. "

### The actual Functions
##############################################################################

function required_tools() {
  if [[ -n ${REQUIRED_TOOLS[0]+x} ]]; then
    if [[ -z ${__internal_tool+x} ]]; then
      info "Checking for the required tools necessary to ${*}"
    fi
    for __tool in "${REQUIRED_TOOLS[@]}"; do
      if ! command -v "${__tool}" >/dev/null; then
        emergency "${__tool} is required... "
      fi
    done
  fi
}
function __script_env() {
  if [[ -f "${__ENV_FILE}" ]]; then
    set -a
    info "Loading Environment file"
    # shellcheck source=/dev/null
    source "${__ENV_FILE}"
    set +a
    debug "$(env -0 | sort -z | tr '\0' '\n' | grep ^SHOGINN)"
    return
  else
    debug "No env file found"
  fi
}
function __load_lib() {
  for __file in "${__LIB_DIR}"*; do
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
  if [ ! -f "${__NETLIFY_TOML}" ]; then
    debug "Could not find file using arg"
    __NETLIFY_TOML="${1}"
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
  if [ -f "${__NETLIFY_TOML}" ]; then
    __current_version=$(sed <"${__NETLIFY_TOML}" -n 's/^HUGO_VERSION = //p' | tr -d "\"")
    info "Current Netlify Hugo version configured is ${__current_version}"
    if [ "$__current_version" != "$__latest_version" ]; then
      info "Updating the netlify.toml to the latest Hugo version ${__latest_version}."
      sed -i.bak -e "s/HUGO_VERSION = .*/HUGO_VERSION = \"$__latest_version\"/g" "${__NETLIFY_TOML}" && rm -f "${__NETLIFY_TOML}".bak
    fi
  else
    warning "Could not check your netlify config because you dont have a netlify config"
  fi
}

## Old hugo
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
  info "Checking for Module replacements."
  debug Replacement File: "${__REPLACEMENTS}"

  if [[ -f "${__REPLACEMENTS}" ]]; then
    debug "Found some replacements"
    while read -ra __; do
      if $__not_first_line; then
        __hugo_module_replacements="${__hugo_module_replacements},${__[0]} -> ${__[1]}"
      else
        __hugo_module_replacements="${__[0]} -> ${__[1]}"
        __not_first_line=true
      fi
    done <"${__REPLACEMENTS}"
    # shellcheck disable=SC2015
    [[ -n "${__hugo_module_replacements}" ]] && export HUGO_MODULE_REPLACEMENTS="${__hugo_module_replacements}" || info "No replacements found"
  fi
  debug "ENV for HUGO_MODULE\n $(env | grep ^HUGO_MODULE)"
}

function __hugo_env() {
  info "Settings up the Hugo Environment"
  __script_env
  __module_replacements

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
      --logLevel debug
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
    )
    __hugo_args+=("${__hugo_build_args[@]}")
    debug "Building Hugo"
  fi
  if [[ ${SHOGINN_SCRIPTS_SERVE_HUGO:-} ]]; then
    __hugo_build_args=(
      --minify
      --cleanDestinationDir
      --enableGitInfo
    )
    __hugo_args+=("${__hugo_build_args[@]}")
    __hugo_args=("server" "${__hugo_args[@]}")
    debug "Starting the Hugo Server"
  fi
  if [[ "${SHOGINN_SCRIPTS_TEST:-}" ]]; then
    notice "Test Mode is on; Hugo commands will echo."
    __scripts_hugo_cmd="info"
  else
    __scripts_hugo_cmd="hugo"
  fi
}

function start_hugo() {
  if [[ ${SHOGINN_SCRIPTS_SERVE_HUGO:-} || ${SHOGINN_SCRIPTS_BUILD_HUGO:-} ]]; then
    __internal_tool=1
    local REQUIRED_TOOLS=(
      npm
    )
    required_tools "HUGO"
    # starting hugo server
    __hugo_env
    trap "{ echo 'Terminated with Ctrl+C'; }" SIGINT
    refresh_hugo
    info "Starting HUGO"
    debug Hugo ARGS: "${__hugo_args[@]}"
    "${__scripts_hugo_cmd}" "${__hugo_args[@]}" 2>&1 | tee -a hugo.log
  else
    emergency "You must set the proper HUGO variables to use this function see README"
  fi
}
