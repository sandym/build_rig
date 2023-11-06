#!/bin/sh

if [ -f '/.dockerenv' ]
then

	# in docker
	if [ "$(uname -m)" != "x86_64" ]
	then
		echo "ERROR: Only for x86_64 containers"
		exit 1
	fi

	# parse options to find the executable to start
	gdbArgs=()
	EXECUTABLE=""

	for opt in "$@"
	do
		if [[ "${opt}" == "--executable="* ]]
		then
			EXECUTABLE=${opt#--executable=}
			continue
		fi
		gdbArgs+=(${opt})
	done

	# start in background with debug server and clean up on exit
	ROSETTA_DEBUGSERVER_PORT=1234 "${EXECUTABLE}" &
	TARGET_PID=$!
	cleanup() {
		kill ${TARGET_PID}
	}
	trap 'cleanup' SIGINT SIGTERM EXIT

	sleep 2

	/usr/local/bin/gdb ${gdbArgs[@]}

else

	# in host, just call itself in the container

	# parse options to find the container to use
	gdbArgs=()
	CONTAINER=""

	for opt in "$@"
	do
		if [[ "${opt}" == "--container="* ]]
		then
			CONTAINER=${opt#--container=}
			continue
		fi
		gdbArgs+=(${opt})
	done

	/usr/local/bin/docker exec -i ${CONTAINER} /rosetta_gdb_wrapper.sh ${gdbArgs[@]}

fi
