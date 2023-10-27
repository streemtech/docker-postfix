#!/bin/sh
set -e
set -x

if ! hash netstat; then
    echo "netstat not found!" >2
    exit 1
fi

if ! hash nc; then
    echo "netcat not found!" >2
    exit 1
fi