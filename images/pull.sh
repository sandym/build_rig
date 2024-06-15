#!/bin/sh

docker pull quay.io/centos/centos:stream9
docker pull quay.io/centos/centos:stream10-development
docker pull alpine
docker pull ubuntu

docker system prune

docker images
