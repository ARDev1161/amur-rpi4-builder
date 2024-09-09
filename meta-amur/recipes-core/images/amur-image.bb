# require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb
require ${COREBASE}/../meta-raspberrypi/recipes-core/images/rpi-test-image.bb

inherit core-image
inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

SUMMARY = "Custom Yocto Image for Raspberry Pi with Ubuntu 22.02 and ROS Humble"
DESCRIPTION = "${SUMMARY}"

LAYERDEPENDS_meta-amur += "meta-raspberrypi"

IMAGE_FEATURES += "ssh-server-openssh"
EXTRA_IMAGE_FEATURES = "debug-tweaks"

IMAGE_INSTALL:remove = "packagegroup-rpi-test"
IMAGE_INSTALL:append = "packagegroup-rpi-amur \
    wifi-setup \
    piper \
    ros-core \
    rplidar-ros \
"
IMAGE_INSTALL:append = "pciutils usbutils i2c-tools htop"
