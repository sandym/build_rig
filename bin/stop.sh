#!/bin/sh

docker stop ubuntu_lts_builder > /dev/null 2>&1 &
docker stop ubuntu_builder > /dev/null 2>&1 &
docker stop alpine_builder > /dev/null 2>&1 &
docker stop centos7_builder > /dev/null 2>&1 &
docker stop centos8_builder > /dev/null 2>&1 &

docker wait ubuntu_lts_builder > /dev/null 2>&1
docker wait ubuntu_builder > /dev/null 2>&1
docker wait alpine_builder > /dev/null 2>&1
docker wait centos7_builder > /dev/null 2>&1
docker wait centos8_builder > /dev/null 2>&1
