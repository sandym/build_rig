#!/bin/sh

cd $(dirname "$0")
IMAGES=$(cd ../images ; pwd)

. ../.env

cd "${IMAGES}/alpine"
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t alpine_builder .
cd "${IMAGES}/ubuntu"
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t ubuntu_builder .
cd "${IMAGES}/ubuntu_lts"
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t ubuntu_lts_builder .
cd "${IMAGES}/centos7"
docker build --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg NINJA_VERSION=${NINJA_VERSION} -t centos7_builder .

docker volume create build_rig_work
