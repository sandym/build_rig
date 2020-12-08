FROM ubuntu:20.10

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && apt-get -y upgrade && \
apt-get -y install wget clang g++ gdb libssl-dev make time && \
apt-get autoclean && \
apt-get clean && \
apt-get autoremove --purge && \
rm -rf /var/apt/cache/* && \
rm -rf /tmp/*

ARG CMAKE_VERSION

RUN cd /tmp && \
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
sh cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION

RUN cd /usr/local/bin && \
wget https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip && \
ln -s /usr/bin/gdb
