#!/bin/sh

cd $(dirname "$0")
ROOT=$(cd .. ; pwd)

cd "${ROOT}/" || exit 1

docker compose down --remove-orphans
