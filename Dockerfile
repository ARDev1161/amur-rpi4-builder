FROM ubuntu:22.04

RUN apt-get -qq update
RUN apt-get -qqy upgrade

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt purge -y libopencv*

RUN apt-get install -y \
      wget \
      unzip \
      tar \
      cpio \
      ssh \
      gdb \
      locales \
# libconfig \
      libconfig++-dev \
      libconfig-dev \
# OpenCV dependencies \
      build-essential \
      cmake \
      git \
      libgtk2.0-dev \
      pkg-config \
      libavcodec-dev \
      libavformat-dev \
      libswscale-dev \
      libtbb2 \
      libtbb-dev \
      libjpeg-dev \
      libpng-dev \
      libtiff-dev \
      python3 \
      python3-dev \
      python3-pip \
      python3-numpy\
# GStreamer dependencies \
      gstreamer1.0*\
      libgstreamer1.0-dev \
      libgstreamer-plugins-base1.0-dev\
# gRPC dependencies
      libssl-dev \
#
#       swig \
#       clang \
#       rsync \
#       python \
#       p7zip-full \
#       bc \
#       expect \
#       qemu-system-aarch64 \
# \
#       libopencv-dev \
#       libopencv-shape-dev \
#       libopencv-video-dev \
#       libopencv-imgproc-dev \
#       libarchive-dev \
# \
#       lzop \
#       libboost-iostreams-dev \
#       genext2fs \
#       xxd \
# \
#       protobuf-compiler \
#       protobuf-compiler-grpc \
#       protobuf-c-compiler \
#       libprotobuf-dev \
#       libprotobuf-c-dev \
#       libgrpc++-dev \
#       libgrpc++1 \
#       libgrpc10 \
# \
#       gettext-base \
  && apt-get clean

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Downloading & installing toolchain
RUN wget https://github.com/ARDev1161/raspberry-cross-toolchain/releases/latest/download/x-tools-aarch64-rpi4-linux-gnu.tar.xz
RUN mkdir -p ~/opt
RUN tar xJf x-tools-aarch64-rpi4-linux-gnu.tar.xz -C ~/opt

# Build thirdparty libraries
ADD scripts /tmp/scripts
RUN wget https://github.com/opencv/opencv/archive/refs/tags/4.7.0.tar.gz && \
    tar -zxf opencv-4.7.0.tar.gz --directory /tmp/build_opencv
RUN /tmp/scripts/install_opencv.sh /tmp/build_opencv
RUN /tmp/scripts/install_grpc.sh
# RUN cd /tmp \
#     && git clone https://github.com/sbabic/libubootenv.git \
#     && cd libubootenv \
#     && cmake . \
#     && make -j$(nproc) \
#     && make install
# RUN rm -rf /tmp/scripts /tmp/build_numcpp /tmp/build_opencv /tmp/build_boost
