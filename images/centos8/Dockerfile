FROM quay.io/centos/centos:stream8

RUN echo "skip_missing_names_on_install=0" >> /etc/yum.conf && \
yum -y install centos-release-scl && \
yum -y install \
gcctoolset-10 \
openssl-devel \
which && \
yum clean all && rm -rf /var/cache/yum

ARG CMAKE_VERSION

RUN cd /tmp && \
curl -L -O https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
sh cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
rm -rf /tmp/cmake-*

ARG NINJA_VERSION

RUN cd /usr/local/bin && \
curl -L -O https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip && \
cmake -E tar zxf ninja-linux.zip && \
rm ninja-linux.zip

ENV PS1='[\e[35mcentos8\e[m \W]# '
