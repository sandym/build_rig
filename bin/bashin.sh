#!/bin/sh

cd $(dirname "$0")
CONTAINER=$(basename ${0/\.sh/})
if [[ "${CONTAINER}" == *"_amd64"* ]]
then
	CONTAINER=${CONTAINER/_amd64/}
	CONTAINER=${CONTAINER}_builder:amd64
else
	CONTAINER=${CONTAINER}_builder:$(uname -m)
fi
SCRIPTS=$(cd ../scripts ; pwd)

SHELL=bash
if [[ "${CONTAINER}" == *"alpine"* ]]
then
	SHELL=ash
fi

# start comtainer if not running
docker ps --filter "name=${CONTAINER}" | grep ${CONTAINER} > /dev/null
if [ $? -ne 0 ]
then
	docker run --rm --init -ti -d \
		--cap-add=ALL --security-opt seccomp=unconfined \
		--mount src=build_rig_work,target=/work \
		--name ${CONTAINER} \
		${CONTAINER} sleep infinity
fi

# start shell
docker exec -ti ${CONTAINER} ${SHELL}
