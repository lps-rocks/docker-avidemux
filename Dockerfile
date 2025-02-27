#
# avidemux Dockerfile
#
# https://github.com/jlesage/docker-avidemux
#

# Pull base image.
FROM alpine:latest

# Define software versions.
ARG AVIDEMUX_VERSION=2.8.1
ARG OPENCORE_AMR_VERSION=0.1.5
ARG TWOLAME_VERSION=0.4.0
ARG AFTEN_VERSION=0.0.8
ARG LIBDCA_VERSION=0.0.7
ARG DCAENC_VERSION=2

# Define software download URLs.
ARG AVIDEMUX_URL=https://downloads.sourceforge.net/project/avidemux/avidemux/${AVIDEMUX_VERSION}/avidemux_${AVIDEMUX_VERSION}.tar.gz
ARG OPENCORE_AMR_URL=https://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCORE_AMR_VERSION}.tar.gz
ARG TWOLAME_URL=https://downloads.sourceforge.net/project/twolame/twolame/${TWOLAME_VERSION}/twolame-${TWOLAME_VERSION}.tar.gz
ARG AFTEN_URL=https://downloads.sourceforge.net/project/aften/aften/${AFTEN_VERSION}/aften-${AFTEN_VERSION}.tar.bz2
ARG LIBDCA_URL=https://download.videolan.org/pub/videolan/libdca/${LIBDCA_VERSION}/libdca-${LIBDCA_VERSION}.tar.bz2
ARG DCAENC_URL=https://github.com/darealshinji/dcaenc/archive/refs/tags/v${DCAENC_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Compile Avidemux
RUN \
    apk add --no-cache --virtual .build-dependencies \
        curl \
        build-base \
        patch \
        tar \
        bash \
        coreutils \
        file \
        cmake \
        yasm \
        nasm \
        autoconf \
        automake \
        libtool \
        qt5-qtbase \
        qt5-qttools-dev \
        zlib-dev \
        libxv-dev \
        sqlite-dev \
        fribidi-dev \
        libvdpau-dev \
        x264-dev \
        x265-dev \
        xvidcore-dev \
        libvpx-dev \
        libvorbis-dev \
        libogg-dev \
        faac-dev \
        faad2-dev \
        glu-dev \
        libass-dev \
        alsa-lib-dev \
        lame-dev \
        opus-dev \
        fdk-aac-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download sources.
    echo 'Downloading sources...' && \
    curl -# -L ${AVIDEMUX_URL} | tar xz && \
    curl -# -L ${OPENCORE_AMR_URL} | tar xz && \
    curl -# -L ${TWOLAME_URL} | tar xz && \
    curl -# -L ${AFTEN_URL} | tar xj && \
    curl -# -L ${LIBDCA_URL} | tar xj && \
    curl -# -L ${DCAENC_URL} | tar xz && \
    # Compile opencore-amr.
    echo 'Compiling opencore-amr...' && \
    cd opencore-amr-${OPENCORE_AMR_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-static \
        && \
    make install && \
    cd .. && \
    # Compile twolame.
    echo 'Compiling twolame...' && \
    cd twolame-${TWOLAME_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-static \
        --datarootdir=/tmp/twolame-share \
        && \
    make install && \
    cd .. && \
    # Compile aften.
    echo 'Compiling aften...' && \
    cd aften-${AFTEN_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. -DSHARED=ON -DCMAKE_INSTALL_PREFIX:STRING="/usr" && \
    make install && \
    cd .. && \
    cd .. && \
    # Compile libdca.
    echo 'Compiling libdca...' && \
    cd libdca-${LIBDCA_VERSION} && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr \
        --disable-static \
        --datarootdir=/tmp/libdca-share \
        && \
    make install && \
    cd .. && \
    # Compile dcaenc.
    echo 'Compiling dcaenc...' && \
    cd dcaenc-${DCAENC_VERSION} && \
    autoreconf -f -i -v && \
    ./configure \
        --prefix=/usr \
        --disable-static \
        --disable-alsa \
        && \
    make install && \
    cd .. && \
    # Patch avidemux source.
    echo 'Patching avidemux...' && \
    sed -i -e 's|#ifndef __APPLE__|#if 0 //#ifndef __APPLE__|' avidemux_${AVIDEMUX_VERSION}/avidemux/common/main.cpp && \
    sed -i -e 's|#ifndef __APPLE__|#if 0 //#ifndef __APPLE__|' avidemux_${AVIDEMUX_VERSION}/avidemux/qt4/ADM_jobs/src/ADM_jobs.cpp && \
    sed -i -e 's|#ifndef __APPLE__|#if 0 //#ifndef __APPLE__|' avidemux_${AVIDEMUX_VERSION}/avidemux_core/ADM_core/include/ADM_assert.h && \
    sed -i -e 's|#include <execinfo.h>|//#include <execinfo.h>|' avidemux_${AVIDEMUX_VERSION}/avidemux_core/ADM_core/src/ADM_crashdump_unix.cpp && \
    sed -i -e 's|#if !defined(__HAIKU__) && !defined(__sun__)|#if 0 //#if !defined(__HAIKU__) && !defined(__sun__)|' avidemux_${AVIDEMUX_VERSION}/avidemux_core/ADM_core/src/ADM_crashdump_unix.cpp && \
    sed -i -e 's|canonicalize_file_name(in.c_str())|realpath(in.c_str(), NULL)|' avidemux_${AVIDEMUX_VERSION}/avidemux_core/ADM_core/src/ADM_folder_linux.cpp && \
    sed -i -e 's|^\(END\)\?IF (NOT APPLE)|#\1IF (NOT APPLE)|' avidemux_${AVIDEMUX_VERSION}/avidemux_core/ADM_core/src/CMakeLists.txt && \
    sed -i -e 's|SET(ADM_core_SRCS \(.*\) ADM_memcpy.cpp|#SET(ADM_core_SRCS \1 ADM_memcpy.cpp|' avidemux_${AVIDEMUX_VERSION}/avidemux_core/ADM_core/src/CMakeLists.txt && \
    sed -i -e 's|diaMenuEntry format\[\]={{MP4_MUXER_MP4,"MP4"},{MP4_MUXER_PSP,"PSP"},NULL};|diaMenuEntry format\[\]={{MP4_MUXER_MP4,"MP4",NULL},{MP4_MUXER_PSP,"PSP",NULL}};|' avidemux_${AVIDEMUX_VERSION}/avidemux_plugins/ADM_muxers/muxerMp4/muxerMP4Config.cpp && \
    # Compile avidemux.
    echo 'Compiling avidemux...' && \
    cd avidemux_${AVIDEMUX_VERSION} && \
    chmod +x bootStrap.bash && \
    ./bootStrap.bash && \
    # Install avidemux.
    echo 'Installing avidemux...' && \
    rm -r install/usr/include && \
    find install/usr/bin -type f -exec strip {} ';' && \
    find install/usr/lib -type f -exec strip {} ';' && \
    cp -Rv install/usr/* /usr/ && \
    cd ..  && \
    # Cleanup.
    rm -r \
        /usr/include/opencore-amr* \
        /usr/lib/libopencore-amr*.la \
        /usr/lib/pkgconfig/opencore-amr*.pc \
        /usr/include/twolame.h \
        /usr/lib/pkgconfig/twolame.pc \
        /usr/bin/aften \
        /usr/bin/wavinfo \
        /usr/bin/wavrms \
        /usr/bin/wavfilter \
        /usr/include/aften \
        /usr/include/dca.h \
        /usr/include/dts.h \
        /usr/lib/pkgconfig/libdca.pc \
        /usr/lib/pkgconfig/libdts.pc \
        /usr/lib/libdts.a \
        /usr/bin/dcadec \
        /usr/bin/extract_dca \
        /usr/bin/dtsdec \
        /usr/bin/extract_dts \
        /usr/include/dcaenc.h \
        /usr/lib/pkgconfig/dcaenc.pc \
        /usr/lib/libdcaenc.la \
        /usr/bin/dcaenc \
        && \
    apk del .build-dependencies fdk-aac-dev && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN \
    apk add \
         sqlite-libs \
         qt5-qtbase-x11 \
         glu \
         libvdpau \
         libxv \
         libvorbis \
         lame \
         faac \
         alsa-lib \
         faad2 \
         opus \
         x264-libs \
         x265 \
         xvidcore \
         fribidi \
         fdk-aac \
         libvpx \
         && \
    ln -s libvdpau.so.1 /usr/lib/libvdpau.so

# Get default config
RUN \
    env HOME=/tmp /usr/bin/avidemux3_cli --help > /dev/null && \
    mv /tmp/.avidemux6/config3 /defaults/ && \
    sed -i -e 's|"language" : "",|"language" : "en",|' /defaults/config3 && \
    sed -i -e 's/"enabled" : true,/"enabled" : false,/' /defaults/config3 && \
    rm -r /tmp/.avidemux6

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Avidemux"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
