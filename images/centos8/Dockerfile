FROM centos:8

RUN yum -y update && \
yum -y install \
curl \
gcc-c++ \
gcc-toolset-9-gcc-c++ \
gcc-toolset-9-gdb \
gcc-toolset-9-make \
git \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum && \
cd /usr/local/bin && \
ln -s /opt/rh/gcc-toolset-9/root/usr/bin/make && \
ln -s /opt/rh/gcc-toolset-9/root/usr/bin/gdb

ARG CMAKE_VERSION=3.17.3

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

# latest clang
# RUN cd /tmp && \
# git clone --branch llvmorg-10.0.0 --depth 1 https://github.com/llvm/llvm-project.git src && \
# mkdir build && \
# cd build && \
# export LLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;llvm" && \
# cmake -G Ninja \
# 	-DCMAKE_BUILD_TYPE=Release \
# 	-DLLVM_ENABLE_LIBXML2=0 \
# 	-DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS} \
# 	-DCMAKE_INSTALL_PREFIX:PATH=/opt/llvm \
# 	-DLLVM_TARGETS_TO_BUILD="host" \
# 	../src/llvm && \
# ninja && \
# ninja install-clang && \
# ninja install-lld && \
# ninja install-clang-resource-headers && \
# rm -rf /tmp/build /tmp/src

# ENV PATH=$PATH:/opt/llvm/bin

# CMD ["sleep","infinity"]
