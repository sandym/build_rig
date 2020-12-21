#!/bin/sh
#
# platform: darwin or container name
#
# triplet:  action-toolset-type
#
#	where:
#		action: build, test, clean
#		toolset: default, gcc9, gcc10, clang
#		type:    debug, release, asan, tsan, ubsan
#

PLATFORM=$1
TRIPLET=$2
PROJECT=$3
PROJECT_NAME=$(basename "${PROJECT}")

usage()
{
	echo "usage:"
	echo "  ./driver.sh platform triplet project_path"
	echo ""
	echo "     platform: darwin or name of a container to run the build"
	echo "     triplet:   action-toolset-type"
	echo "                where:"
	echo "                   action:  build, test, clean"
	echo "                   toolset: gcc8, gcc9, clang"
	echo "                   type:    debug, release, asan, tsan"
	echo "     project:   path to project to build, should have a"
	echo "                CMakeLists.txt"
	echo ""
	exit 0
}

ACTION=$(echo "${TRIPLET}" | cut -d "-" -f 1)
TOOLSET=$(echo "${TRIPLET}" | cut -d "-" -f 2)
TYPE=$(echo "${TRIPLET}" | cut -d "-" -f 3)

centos7_toolset()
{
	case "${TOOLSET}" in
		gcc8)
			. /opt/rh/devtoolset-8/enable
			;;
		gcc9)
			. /opt/rh/devtoolset-9/enable
			;;
		*)
			echo "unsupported toolset for centos7: ${TOOLSET}"
			exit -1
			;;
	esac
}

alpine_toolset()
{
	case "${TOOLSET}" in
		gcc9)
			;;
		clang)
			;;
		*)
			echo "unsupported toolset for alpine: ${TOOLSET}"
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
			echo "unsupported toolset for ubuntu: ${TOOLSET}"
			exit -1
			;;
	esac
}

do_cmake()
{
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
				export LDFLAGS="-fsanitize=address"
				;;
			tsan)
				export CXXFLAGS="-fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=thread"
				export CFLAGS="-fno-omit-frame-pointer -fsanitize=thread"
				export LDFLAGS="-fsanitize=thread"
				;;
			ubsan)
				export CXXFLAGS="-fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize=undefined"
				export CFLAGS="-fno-omit-frame-pointer -fsanitize=undefined"
				export LDFLAGS="-fsanitize=undefined"
				;;
			debug)
				;;
			*)
				echo "unsupported type: ${TYPE}"
				usage
				;;
		esac

		cmake -G Ninja \
			-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
			-DCMAKE_EXPORT_COMPILE_COMMANDS=on \
			"/work/${PROJECT_NAME}/src" || exit -1
	fi
}

run_build()
{
	echo "PATH = ${PATH}"
	echo "building in ${BIN_DIR}"
	echo ""
	case ${TOOLSET} in
		clang)
			clang++ --version || exit 1
			;;
		*)
			g++ --version || exit 1
			;;
	esac

	mkdir -p "${BIN_DIR}"
	cd "${BIN_DIR}"

	do_cmake
	case ${ACTION} in
		build)
			/usr/bin/time -p ninja
			;;
		test)
			/usr/bin/time -p ninja
			/usr/bin/time -p ctest --output-on-failure --parallel $(nproc)
			;;
		*)
			echo "unsupported action: ${action}"
			usage
			;;
	esac
}

if [ "${PLATFORM}" = "darwin" ]
then
	BUILD_DIR=~/darwin_build/"${PROJECT_NAME}"
	case "${TOOLSET}" in
		xcode)
			case "${ACTION}" in
				build)
					mkdir -p "${BUILD_DIR}/xcode"
					cd "${BUILD_DIR}/xcode"
					cmake -G Xcode ${PROJECT_PATH}
					open *.xcodeproj
					exit 0
					;;
				clean)
					rm -rf "${BUILD_DIR}/xcode"
					exit 0
					;;
				*)
					echo "unsupported action for xcode: ${ACTION}"
					exit -1
					;;
			esac
			;;
		clang)
			BIN_DIR=${BUILD_DIR}/${TYPE}
			if [ "${ACTION}" = "clean" ]
			then
				if [ -d "${BIN_DIR}" ]
				then
					cd "${BIN_DIR}"
					if [ -f build.ninja ]
					then
						ninja clean
					else
						rm -rf * .ninja*
					fi
				fi
				exit 0
			fi

			run_build
			;;
		*)
			echo "unsupported toolset for darwin: ${TOOLSET}"
			exit -1
			;;
	esac
else

if [ ! -f "/.dockerenv" ]
then
	# in host
	SCRIPTS=$(dirname "$0")
	SCRIPTS=$(cd "${SCRIPTS}" ; pwd)
	cd "${SCRIPTS}"

	source "../.env"

	# build syndir of needed
	if [ ! -f "syncdir_host" ] || [ "syncdir.go" -nt "syncdir_host" ]
	then
		echo "building syncdir..."
	 	$(go build -o syncdir_host)
	 	$(GOOS=linux GOARCH=amd64 go build -o syncdir_linux)
	fi

	"./syncdir_host" -scan "${PROJECT}"

	cd "${SCRIPTS}/.."

	export MSYS_NO_PATHCONV=1
	docker-compose run --rm ${PLATFORM} \
			/scripts/driver.sh ${PLATFORM} ${TRIPLET} ${PROJECT}

	echo ""
	echo "done: ${PLATFORM} ${TRIPLET}"

else
	# in container, for a linux build

	# adjust TOOLSET
	case ${PLATFORM} in
		centos7_builder)
			centos7_toolset
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

	BIN_DIR=/work/${PROJECT_NAME}/${PLATFORM%_builder}/${TOOLSET}-${TYPE}

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

	run_build

fi

fi
