# syntax=docker/dockerfile:1
FROM ubuntu:23.04

ARG DEBIAN_FRONTEND=noninteractive

RUN <<EOT
apt-get -y update
apt-get -y install --no-install-recommends \
	wget \
	g++ \
	gdb \
	libssl-dev \
	make \
	ninja-build
EOT

WORKDIR /tmp

###
# cmake
###
ARG CMAKE_VERSION

RUN --mount=type=cache,target=/tmp <<EOT
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local
EOT

WORKDIR /

ENV PS1='[\e[35mubuntu:$(uname -m)\e[m \W]# '
RUN <<EOT
echo "" >> /root/.bashrc
echo "PS1='$PS1'" >> /root/.bashrc
EOT
