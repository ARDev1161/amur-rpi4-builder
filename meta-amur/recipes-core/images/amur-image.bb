require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb

SUMMARY = "Custom Yocto Image for Raspberry Pi with Ubuntu 22.02 and ROS Humble"
DESCRIPTION = "${SUMMARY}"

inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

IMAGE_FEATURES += "ssh-server-openssh"
EXTRA_IMAGE_FEATURES = "debug-tweaks"
IMAGE_INSTALL:append = " \
    ros-core \
    rplidar-ros \
"
