#!/usr/bin/env bash
__script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../functions/shoginn_scripts.sh
source "${__script_dir}"/../functions/shoginn_scripts.sh

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    emergency "Don't source this code."
else
    if [[ ! ${1:-} ]]; then
        emergency "Specify the Netlify.toml file location"
    else
        update_netlify "${1:-}"
    fi
    exit ${?}
fi
