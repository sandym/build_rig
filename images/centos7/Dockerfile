FROM centos:7

RUN yum -y update && \
yum -y install centos-release-scl && \
yum -y install \
devtoolset-8-gcc-c++ \
devtoolset-9-gcc-c++ \
devtoolset-9-gdb \
devtoolset-9-make \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum && \
cd /usr/local/bin && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/make && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/gdb && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/gcore && \
ln -s /opt/rh/devtoolset-9/root/usr/bin/gstack

ARG CMAKE_VERSION=3.18.0

RUN cd /tmp && \
. /opt/rh/devtoolset-9/enable && \
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
