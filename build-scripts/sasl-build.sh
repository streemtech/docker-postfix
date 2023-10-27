#!/bin/sh
set -e

build_pandoc() {
    CAN_INSTALL=1
    if [ -f /etc/alpine-release ]; then
        if ! apk add --upgrade pandoc; then
            CAN_INSTALL=0
        fi
    else
        if ! apt-get install -y --no-install-recommends; then
            CAN_INSTALL=0
        fi
    fi
    if [ -f /etc/alpine-release ]; then
        apk add --upgrade cabal curl llvm
    else
        apt-get install -y --no-install-recommends cabal curl llvm
    fi
    mkdir pandoc
    curl --retry 5 --max-time 300 --connect-timeout 10 -fsSL https://github.com/jgm/pandoc/archive/refs/tags/3.1.8.tar.gz | tar xvzf - --strip-components 1 -C pandoc
    cd pandoc
    cabal update
    cabal install --only-dependencies --lib
    cabal configure \
        --enable-optimization=2 \
        --disable-tests \
        --disable-documentation \
        --disable-benchmarks \
        --disable-coverage \
        --disable-library-stripping \
        --disable-executable-stripping \
        --disable-profiling \
        --enable-static
    cabal build
}

build_sasl2() {
    git clone --depth 1 --branch ${SASL_XOAUTH2_GIT_REF} ${SASL_XOAUTH2_REPO_URL} /sasl-xoauth2
    cd /sasl-xoauth2
    mkdir build
    cd build
    if [ -f /etc/alpine-release ]; then
        patch -p1 -d .. < /build-scripts/sasl-xoauth2.diff
        cmake -DCMAKE_INSTALL_PREFIX=/ ..
    else
        cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    fi
    make
    make install
    install ../scripts/postfix-sasl-xoauth2-update-ca-certs /etc/ca-certificates/update.d
    update-ca-certificates
}

if [ -f /etc/alpine-release ]; then
    apk add --upgrade --virtual .build-deps git cmake clang make gcc g++ libc-dev pkgconfig curl-dev jsoncpp-dev cyrus-sasl-dev patch
    build_pandoc
    build_sasl2
    apk del .build-deps;
else
    [ -f /etc/lsb-release ] && . /etc/lsb-release
    [ -f /etc/os-release ] && . /etc/os-release
    apt-get update -y -qq
    LIBS="git build-essential cmake pkg-config libcurl4-openssl-dev libssl-dev libjsoncpp-dev libsasl2-dev"
    apt-get install -y --no-install-recommends ${LIBS}
    build_pandoc
    build_sasl2
    apt-get remove --purge -y ${LIBS}
    apt-get autoremove --yes
    apt-get clean autoclean
fi

