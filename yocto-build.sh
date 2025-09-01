#!/bin/bash

set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

IMAGE_NAME="amur-image-humble"

DL_DIR="${HOME}/cache/dl"
SSTATE_DIR="${HOME}/cache/sstate"
BUILD_DIR="${SCRIPT_DIR}/build"

# Default platform and machine; can be overridden by CLI options
PLATFORM="rpi4"
MACHINE_TYPE=""

WIFI_SSID="amur"
WIFI_PASSWORD="sensorika.info-AMUR"

num_cores=$(nproc)

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --image-name NAME      Set the image name (default: $IMAGE_NAME)"
    echo "  --dl-dir DIR           Set the download directory (default: $DL_DIR)"
    echo "  --sstate-dir DIR       Set the sstate cache directory (default: $SSTATE_DIR)"
    echo "  --build-dir DIR        Set the build directory (default: $BUILD_DIR)"
    echo "  --platform NAME        Target platform: rpi4 or cm3588-plus (default: $PLATFORM)"
    echo "  --machine TYPE         Set the Yocto machine (overrides platform default)"
    echo "  --wifi-ssid SSID       Set the Wi-Fi SSID (default: $WIFI_SSID)"
    echo "  --wifi-pass PASS       Set the Wi-Fi password (default: $WIFI_PASSWORD)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --image-name)
            IMAGE_NAME="$2"
            shift
            shift
            ;;
        --dl-dir)
            DL_DIR="$2"
            shift
            shift
            ;;
        --sstate-dir)
            SSTATE_DIR="$2"
            shift
            shift
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift
            shift
            ;;
        --machine)
            MACHINE_TYPE="$2"
            shift
            shift
            ;;
        --wifi-ssid)
            WIFI_SSID="$2"
            shift
            shift
            ;;
        --wifi-pass)
            WIFI_PASSWORD="$2"
            shift
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Determine machine and platform-specific layers
case "$PLATFORM" in
    rpi4)
        MACHINE_TYPE=${MACHINE_TYPE:-"raspberrypi4-64"}
        PLATFORM_LAYERS=(${SCRIPT_DIR}/meta-raspberrypi)
        ;;
    cm3588-plus)
        MACHINE_TYPE=${MACHINE_TYPE:-"cm3588-plus"}
        PLATFORM_LAYERS=(${SCRIPT_DIR}/meta-rockchip)
        ;;
    *)
        echo "Unsupported platform: ${PLATFORM}"
        exit 1
        ;;
esac

echo "-----------------------"
echo "START BUILD YOCTO IMAGE"
echo "-----------------------"

sudo chmod 777 ${SCRIPT_DIR}
if ! command -v bitbake &> /dev/null
then
    source ${SCRIPT_DIR}/poky/oe-init-build-env ${BUILD_DIR}
    cd ${SCRIPT_DIR}
fi

echo
echo "Building image with the following settings:"
echo "  IMAGE_NAME = ${IMAGE_NAME}"
echo "  DL_DIR = ${DL_DIR}"
echo "  SSTATE_DIR = ${SSTATE_DIR}"
echo "  BUILD_DIR = ${BUILD_DIR}"
echo "  PLATFORM = ${PLATFORM}"
echo "  MACHINE_TYPE = ${MACHINE_TYPE}"
echo "  WIFI_SSID = ${WIFI_SSID}"
echo "  WIFI_PASSWORD = ${WIFI_PASSWORD}"
echo

echo "Adding bitbake layers"

pushd ${BUILD_DIR} &> /dev/null
bitbake-layers add-layer \
    ${SCRIPT_DIR}/meta-openembedded/meta-oe/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-multimedia/ \
    ${SCRIPT_DIR}/meta-openembedded/meta-networking \
    ${SCRIPT_DIR}/meta-openembedded/meta-python \
    ${PLATFORM_LAYERS[@]} \
    ${SCRIPT_DIR}/meta-ros/meta-ros-common \
    ${SCRIPT_DIR}/meta-ros/meta-ros2 \
    ${SCRIPT_DIR}/meta-ros/meta-ros2-humble \
    ${SCRIPT_DIR}/meta-amur
popd &> /dev/null

echo "Modifying: '${BUILD_DIR}/conf/local.conf'"

mkdir -p "${BUILD_DIR}/conf/meta-ros/recipes-images"
LOCAL_CONF_STRING="# ADDED BY '${SCRIPT_DIR}/create-bitbake-conf.sh'"
if grep -q "${LOCAL_CONF_STRING}" "${BUILD_DIR}/conf/local.conf";
then
    :
else
    cat <<EOF >>${BUILD_DIR}/conf/local.conf
${LOCAL_CONF_STRING}
DL_DIR = "${DL_DIR}"
SSTATE_DIR = "${SSTATE_DIR}"
MACHINE = "${MACHINE_TYPE}"

BB_NUMBER_THREADS="${num_cores}"
PARALLEL_MAKE="-j${num_cores}"
LICENSE_FLAGS_ACCEPTED = "synaptics-killswitch"
BB_FETCH_PREMIRRORONLY = "0"
BB_FETCH_RETRIES = "3"
BB_NETWORK_TIMEOUT = "3000"
BB_FETCH_TIMEOUT = "3000"
FETCHCMD_git = "git -c http.sslCAInfo=/etc/ssl/certs/ca-certificates.crt"
EOF

fi

cp poky/meta/files/common-licenses/BSD-3-Clause poky/meta/files/common-licenses/BSD

echo
echo "Main config: '${BUILD_DIR}/conf/local.conf'"
echo
echo "DL_DIR has been set to: '${DL_DIR}'"
echo "SSTATE_DIR has been set to: '${SSTATE_DIR}'"

cat <<EOF > ${SCRIPT_DIR}/meta-amur/recipes-connectivity/wifi-setup/files/wpa_supplicant.conf
# Giving configuration update rights to wpa_cli
ctrl_interface=/run/wpa_supplicant
ctrl_interface_group=wheel
update_config=1

network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PASSWORD}"
    scan_ssid=1
    proto=RSN
    key_mgmt=WPA-PSK
    pairwise=CCMP TKIP
    group=CCMP TKIP
}
EOF

bitbake amur-image
IMG_DIR="${BUILD_DIR}/tmp/deploy/images/${MACHINE_TYPE}/"
rm -f "images" && ln -s "${IMG_DIR}" "images"

IMAGE_PATH=$(find "${IMG_DIR}" -name "${IMAGE_NAME}*.wic.bz2" -print -quit)

# Распакуйте .bz2 файл
bzip2 -d "${IMAGE_PATH}" -c > "./amur-image.img"
