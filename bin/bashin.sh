#!/bin/sh

cd $(dirname "$0")
CONTAINER=$(basename ${0/\.sh/})
CONTAINER=${CONTAINER}_builder
SCRIPTS=$(cd ../scripts ; pwd)

. ../.env

SHELL=bash
if [ "${CONTAINER}" = "alpine_builder" ]
then
	SHELL=ash
fi

docker ps | grep ${CONTAINER} > /dev/null
if [ $? = 0 ]
then
	docker exec -ti ${CONTAINER} ${SHELL}
else
	docker run --rm -ti \
		--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--mount type=bind,source="${WORKSPACE_SHARED_FOLDER}",target=/share \
		--mount type=bind,source="${SCRIPTS}",target=/scripts \
		--mount src=build_rig_work,target=/work \
		--name ${CONTAINER} \
		${CONTAINER} ${SHELL}
fi
