#!/bin/bash

set -e

echo ""
echo "-----------------------"
echo "START BUILD YOCTO IMAGE"
echo "-----------------------"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

DL_DIR="${HOME}/cache/dl"
SSTATE_DIR="${HOME}/cache/sstate"
BUILD_DIR="build"

sudo chmod 777 ${SCRIPT_DIR}
if ! command -v bitbake &> /dev/null
then
    source ${SCRIPT_DIR}/poky/oe-init-build-env ${BUILD_DIR}
    cd ${SCRIPT_DIR}
fi

echo "Adding bitbake layers"

pushd ./${BUILD_DIR} &> /dev/null
bitbake-layers add-layer \
    ${SCRIPT_DIR}/meta-openembedded/meta-oe/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-multimedia/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-networking \
    ${SCRIPT_DIR}/meta-openembedded/meta-python \
    ${SCRIPT_DIR}/meta-raspberrypi \
    ${SCRIPT_DIR}/meta-ros/meta-ros-common \
    ${SCRIPT_DIR}/meta-ros/meta-ros2 \
    ${SCRIPT_DIR}/meta-ros/meta-ros2-humble
popd &> /dev/null

num_cores=$(nproc)

echo
echo "Modifying: '${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf'"
LOCAL_CONF_STRING="# ADDED BY '${SCRIPT_DIR}/create-bitbake-conf.sh'"
if grep -q "${LOCAL_CONF_STRING}" "${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf";
then
    :
else
    cat <<EOF >>${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf
${LOCAL_CONF_STRING}
DL_DIR = "${DL_DIR}"
SSTATE_DIR = "${SSTATE_DIR}"
MACHINE = "raspberrypi4-64"
BB_NUMBER_THREADS="${num_cores}"
PARALLEL_MAKE="-j${num_cores}"
LICENSE_FLAGS_ACCEPTED = "synaptics-killswitch"
EOF

   cat <<EOF >>${SCRIPT_DIR}/${BUILD_DIR}/conf/amur-image.bb
SUMMARY = "Custom Yocto Image for Raspberry Pi with Ubuntu 22.02 and ROS Humble"
LICENSE = "MIT"

inherit image

IMAGE_FEATURES += " ssh-server-openssh"
EXTRA_IMAGE_FEATURES = "debug-tweaks"
IMAGE_INSTALL = "packagegroup-base ros-humble-desktop"
IMAGE_INSTALL_append = " ros-core ros-comm ros-perception ros-base ros-control ros-planning ros-simulation"
EOF

fi

echo
echo "Please check '${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf'"
echo
echo "DL_DIR has been set to: '${DL_DIR}'"
echo "SSTATE_DIR has been set to: '${SSTATE_DIR}'"
echo
echo "It should be possible to create a build with:"
echo "bitbake core-image-minimal"

bitbake ros-image-core
