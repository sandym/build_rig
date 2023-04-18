# syntax = docker/dockerfile:1
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN <<EOT
apt-get -y update
apt-get -y install --no-install-recommends wget g++ gdb libssl-dev make ninja-build time
EOT

WORKDIR /tmp

ARG CMAKE_VERSION

RUN --mount=type=cache,target=/tmp <<EOT
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh
sh cmake-${CMAKE_VERSION}-Linux-$(uname -m).sh --skip-license --prefix=/usr/local
EOT

ENV PS1='[\e[35mubuntu_lts\e[m \W]# '
RUN <<EOT
echo "" >> /root/.bashrc
echo "PS1='$PS1'" >> /root/.bashrc
EOT
