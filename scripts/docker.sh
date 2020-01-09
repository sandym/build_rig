#!/bin/sh

SCRIPTS=`dirname "$0"`
SCRIPTS=`cd "${SCRIPTS}" ; pwd`
CONTAINER=$1
ACTION=$2
PROJECT=$3

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
	docker exec -ti ${CONTAINER} /scripts/docker.sh ${CONTAINER} ${ACTION} ${PROJECT}

	echo ""
	CONTAINER=${CONTAINER%_builder}
	echo "done: ${CONTAINER} ${ACTION}"

else
	# in container

	syncdir syncdir_linux '-sync' "/share/${PROJECT}" "/work/${PROJECT}"
	echo ""

	# for c++17 on centos 7
	if [ -f /opt/rh/devtoolset-8/enable ]
	then
		. /opt/rh/devtoolset-8/enable
	fi

	echo "PATH = ${PATH}"
	g++ --version

	CONTAINER=${CONTAINER%_builder}
	mkdir -p "/work/${PROJECT}_build/${CONTAINER}"
	cd "/work/${PROJECT}_build/${CONTAINER}"

	if [ ! -f build.ninja ]
	then
		cmake -G Ninja \
			-DCMAKE_BUILD_TYPE=Debug \
			-DCMAKE_EXPORT_COMPILE_COMMANDS=on \
			"/work/${PROJECT}" || exit -1
	fi
	ninja

	if [ "${ACTION}" = "test" ]
	then
		ctest --output-on-failure --parallel $(nproc)
	fi
fi
