#!/bin/sh
set -e

do_build() {
    git clone --depth 1 --branch ${SASL_XOAUTH2_GIT_REF} ${SASL_XOAUTH2_REPO_URL} /sasl-xoauth2
    cd /sasl-xoauth2
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=/ ..
    make
    make install
}

if [ -f /etc/alpine-release ]; then
    apk add --upgrade --virtual .build-deps git cmake clang make gcc g++ libc-dev pkgconfig curl-dev jsoncpp-dev cyrus-sasl-dev
    do_build
    apk del .build-deps;
else
    . /etc/lsb-release
    apt-get update -y -qq
    LIBS="git build-essential cmake pkg-config libcurl4 libcurl4-openssl-dev libssl-dev libjsoncpp-dev libsasl2-dev"
    apt-get install -y --no-install-recommends ${LIBS}
    do_build
    apt-get remove --purge -y ${LIBS}
    apt-get autoremove --yes
    apt-get clean autoclean
fi

