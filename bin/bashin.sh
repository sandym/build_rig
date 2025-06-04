#!/bin/sh

cd $(dirname "$0")
SERVICE=$(basename ${0/\.sh/})

if [[ "$(pwd)" == *"x86_64"* ]]
then
	SERVICE=${SERVICE}_x86_64
	cd ..
fi
cd .. || exit 1

SHELL=bash
if [[ "${SERVICE}" == *"alpine"* ]]
then
	SHELL=ash
fi

# start service if not running
docker compose up ${SERVICE} -d --remove-orphans
# start shell
docker compose exec -it ${SERVICE} ${SHELL}
