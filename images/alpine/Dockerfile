FROM alpine

RUN apk add --no-cache clang g++ gdb make ninja linux-headers openssl-dev

ARG CMAKE_VERSION

RUN cd /tmp && \
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
tar -zxf cmake-${CMAKE_VERSION}.tar.gz && \
cd cmake-${CMAKE_VERSION} && \
./bootstrap && \
make -j$(nproc) && \
make install  && \
rm -rf /tmp/cmake-*

ENV PS1='[\e[35malpine\e[m \W]# '
