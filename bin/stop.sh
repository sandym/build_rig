#!/bin/sh

docker stop ubuntu_lts_builder > /dev/null 2>&1 &
docker stop ubuntu_builder > /dev/null 2>&1 &
docker stop alpine_builder > /dev/null 2>&1 &
docker stop centos9_builder > /dev/null 2>&1 &

docker wait ubuntu_lts_builder > /dev/null 2>&1
docker wait ubuntu_builder > /dev/null 2>&1
docker wait alpine_builder > /dev/null 2>&1
docker wait centos9_builder > /dev/null 2>&1
