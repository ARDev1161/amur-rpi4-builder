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
    ${SCRIPT_DIR}/meta-ros/meta-ros2-humble \
    ${SCRIPT_DIR}/meta-amur
popd &> /dev/null

num_cores=$(nproc)

echo "Modifying: '${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf'"
mkdir -p "${SCRIPT_DIR}/${BUILD_DIR}/conf/meta-ros/recipes-images"
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
BB_FETCH_PREMIRRORONLY = "0"
BB_FETCH_RETRIES = "3"
BB_NETWORK_TIMEOUT = "3000"
BB_FETCH_TIMEOUT = "3000"
FETCHCMD_git = "git -c http.sslCAInfo=/etc/ssl/certs/ca-certificates.crt"

ROS_DISTRO="humble"
ROS_DISTRO_BASELINE_PLATFORM="ubuntu-jammy"
ROS_VERSION="2"
EOF

fi

cp poky/meta/files/common-licenses/BSD-3-Clause poky/meta/files/common-licenses/BSD

echo
echo "Please check '${SCRIPT_DIR}/${BUILD_DIR}/conf/local.conf'"
echo
echo "DL_DIR has been set to: '${DL_DIR}'"
echo "SSTATE_DIR has been set to: '${SSTATE_DIR}'"
echo
echo "It should be possible to create a build with:"
echo "bitbake core-image-minimal"

# bitbake ros-image-core
bitbake amur-image
