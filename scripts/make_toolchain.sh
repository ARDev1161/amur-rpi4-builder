#!/bin/bash

CT_NG_VERSION=1.25.0

# Get source code
echo "Crosstool-ng downloading..."
wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CT_NG_VERSION}.tar.bz2
tar xjf crosstool-ng-${CT_NG_VERSION}.tar.bz2
cd crosstool-ng-${CT_NG_VERSION}

# Build & install
echo "Crosstool-ng building..."
./bootstrap
./configure --enable-local
make
make install

# Select a base-line configuration
echo "Crosstool-ng making configuration..."
./ct-ng aarch64-rpi4-linux-gnu

# Build
echo "Building toolchain..."
./ct-ng build

echo "export PATH=$PATH:~/x-tools/aarch64-rpi4-linux-gnu/bin/" > ~/.bashrc
export RPI4_CXX_COMPILER=aarch64-rpi4-linux-gnu-g++
export RPI4_C_COMPILER=aarch64-rpi4-linux-gnu-gcc
