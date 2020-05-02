FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && apt-get -y upgrade && \
apt-get -y install curl g++ gdb git libssl-dev make time && \
apt-get autoclean && \
apt-get clean && \
apt-get autoremove --purge && \
rm -rf /var/apt/cache/* && \
rm -rf /tmp/*

ARG CMAKE_VERSION=3.17.2

RUN cd /tmp && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
tar -zxf cmake-${CMAKE_VERSION}.tar.gz && \
cd cmake-${CMAKE_VERSION} && \
./bootstrap && \
make -j$(nproc) && \
make install  && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION=v1.10.0

RUN cd /usr/local/bin && \
curl -L -O https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip

CMD ["sleep","infinity"]
