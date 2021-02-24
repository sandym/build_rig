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

# docker ps

docker run --rm -ti \
	--mount type=bind,source="${WORKSPACE_SHARED_FOLDER}",target=/share \
	--mount type=bind,source="${SCRIPTS}",target=/scripts \
	--mount src=build_rig_work,target=/work \
	${CONTAINER} ${SHELL}

    # cap_add:
    #   - SYS_PTRACE
    # security_opt:
    #   - seccomp:unconfined

# docker exec -t ${CONTAINER} $(bash | ash | sh)
