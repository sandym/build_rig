#!/bin/sh
#
# triplet: action-toolset-type
#
#	where:
#		action:	 build, test, clean
#		toolset: gcc, clang
#		type:    debug, release, asan, tsan
#

CONTAINER=$1
TRIPLET=$2
PROJECT=$3

usage()
{
	echo "usage:"
	echo "  ./docker.sh container triplet project"
	echo ""
	echo "     container: name of a container to run the build"
	echo "     triplet:   action-toolset-type"
	echo "                where:"
	echo "                   action:  build, test, clean"
	echo "                   toolset: gcc, clang, msvc"
	echo "                   type:    debug, release, asan, tsan"
	echo "     project:   path to project to build, should have a"
	echo "                CMakeLists.txt"
	echo ""
	exit 0
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
	*-msvc-*)
		TOOLSET=msvc
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

	PROJECT=`basename "${PROJECT}"`
	export MSYS_NO_PATHCONV=1
	docker ps | grep ${CONTAINER} > /dev/null 2>&1
	if [ $? = 0 ]
	then
		# container is already running, just exec
		time docker exec -ti ${CONTAINER} \
			/scripts/docker.sh ${CONTAINER} ${TRIPLET} ${PROJECT}
	else
		# fix for path on windows
		which cygpath.exe > /dev/null
		if [ $? = 0 ]
		then
			SCRIPTS=`cygpath.exe -m "${SCRIPTS}"`
		fi

		WORK=/work
		if [ "${TOOLSET}" = "msvc" ]
		then
			WORK=/root/.wine/drive_c/w
			# @todo: entrypoint
		fi

		# container is not running, run and --rm
		time docker run --rm -ti \
			--mount type=bind,source="${SCRIPTS}",target=/scripts \
			--mount type=bind,source="${WORKSPACE_SHARED_FOLDER}",target=/share \
  			--mount source=build_rig_work,target=${WORK} \
			${CONTAINER} \
			/scripts/docker.sh ${CONTAINER} ${TRIPLET} ${PROJECT}
	fi

	echo ""
	echo "done: ${CONTAINER} ${TRIPLET}"

elif [ "${TOOLSET}" != "msvc" ]
then
	# in container, for a linux build

	BIN_DIR=/work/${CONTAINER%_builder}/${PROJECT}-${TOOLSET}-${TYPE}

	# for modern c++ on centos
	if [ -f /opt/rh/devtoolset-9/enable ]
	then
		. /opt/rh/devtoolset-9/enable
	elif [ -f /opt/rh/devtoolset-8/enable ]
	then
		. /opt/rh/devtoolset-8/enable
	fi

	if [ "${ACTION}" = "clean" ]
	then
		if [ -d "${BIN_DIR}" ]
		then
			cd "${BIN_DIR}"

			/script/syncdir_linux -clean "/work/${PROJECT}"
			if [ -f build.ninja ]
			then
				ninja clean
			else
				rm -rf * .ninja*
			fi
		fi

		exit 0
	fi

	/scripts/syncdir_linux -sync "/share/${PROJECT}" "/work/${PROJECT}"
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

else
	# in container, for a msvc-wine build

	WORK=/root/.wine/drive_c/w
	BIN_DIR=${CONTAINER%_builder}/${PROJECT}-${TOOLSET}-${TYPE}

	if [ "${ACTION}" = "clean" ]
	then
		if [ -d "${BIN_DIR}" ]
		then
			cd "${BIN_DIR}"

			/script/syncdir_linux -clean "${WORK}/${PROJECT}"
			rm -rf * .ninja*
		fi

		exit 0
	fi

	/scripts/syncdir_linux -sync "/share/${PROJECT}" "${WORK}/${PROJECT}"
	echo ""

	mkdir -p "${WORK}/${BIN_DIR}"

	BUILD_TYPE=Debug
	if [ "${TYPE}" = "release" ]
	then
		BUILD_TYPE=RelWithDebInfo
	fi

	echo "@echo off\r" > "${WORK}/${BIN_DIR}/build.bat"
	echo "c:\\x64.bat\r" >> "${WORK}/${BIN_DIR}/build.bat"
	echo "echo \"msvc version %VSCMD_VER%\"\r" >> "${WORK}/${BIN_DIR}/build.bat"
	echo "echo \"building in C:/w/%3\"\r" >> "${WORK}/${BIN_DIR}/build.bat"
	echo ""


	wine64 "${WORK}/${BIN_DIR}/build.bat" ${ACTION} ${BUILD_TYPE} "${BIN_DIR}"

	exit 0
	
	cd "${BIN_DIR}"

	if [ ! -f build.ninja ]
	then

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
