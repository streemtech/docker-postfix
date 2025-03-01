#!/usr/bin/env bash
set -e

build_sasl2() {
	git clone --depth 1 --branch ${SASL_XOAUTH2_GIT_REF} ${SASL_XOAUTH2_REPO_URL} /sasl-xoauth2
	cd /sasl-xoauth2
	mkdir build
	cd build
	# Documentation build (now) requires pandoc, which is not available on multiple
	# architectures. Since we're are building an image that we want it to be as slim as possible,
	# we're removing the build of documentation instead of complicating things with pandoc.
	patch -p1 -d .. < /build-scripts/sasl-xoauth2-01.patch

	# Ensure that the sasl-xoauth2-tool uses python from the virtual environment into which we
	# installed the msal library.
	patch -p1 -d .. < /build-scripts/sasl-xoauth2-03.patch

	if [ -f /etc/alpine-release ]; then
		patch -p1 -d .. < /build-scripts/sasl-xoauth2-02.patch
		cmake -DCMAKE_INSTALL_PREFIX=/ ..
	else
		cmake -DCMAKE_INSTALL_PREFIX=/usr ..
	fi
	make
	make install
	install ../scripts/postfix-sasl-xoauth2-update-ca-certs /etc/ca-certificates/update.d
	update-ca-certificates
}

setup_python_venv() {
	python3 -m venv /sasl
	. /sasl/bin/activate
	pip3 install msal
}

[ -f /etc/lsb-release ] && . /etc/lsb-release
[ -f /etc/os-release ] && . /etc/os-release
if [ -f /etc/alpine-release ]; then
	apk add --upgrade --virtual .build-deps git cmake clang make gcc g++ libc-dev pkgconfig curl-dev jsoncpp-dev cyrus-sasl-dev patch
	setup_python_venv
	build_sasl2
	apk del .build-deps;
else
	apt-get update -y -qq
	LIBS="git build-essential cmake pkg-config libcurl4-openssl-dev libssl-dev libjsoncpp-dev libsasl2-dev python3-venv"
	apt-get install -y --no-install-recommends ${LIBS}
	setup_python_venv
	build_sasl2
	apt-get remove --purge -y ${LIBS}
	apt-get autoremove --yes
	apt-get clean autoclean
fi

