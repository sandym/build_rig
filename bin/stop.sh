#!/bin/sh

CONTAINERS=$(docker ps --all --filter "name=.*_builder" --format "{{.Names}}")

# stop all builders
for c in ${CONTAINERS}
do
	docker stop ${c} > /dev/null 2>&1 &
done

# wait for all builders
for c in ${CONTAINERS}
do
	docker wait ${c} > /dev/null 2>&1
done
