FROM centos:7

ARG CMAKE_VERSION=3.16.4
ARG NINJA_VERSION=v1.10.0

RUN yum -y update && \
yum -y install centos-release-scl && \
yum -y install \
devtoolset-8-gcc-c++ \
devtoolset-8-gdb \
devtoolset-8-make \
git \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum

RUN cd /tmp && \
. /opt/rh/devtoolset-8/enable && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
tar -zxf cmake-${CMAKE_VERSION}.tar.gz && \
cd cmake-${CMAKE_VERSION} && \
./bootstrap && \
make -j$(nproc) && \
make install  && \
rm -rf /tmp/cmake-*


RUN cd /usr/local/bin && \
curl -L -O https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip

CMD ["sleep","infinity"]
