#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

NINJA_VERSION=$(ninja --version)
CMAKE_VERSION=$(cmake --version | perl -n -e 'print $1 if(/cmake version\s(\S+)\s*$/)')

cd "${IMAGES}/alpine" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} -t alpine_builder .
cd "${IMAGES}/ubuntu" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} -t ubuntu_builder .
cd "${IMAGES}/ubuntu_lts" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} -t ubuntu_lts_builder .
cd "${IMAGES}/centos7" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t centos7_builder .
cd "${IMAGES}/centos9" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t centos9_builder .

docker volume create build_rig_work
