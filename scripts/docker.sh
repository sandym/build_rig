#!/bin/sh
#
# triplet: action-toolset-type
#
#	where:
#		action:	 build, test, clean
#		toolset: gcc, clang
#		type:    debug, release, asan, tsan
#

SCRIPTS=`dirname "$0"`
SCRIPTS=`cd "${SCRIPTS}" ; pwd`
CONTAINER=$1
TRIPLET=$2
PROJECT=$3

usage()
{
	echo "usage:"
	exit 1
}

ACTION=build
case ${TRIPLET} in
	*build-*)
		ACTION=build
		;;
	*test-*)
		ACTION=test
		;;
	*clean-*)
		ACTION=clean
		;;
	*)
		usage
		;;
esac

TOOLSET=gcc
case ${TRIPLET} in
	*-gcc-*)
		TOOLSET=gcc
		;;
	*-clang-*)
		TOOLSET=clang
		;;
	*)
		usage
		;;
esac

TYPE=debug
case ${TRIPLET} in
	*-debug*)
		TYPE=debug
		;;
	*-release*)
		TYPE=release
		;;
	*-asan*)
		TYPE=asan
		;;
	*-tsan*)
		TYPE=tsan
		;;
	*)
		usage
		;;
esac

syncdir()
{
	SYNCDIR=$1
	shift
	"${SCRIPTS}/${SYNCDIR}" $@
}

if [ ! -f "/.dockerenv" ]
then
	# in host

	# build syndir of needed
	if [ ! -f "${SCRIPTS}/syncdir_host" ] || [ "${SCRIPTS}/syncdir/syncdir.go" -nt "${SCRIPTS}/syncdir_host" ]
	then
		echo "building syncdir..."
	 	`cd "${SCRIPTS}/syncdir" ; go build -o ../syncdir_host`;
	 	`cd "${SCRIPTS}/syncdir" ; GOOS=linux GOARCH=amd64 go build -o ../syncdir_linux`;
	fi

	cd "${PROJECT}"
	syncdir syncdir_host "-scan" .

	PROJECT=`basename "${PROJECT}"`
	time docker exec -ti ${CONTAINER} /scripts/docker.sh ${CONTAINER} ${TRIPLET} ${PROJECT}

	echo ""
	CONTAINER=${CONTAINER%_builder}
	echo "done: ${CONTAINER} ${TRIPLET}"

else
	# in container

	BIN_DIR=/work/${CONTAINER%_builder}_build/${PROJECT}-${TOOLSET}-${TYPE}

	# for c++17 on centos 7
	if [ -f /opt/rh/devtoolset-8/enable ]
	then
		. /opt/rh/devtoolset-8/enable
	fi

	if [ "${ACTION}" = "clean" ]
	then
		if [ -d "${BIN_DIR}" ]
		then
			cd "${BIN_DIR}"

			syncdir syncdir_linux '-clean' "/work/${PROJECT}"
			if [ -f build.ninja ]
			then
				ninja clean
			else
				rm -rf * .ninja*
			fi
		fi

		exit 0
	fi

	syncdir syncdir_linux '-sync' "/share/${PROJECT}" "/work/${PROJECT}"
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
			"/work/${PROJECT}" || exit -1
	fi
	ninja

	if [ "${ACTION}" = "test" ]
	then
		ctest --output-on-failure --parallel $(nproc)
	fi
fi
