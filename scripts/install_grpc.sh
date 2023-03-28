#!/bin/bash

export PROCCESSOR_ARCH=aarch64
export TOOLCHAIN_NAME=aarch64-rpi4-linux-gnu
export TOOLCHAIN_PATH=~/opt/x-tools/${TOOLCHAIN_NAME}
export TOOLCHAIN_UTIL=${TOOLCHAIN_PATH}/bin/${TOOLCHAIN_NAME}
export TOOLCHAIN_TOOLS=${TOOLCHAIN_PATH}/${TOOLCHAIN_NAME}

cd /tmp
git clone https://github.com/grpc/grpc.git -b v1.53.0
pushd "/tmp/grpc"
git submodule update --init --recursive
popd

mkdir /tmp/build_grpc_host
pushd "/tmp/build_grpc_host"
cmake -DBUILD_SHARED_LIBS=ON -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DgRPC_SSL_PROVIDER=package /tmp/grpc
make -j$(nproc) install
popd

mkdir /tmp/build_abseil_host
pushd "/tmp/build_abseil_host"
cmake -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE /tmp/grpc/third_party/abseil-cpp
make -j$(nproc) install
popd

mkdir /tmp/build_grpc
pushd "/tmp/build_grpc"
cmake \
	-DCMAKE_CXX_COMPILER=${TOOLCHAIN_UTIL}-g++ \
	-DCMAKE_C_COMPILER=${TOOLCHAIN_UTIL}-gcc \
	-DCMAKE_AR=${TOOLCHAIN_TOOLS}/ar \
	-DCMAKE_STRIP=${TOOLCHAIN_TOOLS}/strip \
	-DCMAKE_LINKER=${TOOLCHAIN_TOOLS}/ld \
	-DCMAKE_NM=${TOOLCHAIN_TOOLS}/nm \
	-DCMAKE_OBJCOPY=${TOOLCHAIN_TOOLS}/objcopy \
	-DCMAKE_OBJDUMP=${TOOLCHAIN_TOOLS}/objdump \
	-DCMAKE_RANLIB=${TOOLCHAIN_TOOLS}/ranlib \
	-DCMAKE_CROSSCOMPILING=1 \
	-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
	-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
	-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
	-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
	-DCMAKE_SYSTEM_PROCESSOR=${PROCCESSOR_ARCH} \
	-DCMAKE_SYSTEM_NAME=Linux \
	-DBUILD_SHARED_LIBS=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/opt/grpc \
	-D_gRPC_CPP_PLUGIN=/tmp/build_grpc_host/grpc_cpp_plugin \
	/tmp/grpc
make -j$(nproc) install
popd

mkdir /tmp/build_abseil
pushd "/tmp/build_abseil"
cmake \
	-DCMAKE_CXX_COMPILER=${TOOLCHAIN_UTIL}-g++ \
	-DCMAKE_SYSTEM_PROCESSOR=${PROCCESSOR_ARCH} \
	-DCMAKE_SYSTEM_NAME=Linux \
	-DCMAKE_INSTALL_PREFIX=/opt/grpc \
	-DCMAKE_POSITION_INDEPENDENT_CODE=TRUE /tmp/grpc/third_party/abseil-cpp
make -j$(nproc) install
popd

# Next protobuf definition breaks cross-environment
rm -rf /usr/local/lib/cmake/protobuf

echo /usr/local/lib > /etc/ld.so.conf.d/local.conf
ldconfig
