FROM alpine

RUN apk add --no-cache clang g++ gdb git make linux-headers ninja openssl-dev

RUN cd /usr/local/bin && \
ln -s /usr/bin/gdb

ARG CMAKE_VERSION=3.19.0

RUN cd /tmp && \
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
tar -zxf cmake-${CMAKE_VERSION}.tar.gz && \
cd cmake-${CMAKE_VERSION} && \
./bootstrap && \
make -j$(nproc) && \
make install  && \
rm -rf /tmp/cmake-*
