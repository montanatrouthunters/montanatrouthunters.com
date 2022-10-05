#!/usr/bin/env bash

REQUIRED_TOOLS=(
    cat
)

for TOOL in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "${TOOL}" >/dev/null; then
        echo "${TOOL} is required... "
        exit 1
    fi
done

get_latest_release() {
    curl --silent "https://api.github.com/repos/gohugoio/hugo/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"v([^"]+)".*/\1/'
}

cat <<EOF
[build]
publish = "public"

[build.environment]
GO_VERSION = "1.19"
HUGO_VERSION = "$(get_latest_release)"
HUGO_ENABLEGITINFO = "true"

[context.production]
command = "./bin/netlify/build.sh \$URL"

[context.production.environment]
HUGO_ENV = "production"
WC_POST_CSS = "true"

[context.deploy-preview]
command = "./bin/netlify/build.sh \$DEPLOY_PRIME_URL"
HUGO_BUILDFUTURE = "true"

[context.branch-deploy]
command = "./bin/netlify/build.sh \$DEPLOY_PRIME_URL"

[[plugins]]
package = "netlify-plugin-hugo-cache-resources"

[plugins.inputs]
debug = true
EOF
