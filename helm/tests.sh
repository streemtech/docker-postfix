#!/usr/bin/env bash
set -e
mkdir -p fixtures

FIND="find"
# Brew installs GNU find as "gfind" by default
if command -v gfind >/dev/null 2>&2; then
    FIND="$(which gfind)"
fi

for i in `${FIND} -maxdepth 1 -type f -name test\*yml | sort`; do
    echo "☆☆☆☆☆☆☆☆☆☆ $i ☆☆☆☆☆☆☆☆☆☆"
    helm template -f $i --dry-run mail > fixtures/demo.yaml
    docker run -it -v `pwd`/fixtures:/fixtures garethr/kubeval fixtures/demo.yaml
done
