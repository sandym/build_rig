#!/bin/sh

cd $(dirname "$0")
ROOT=$(cd .. ; pwd)

NINJA_VERSION=$(ninja --version)
CMAKE_VERSION=$(cmake --version | perl -n -e 'print $1 if(/cmake version\s(\S+)\s*$/)')

cd "${ROOT}/" || exit 1

docker compose build
