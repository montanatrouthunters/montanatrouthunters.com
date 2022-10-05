#!/usr/bin/env bash

REQUIRED_TOOLS=(
    hugo
    npm
)

for TOOL in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "${TOOL}" >/dev/null; then
        echo "${TOOL} is required... "
        exit 1
    fi
done
echo "Running Netlify Build"
hugo mod get -u ./...
hugo mod tidy
echo "Starting the Hugo Build"

source "./bin/build/hugo.sh"
