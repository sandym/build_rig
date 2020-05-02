#!/bin/sh

set -e

PROJECT_PATH="$2"
PROJECT_NAME=`basename "${PROJECT_PATH}"`
BUILD_DIR=~/darwin_build/"${PROJECT_NAME}"

if [ "${1}" = "xcode" ]
then

	mkdir -p "${BUILD_DIR}/xcode"
	cd "${BUILD_DIR}/xcode"
	cmake -G Xcode ${PROJECT_PATH}
	open *.xcodeproj
	exit 0

fi

if [ "${1}" = "xcode-clean" ]
then

	rm -rf "${BUILD_DIR}/xcode"
	exit 0

fi

ACTION=build
case $1 in
    clean-*)
	 	ACTION=clean
		;;
    test-*)
	 	ACTION=test
		;;
    run-*)
	 	ACTION=run
		;;
    *)
		;;
esac

BINDIR=debug
BUILD_TYPE=Debug
case $1 in
    *-release)
		BINDIR=release
		BUILD_TYPE=RelWithDebInfo
		;;
    *)
		;;
esac

if [ "${ACTION}" = "clean" ]
then

	if [ -f "${BUILD_DIR}/${BINDIR}/build.ninja" ]
	then
		cd "${BUILD_DIR}/${BINDIR}"
		ninja clean
	else
		rm -rf "${BUILD_DIR}/${BINDIR}"
	fi
	exit 0

fi

mkdir -p "${BUILD_DIR}/${BINDIR}"
cd "${BUILD_DIR}/${BINDIR}"
if [ ! -f build.ninja ]
then
	cmake -G Ninja \
		-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=on ${PROJECT_PATH}
fi

time ninja

if [ "${ACTION}" = "test" ]
then
	ctest --output-on-failure --parallel $(sysctl -n hw.ncpu)
fi

echo ""
echo "done macos ${ACTION}"

if [ "${ACTION}" = "run" ] && [ -f "${PROJECT_PATH}/run.sh" ]
then
	"${PROJECT_PATH}/run.sh"
fi

