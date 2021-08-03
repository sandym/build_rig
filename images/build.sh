#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

NINJA_VERSION=v1.10.2
CMAKE_VERSION=3.21.1

cd "${IMAGES}/alpine" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t alpine_builder .
cd "${IMAGES}/ubuntu" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t ubuntu_builder .
cd "${IMAGES}/ubuntu_lts" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t ubuntu_lts_builder .
cd "${IMAGES}/centos9" || exit -1
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t centos9_builder .

docker volume create build_rig_work
