#!/bin/sh

set -e

PROJECT_PATH="$2"
PROJECT_NAME=`basename "${PROJECT_PATH}"`

if [ "$1" = "xcode" ]
then

	mkdir -p ~/darwin_build/"${PROJECT_NAME}"/xcode
	cd ~/darwin_build/"${PROJECT_NAME}"/xcode
	cmake -G Xcode ${PROJECT_PATH}
	open *.xcodeproj
	exit 0

fi

if [ "$1" = "xcode-clean" ]
then

	rm -rf ~/darwin_build/"${PROJECT_NAME}"/xcode
	exit 0

fi

if [ "$1" = "clean" ]
then

	if [ -f ~/darwin_build/"${PROJECT_NAME}"/debug/build.ninja ]
	then
		cd ~/darwin_build/"${PROJECT_NAME}"/debug
		ninja clean
	else
		rm -rf ~/darwin_build/"${PROJECT_NAME}"/debug
	fi
	exit 0

fi

mkdir -p ~/darwin_build/"${PROJECT_NAME}"/debug
cd ~/darwin_build/"${PROJECT_NAME}"/debug
if [ ! -f build.ninja ]
then
	cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=on ${PROJECT_PATH}
fi

time ninja

if [ "$1" = "test" ]
then
	ctest --output-on-failure --parallel $(sysctl -n hw.ncpu)
fi

echo ""
echo "done macos $1"
