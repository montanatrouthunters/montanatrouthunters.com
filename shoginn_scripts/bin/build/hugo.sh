#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

__script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${__script_dir}"/../functions/shoginn_scripts.sh

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    emergency "Don't source this code."
else
    start_hugo
    exit ${?}
fi
