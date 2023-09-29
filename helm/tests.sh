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

for i in `${FIND} -maxdepth 1 -type f -name test\*yml | sort`; do
    echo "☆☆☆☆☆☆☆☆☆☆ $i ☆☆☆☆☆☆☆☆☆☆"
    helm template -f $i --dry-run mail > fixtures/demo.yaml
    docker run \
        -it \
        -v "${SCRIPT_DIR}/fixtures:/fixtures" \
        -v "${SCRIPT_DIR}/schemas:/schemas" \
        garethr/kubeval \
            --additional-schema-locations file:///schemas \
            fixtures/demo.yaml
done
