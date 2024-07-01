#!/bin/bash

set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

DL_DIR="${HOME}/cache/dl"
SSTATE_DIR="${HOME}/cache/sstate"
BUILD_DIR="build"
if ! command -v bitbake &> /dev/null
then
    source ${SCRIPT_DIR}/poky/oe-init-build-env ${BUILD_DIR}
    cd ${SCRIPT_DIR}
fi

echo "Adding bitbake layers"

pushd ./${BUILD_DIR} &> /dev/null
bitbake-layers add-layer \
    ${SCRIPT_DIR}/meta-intel/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-oe/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-multimedia/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-networking \
    ${SCRIPT_DIR}/meta-openembedded/meta-python \
    ${SCRIPT_DIR}/meta-clang/ \
    ${SCRIPT_DIR}/meta-raspberrypi \
    ${SCRIPT_DIR}/meta-ros/meta-ros-common \
    ${SCRIPT_DIR}/meta-ros/meta-ros2 \
    ${SCRIPT_DIR}/meta-ros/meta-ros2-humble
popd &> /dev/null

echo
echo "Modifying: '${SCRIPT_DIR}/poky/build/conf/local.conf'"
LOCAL_CONF_STRING="# ADDED BY '${SCRIPT_DIR}/create-bitbake-conf.sh'"
if grep -q "${LOCAL_CONF_STRING}" "${SCRIPT_DIR}/poky/build/conf/local.conf";
then
    :
else
    cat <<EOF >>${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf

num_cores=$(nproc)

${LOCAL_CONF_STRING}
DL_DIR = "${DL_DIR}"
SSTATE_DIR = "${SSTATE_DIR}"
MACHINE = "raspberrypi4-64"
BB_NUMBER_THREADS="$num_cores"
PARALLEL_MAKE="-j$num_cores"
IMAGE_INSTALL:append = " ros-core"
IMAGE_INSTALL:append = " ros-comm"
IMAGE_INSTALL:append = " ros-perception"
IMAGE_INSTALL:append = " ros-base"
IMAGE_INSTALL:append = " ros-control"
IMAGE_INSTALL:append = " ros-planning"
IMAGE_INSTALL:append = " ros-simulation"

# Enable building OpenVINO Python API.
# This requires meta-python layer to be included in bblayers.conf.
PACKAGECONFIG:append:pn-openvino-inference-engine = " python3"

# This adds OpenVINO related libraries in the target image.
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine"

# This adds OpenVINO samples in the target image.
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine-samples"

# Include OpenVINO Python API package in the target image.
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine-python3"

# Enable MYRIAD plugin
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-inference-engine-vpu-firmware"

# Include Model Optimizer in the target image.
CORE_IMAGE_EXTRA_INSTALL:append = " openvino-model-optimizer"
EOF

fi

echo
echo "Please check '${SCRIPT_DIR}/poky/build/conf/local.conf'"
echo
echo "DL_DIR has been set to: '${DL_DIR}'"
echo "SSTATE_DIR has been set to: '${SSTATE_DIR}'"
echo
echo
echo "It should be possible to create a build with:"
echo "bitbake core-image-minimal"
