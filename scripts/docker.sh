#!/bin/sh
#
# container: container name
#
# triplet:  action-toolset-type
#
#	where:
#		action: build, test, clean
#		toolset: default, gcc9, gcc10, clang
#		type:    debug, release, asan, tsan
#

CONTAINER=$1
TRIPLET=$2
PROJECT=$3
PROJECT_NAME=`basename "${PROJECT}"`

usage()
{
	echo "usage:"
	echo "  ./docker.sh container triplet project"
	echo ""
	echo "     container: name of a container to run the build"
	echo "     triplet:   action-type-toolset"
	echo "                where:"
	echo "                   action:  build, test, clean"
	echo "                   type:    debug, release, asan, tsan"
	echo "                   toolset: default, gcc9, clang"
	echo "     project:   path to project to build, should have a"
	echo "                CMakeLists.txt"
	echo ""
	exit 0
}

ACTION=build
case ${TRIPLET} in
	build-*)
		ACTION=build
		;;
	test-*)
		ACTION=test
		;;
	clean-*)
		ACTION=clean
		;;
	*)
		usage
		;;
esac
TYPE=debug
case ${TRIPLET} in
	*-debug)
		TYPE=debug
		;;
	*-release)
		TYPE=release
		;;
	*-asan)
		TYPE=asan
		;;
	*-tsan)
		TYPE=tsan
		;;
	*)
		usage
		;;
esac
TOOLSET=default
case ${TRIPLET} in
	*-gcc9-*)
		TOOLSET=gcc9
		;;
	*-gcc10-*)
		TOOLSET=gcc10
		;;
	*-clang-*)
		TOOLSET=clang
		;;
	*)
		usage
		;;
esac

alpine_toolset()
{
	case "${TOOLSET}" in
		gcc9)
			;;
		clang)
			;;
		*)
			exit -1
			;;
	esac
}

ubuntu_toolset()
{
	case "${TOOLSET}" in
		gcc10)
			;;
		clang)
			;;
		*)
			exit -1
			;;
	esac
}

if [ ! -f "/.dockerenv" ]
then
	# in host
	SCRIPTS=`dirname "$0"`
	SCRIPTS=`cd "${SCRIPTS}" ; pwd`
	cd "${SCRIPTS}"

	source "../.env"

	# build syndir of needed
	if [ ! -f "syncdir_host" ] ||
		[ "syncdir/syncdir.go" -nt "syncdir_host" ]
	then
		echo "building syncdir..."
		cd "syncdir"
	 	`go build -o ../syncdir_host`;
	 	`GOOS=linux GOARCH=amd64 go build -o ../syncdir_linux`;
		cd "${SCRIPTS}"
	fi

	"./syncdir_host" -scan "${PROJECT}"

	cd "${SCRIPTS}/.."

	export MSYS_NO_PATHCONV=1
	time docker-compose run --rm ${CONTAINER} \
			/scripts/docker.sh ${CONTAINER} ${TRIPLET} ${PROJECT}

	echo ""
	echo "done: ${CONTAINER} ${TRIPLET}"

else
	# in container, for a linux build

	# adjust TOOLSET
	case ${CONTAINER} in
		centos8_builder)
			. /opt/rh/gcc-toolset-9/enable 
			;;
		alpine_builder)
			alpine_toolset
			;;
		ubuntu_builder)
			ubuntu_toolset
			;;
		*)
			;;
	esac

	BIN_DIR=/work/${PROJECT_NAME}/${CONTAINER%_builder}/${TOOLSET}-${TYPE}

	if [ "${ACTION}" = "clean" ]
	then
		if [ -d "${BIN_DIR}" ]
		then
			cd "${BIN_DIR}"

			/script/syncdir_linux -clean "/work/${PROJECT_NAME}/src"
			if [ -f build.ninja ]
			then
				ninja clean
			else
				rm -rf * .ninja*
			fi
		fi

		exit 0
	fi

	/scripts/syncdir_linux -sync "/share/${PROJECT_NAME}" "/work/${PROJECT_NAME}/src"
	echo ""

	echo "PATH = ${PATH}"
	echo "building in ${BIN_DIR}"
	echo ""
	if [ "${TOOLSET}" = "clang" ]
	then
		clang++ --version || exit 1
	else
		g++ --version || exit 1
	fi
	ld --version

	mkdir -p "${BIN_DIR}"
	cd "${BIN_DIR}"

	if [ ! -f build.ninja ]
	then
		BUILD_TYPE=Debug
		if [ "${TOOLSET}" = "clang" ]
		then
			export CC=clang
			export CXX=clang++
		fi
		case ${TYPE} in
			release)
				BUILD_TYPE=RelWithDebInfo
				;;
			asan)
				export CXXFLAGS="-fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=address"
				export CFLAGS="-fno-omit-frame-pointer -fsanitize=address"
				export LDFLAGS="-fsanitize=address -pthread"
				;;
			tsan)
				export CXXFLAGS="-fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=thread"
				export CFLAGS="-fno-omit-frame-pointer -fsanitize=thread"
				export LDFLAGS="-fsanitize=thread"
				;;
			*)
				;;
		esac

		cmake -G Ninja \
			-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
			-DCMAKE_EXPORT_COMPILE_COMMANDS=on \
			"/work/${PROJECT_NAME}/src" || exit -1
	fi
	ninja

	if [ "${ACTION}" = "test" ]
	then
		ctest --output-on-failure --parallel $(nproc)
	fi
fi
