#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( pwd; )/$( dirname -- $0; )"
cd "${SCRIPT_DIR}"
FIND="find"

mkdir -p fixtures
# Brew installs GNU find as "gfind" by default
if command -v gfind >/dev/null 2>&2; then
    FIND="$(which gfind)"
fi

do_the_test() {
    local i="${1}"
    echo "☆☆☆☆☆☆☆☆☆☆ $i ☆☆☆☆☆☆☆☆☆☆"
    helm template -f $i --dry-run mail > fixtures/demo.yaml
    docker run \
        -v "${SCRIPT_DIR}/fixtures:/fixtures" \
        -v "${SCRIPT_DIR}/schemas:/schemas" \
        garethr/kubeval \
            --force-color \
            --additional-schema-locations file:///schemas \
            fixtures/demo.yaml
}


if [[ $# -gt 0 ]]; then
    while [[ $# -gt 0 ]]; do
        do_the_test "${1}"
        shift
    done
else
    for i in `${FIND} -maxdepth 1 -type f -name test\*yml | sort`; do
        do_the_test "${i}"
    done
fi