#!/bin/sh

cd $(dirname "$0")
CONTAINER=$(basename ${0/\.sh/})
CONTAINER=${CONTAINER}_builder
SCRIPTS=$(cd ../scripts ; pwd)

SHELL=bash
if [ "${CONTAINER}" = "alpine_builder" ]
then
	SHELL=ash
fi

docker ps --filter "name=${CONTAINER}" | grep ${CONTAINER} > /dev/null
if [ $? -ne 0 ]
then
	docker run --rm -ti -d \
		--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--mount src=build_rig_work,target=/work \
		--name ${CONTAINER} \
		${CONTAINER} sleep infinity
fi

docker exec -ti ${CONTAINER} ${SHELL}
