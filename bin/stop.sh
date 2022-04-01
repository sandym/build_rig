#!/bin/sh

CONTAINERS=$(docker ps --all --filter "name=.*_builder" --format "{{.Names}}")
for c in ${CONTAINERS}
do
	docker stop ${c} > /dev/null 2>&1 &
done

for c in ${CONTAINERS}
do
	docker wait ${c} > /dev/null 2>&1
done
