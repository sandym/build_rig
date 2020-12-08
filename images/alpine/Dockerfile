FROM alpine

RUN apk add --no-cache clang g++ gdb make linux-headers ninja openssl-dev

RUN cd /usr/local/bin && \
ln -s /usr/bin/gdb

ARG CMAKE_VERSION

RUN cd /tmp && \
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
sh cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*
