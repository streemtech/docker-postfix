#!/usr/bin/env bash
set -e

local arch="$(uname -m)"

# Build the sasl2 library with the sasl-xoauth2 plugin.
#
# The sasl-xoauth2 plugin is a SASL plugin that provides support for XOAUTH2 (OAuth 2.0) authentication.
#
# The build is done in /sasl-xoauth2/build.
#
# This script clones the sasl-xoauth2 repository, applies patches to:
# - remove the build of the documentation
# - fix the path to the python interpreter in the sasl-xoauth2-tool
# - fix the path to the library when building on Alpine
#
# After building and installing the sasl2 library with the sasl-xoauth2 plugin, the
# postfix-sasl-xoauth2-update-ca-certs script is installed into the /etc/ca-certificates/update.d directory.
# This script is run by the update-ca-certificates command to update the list of trusted certificates.
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

# Installs rust. Debian bookwork comes with an old version of rust, so we can't use the one from the repository.
# Rust is needed, though for installation of msal library. On some architectures, we cannot use pre-compiled packages
# (because they don't exist in the PIP repositories) and "pip install" will fail without rust. Specifically, when
# compiling cryptographic libraries.
setup_rust() {
	if [[ "${arch}"!= "386" ]] && [[ "${arch}"!= "i386" ]] && [[ "${arch}"!= "mips64el" ]]; then
		curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
		export PATH="$HOME/.cargo/bin:$PATH"
		. "$HOME/.cargo/env"
	fi
}

# Create a virtual environment and install the msal library for the
# sasl-xoauth2-tool.
setup_python_venv() {
	python3 -m venv /sasl
	. /sasl/bin/activate
	if [[ "${arch}"!= "386" ]] && [[ "${arch}"!= "i386" ]] && [[ "${arch}"!= "mips64el" ]]; then
		pip3 install msal
	fi
}

# Installs the base components into the docker image:
#
# 1. sasl2 using the sasl-xoauth2 plugin
# 2. a python virtual environment with the msal library
base_install() {
	build_sasl2
	setup_python_venv
}


[ -f /etc/lsb-release ] && . /etc/lsb-release
[ -f /etc/os-release ] && . /etc/os-release

# Determine the base installation method based on the OS.
# Alpine Linux has a different package management system than Debian-based systems.
if [ -f /etc/alpine-release ]; then
	# Install necessary libraries
	LIBS="git cmake clang make gcc g++ libc-dev pkgconfig curl-dev jsoncpp-dev cyrus-sasl-dev patch libffi-dev python3-dev rust cargo"
	apk add --upgrade curl
	apk add --upgrade --virtual .build-deps ${LIBS}

	# Run compilation and installation
	base_install

	# Cleanup. This is important to ensure that we don't keep unnecessary files laying around and thus increasing the size of the image.
	apk del .build-deps;
else
	# Install necessary libraries
	apt-get update -y -qq
	LIBS="git build-essential cmake pkg-config libcurl4-openssl-dev libssl-dev libjsoncpp-dev libsasl2-dev python3-dev python3-venv"
	apt-get install -y --no-install-recommends ${LIBS}

	# Run compilation and installation
	setup_rust
	base_install
	if [[ "${arch}"!= "386" ]] && [[ "${arch}"!= "i386" ]] && [[ "${arch}"!= "mips64el" ]]; then
		rustup self uninstall -y
	fi

	# Cleanup. This is important to ensure that we don't keep unnecessary files laying around and thus increasing the size of the image.
	apt-get remove --purge -y ${LIBS} python3-venv
	apt-get autoremove --yes
	apt-get clean autoclean
fi

