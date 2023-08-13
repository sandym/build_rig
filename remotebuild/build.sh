#!/bin/sh

REMOTEBUILD=$(dirname "$0")
REMOTEBUILD=$(cd "${REMOTEBUILD}" ; pwd)
cd "${REMOTEBUILD}/.."


if [ ! -f "${REMOTEBUILD}/remotebuild_host" ] ||
	[ ! -f "${REMOTEBUILD}/remotebuild_linux" ] ||
	[ "${REMOTEBUILD}/main.go" -nt "${REMOTEBUILD}/remotebuild_host" ] ||
	[ "${REMOTEBUILD}/main.go" -nt "${REMOTEBUILD}/remotebuild_linux" ] ||
	[ "${REMOTEBUILD}/client.go" -nt "${REMOTEBUILD}/remotebuild_host" ] ||
	[ "${REMOTEBUILD}/client.go" -nt "${REMOTEBUILD}/remotebuild_linux" ] ||
	[ "${REMOTEBUILD}/utils.go" -nt "${REMOTEBUILD}/remotebuild_host" ] ||
	[ "${REMOTEBUILD}/utils.go" -nt "${REMOTEBUILD}/remotebuild_linux" ] ||
	[ "${REMOTEBUILD}/messages.go" -nt "${REMOTEBUILD}/remotebuild_host" ] ||
	[ "${REMOTEBUILD}/messages.go" -nt "${REMOTEBUILD}/remotebuild_linux" ] ||
	[ "${REMOTEBUILD}/server.go" -nt "${REMOTEBUILD}/remotebuild_host" ] ||
	[ "${REMOTEBUILD}/server.go" -nt "${REMOTEBUILD}/remotebuild_linux" ]
then

echo "--> building remotebuild..."

BUILD_ID=$(date "+%Y-%m-%dT%H:%M:%S")

go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o remotebuild/remotebuild_host ./remotebuild

# GOARCH=amd64
GOOS=linux go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o remotebuild/remotebuild_linux ./remotebuild

fi
