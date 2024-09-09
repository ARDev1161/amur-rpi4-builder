SUMMARY = "Wi-Fi Auto Configuration"
DESCRIPTION = "Auto configure Wi-Fi using connman during the first boot."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wpa_supplicant.conf \
           file://wifi.sh"

inherit update-rc.d

INITSCRIPT_NAME = "wifi.sh"
INITSCRIPT_PARAMS = "defaults"

do_install() {
    # Install connmann config
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 0644 ${WORKDIR}/wpa_supplicant.conf ${D}${sysconfdir}/wpa_supplicant

    # Install startup script
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/wifi.sh ${D}${sysconfdir}/init.d/
}

# Указываем путь, где должен находиться файл конфигурации и скрипт разблокировки wifi в конечной системе
FILES_${PN} += "${sysconfdir}/wpa_supplicant/wpa_supplicant.conf ${sysconfdir}/init.d/wifi.sh"
