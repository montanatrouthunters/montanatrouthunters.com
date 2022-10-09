#!/usr/bin/env bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../functions/core.sh
source "${__dir}"/../functions/core.sh

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    info "Updating the Netlify TOML with the latest HUGO verion"
else
    if [[ ! ${1:-} ]]; then
        error "Specify the Netlify.toml file location"
        exit 1
    else
        update_netlify "${1:-}"
    fi
    exit ${?}
fi
