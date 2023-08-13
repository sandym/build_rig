#!/bin/sh
#
# platform: darwin or container name
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
	echo "                   action:  build, test, run, clean"
	echo "                   toolset: gcc or clang"
	echo "                   type:    debug, release, asan, tsan, ubsan"
	echo "     project:   path to project to build, should have a"
	echo "                CMakeLists.txt"
	echo ""
	exit 0
}

ACTION=$(echo "${TRIPLET}" | cut -d "-" -f 1)
TOOLSET=$(echo "${TRIPLET}" | cut -d "-" -f 2)
TYPE=$(echo "${TRIPLET}" | cut -d "-" -f 3)
SOURCE_DIR=${PROJECT}
CXX=g++

gcc_only_toolset()
{
	case "${TOOLSET}" in
		gcc)
			if [ -f /opt/rh/gcc-toolset-13/enable ]
			then
				. /opt/rh/gcc-toolset-13/enable
			fi
			;;
		*)
			echo "unsupported toolset for centos: ${TOOLSET}"
			exit 1
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
			"${SOURCE_DIR}"
		if [ $? -ne 0 ]
		then
			echo "🔴"
			exit 1
		fi
	fi
}

do_build()
{
	if [ "${ACTION}" != "build" ] && [ "${ACTION}" != "test" ] && [ "${ACTION}" != "run" ]
	then
		echo "unsupported action: ${action}"
		usage
	fi

	echo "PATH:"
	for comp in $(echo ${PATH} | tr ":" "\n")
	do
		echo "  - ${comp}"
	done
	echo ""

	echo "building in ${BIN_DIR}"
	echo ""
	case ${TOOLSET} in
		clang)
			clang++ --version || exit 1
			;;
		*)
			${CXX} --version || exit 1
			;;
	esac

	mkdir -p "${BIN_DIR}"
	cd "${BIN_DIR}"

	if [ -f "${SOURCE_DIR}/build.sh" ]
	then
		"${SOURCE_DIR}/build.sh"
	else
		do_cmake
		ninja
	fi
	if [ $? -ne 0 ]
	then
		echo "🔴"
		exit 1
	fi
	if [ "${ACTION}" = "run" ]
	then
		"${SOURCE_DIR}/run.sh"
		if [ $? -ne 0 ]
		then
			echo "🔴"
			exit 1
		fi
	fi
	if [ "${ACTION}" = "test" ]
	then
		ctest --output-on-failure --parallel $(nproc)
		if [ $? -ne 0 ]
		then
			echo "🔴"
			exit 1
		fi
	fi
}

echo "--> ${PLATFORM} ${TRIPLET} ${PROJECT_NAME}"
echo ""
if [ "${PLATFORM}" = "darwin" ]
then
	BUILD_DIR=~/darwin_build/"${PROJECT_NAME}"
	case "${TOOLSET}" in
		xcode)
			case "${ACTION}" in
				build)
					mkdir -p "${BUILD_DIR}/xcode"
					cd "${BUILD_DIR}/xcode"
					cmake -G Xcode ${SOURCE_DIR}
					if [ $? -ne 0 ]
					then
						echo "🔴"
						exit 1
					fi
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
		clang|gcc)
			BIN_DIR=${BUILD_DIR}/${TOOLSET}-${TYPE}
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

			if [ "${TOOLSET}" = "gcc" ]
			then
				# not supported on M1
				exit 1
				# export CC=${CC}
				# export CXX=${CXX}
			fi

			do_build
			;;
		*)
			echo "unsupported toolset for darwin: ${TOOLSET}"
			exit 1
			;;
	esac
else

	# in container, for a linux build

	# adjust TOOLSET
	case ${PLATFORM} in
		centos9_builder|centos9_amd64_builder)
			gcc_only_toolset
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

			if [ -f build.ninja ]
			then
				ninja clean
			else
				rm -rf * .ninja*
			fi
		fi

		exit 0
	fi

	SOURCE_DIR=${PROJECT}/src
	do_build

fi

echo ""
echo "--> done ${PLATFORM} ${TRIPLET} ${PROJECT_NAME}"
