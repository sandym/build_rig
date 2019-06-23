FROM centos:latest

ADD https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip /tmp/.
RUN yum -y upgrade && \
yum -y install centos-release-scl && \
yum -y install devtoolset-8 && \
yum -y install epel-release && \
yum -y install cmake3 && \
cd /usr/local/bin && \
ln -s /opt/rh/devtoolset-8/root/bin/gdb && \
ln -s /opt/rh/devtoolset-8/root/bin/gstack && \
ln -s /opt/rh/devtoolset-8/root/bin/gcore && \
ln -s /opt/rh/devtoolset-8/root/bin/make && \
ln -s /usr/bin/cmake3 cmake && \
ln -s /usr/bin/ctest3 ctest && \
ln -s /usr/bin/cpack3 cpack && \
unzip /tmp/ninja-linux.zip && \
rm  /tmp/ninja-linux.zip && \
yum clean all

CMD [ "sh", "-c", "while sleep 3600; do :; done" ]
