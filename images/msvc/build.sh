#!/bin/sh

cd $(dirname $0)

cd base
docker build -t msvc_builder_base .
cd ..

npm install http-server -g
cd pkgs
http-server &
HTTP_SERVER_PID=$!
cd ..

cd msvc
docker build -t msvc_builder .

kill ${HTTP_SERVER_PID}
