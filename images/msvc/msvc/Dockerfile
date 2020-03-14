FROM msvc_builder_base

ARG ninja_version=v1.10.0
ARG ninja_binaries_url=https://github.com/ninja-build/ninja/releases/download/$ninja_version/ninja-win.zip

WORKDIR /home/wine/.wine/drive_c

USER root

RUN mkdir Tools && cd Tools && \
curl -L -O http://host.docker.internal:8080/VS2019.tar.gz && \
tar -zxf VS2019.tar.gz && \
curl -L -O http://host.docker.internal:8080/SDK.tar.gz && \
tar -zxf SDK.tar.gz && \
curl -L -O http://host.docker.internal:8080/CMake.tar.gz && \
tar -zxf CMake.tar.gz && \
curl -L -O http://host.docker.internal:8080/Git.tar.gz && \
tar -zxf Git.tar.gz && \
curl -L -O $ninja_binaries_url && \
unzip -d Ninja -q ninja-win.zip && \
rm -f *.tar.gz *.zip

# Set batch scripts to set 64 Bit environments
COPY --chown=wine:root x64.bat /home/wine/.wine/drive_c/x64.bat

RUN chown -R wine:root . && \
chmod -R 775 .

USER wine
