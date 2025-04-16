#!/bin/sh

cd $(dirname "$0")
CONTAINER=$(basename ${0/\.sh/})

if [[ "$(pwd)" == *"x86_64"* ]]
then
	CONTAINER=${CONTAINER/_x86_64/}
	CONTAINER=${CONTAINER}_builder:x86_64
	cd ..
else
	CONTAINER=${CONTAINER}_builder:$(uname -m)
fi

SCRIPTS=$(cd ../scripts ; pwd)

SHELL=bash
if [[ "${CONTAINER}" == *"alpine"* ]]
then
	SHELL=ash
fi

CONTAINER_NAME=${CONTAINER//:/_}

# start comtainer if not running
docker ps --filter "name=${CONTAINER_NAME}" | grep ${CONTAINER_NAME} > /dev/null
if [ $? -ne 0 ]
then
	docker run --rm --init -ti -d \
		--cap-add=ALL --security-opt seccomp=unconfined \
		--mount src=build_rig_work,target=/work \
		--name ${CONTAINER_NAME} \
		${CONTAINER} sleep infinity
fi

# start shell
docker exec -ti ${CONTAINER_NAME} ${SHELL}
