#!/bin/sh

docker run -it --rm --privileged --pid=host alpine nsenter -t 1 -m -u -n -i sh

