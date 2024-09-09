SUMMARY = "Piper TTS for arm64"
DESCRIPTION = "Piper TTS (Text-to-Speech) engine for arm64 platform."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Указываем URL архива и его контрольные суммы
SRC_URI = "https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_arm64.tar.gz \
           https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/ru/ru_RU/ruslan/medium/ru_RU-ruslan-medium.onnx;name=ru_RU-ruslan-medium.onnx \
           https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/ru/ru_RU/ruslan/medium/ru_RU-ruslan-medium.onnx.json;name=ru_RU-ruslan-medium.onnx.json \
           https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/bryce/medium/en_US-bryce-medium.onnx;name=en_US-bryce-medium.onnx \
           https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/bryce/medium/en_US-bryce-medium.onnx.json;name=en_US-bryce-medium.onnx.json"

SRC_URI[md5sum] = "478cf4d7e447501ea90953649b9d6ee6"
SRC_URI[sha256sum] = "34b298f6b3e55b55e81f05c6157310f9ec4df3fdd3d73e4c85eb80e218c54d2c"

SRC_URI[ru_RU-ruslan-medium.onnx.md5sum] = "731eb188e63b4c57320e38047ba2d850"
SRC_URI[ru_RU-ruslan-medium.onnx.json.md5sum] = "ae6e273bd38d6ecb05c2d1969b24db0c"
SRC_URI[en_US-bryce-medium.onnx.md5sum] = "a8482817c3bdc3d20121a0e31bfa9809"
SRC_URI[en_US-bryce-medium.onnx.json.md5sum] = "a548d1d4ce8579f5a16926bdec77c7bf"

# Определяем директорию для сборки
S = "${WORKDIR}/piper"

# Игнорируем ошибки QA, связанные с очисткой
INSANE_SKIP:${PN} += "already-stripped ldflags"
INSANE_SKIP:${PN}-dev += "dev-elf"

# Установка бинарных файлов в конечный образ
do_install() {
    install -d ${D}${bindir}/piper
    install -d ${D}${libdir}
    install -d ${D}${sysconfdir}/profile.d

    tar -xzf ${DL_DIR}/piper_arm64.tar.gz -C ${S} --no-same-owner
    echo 'export PATH=$PATH:/usr/bin/piper' > ${S}/piper.sh
    echo 'echo test piper | piper -m /usr/bin/piper/en_US-bryce-medium.onnx -c /usr/bin/piper/en_US-bryce-medium.onnx.json --output_raw | aplay -r 22050 -f S16_LE -t raw -' > ${S}/piper-test.sh

    install -m 0755 ${S}/piper/*.so* ${D}${libdir}
    rm -rf ${S}/piper/*.so*

    # Копируем бинарные файлы и директории рекурсивно
    cp -r ${S}/piper/* ${D}${bindir}/piper
    install -m 0755 ${S}/piper.sh ${D}${sysconfdir}/profile.d/piper.sh
    install -m 0755 ${S}/piper-test.sh ${D}${bindir}/piper/piper-test.sh

    install -m 0755 ${DL_DIR}/ru_RU-ruslan-medium.onnx ${D}${bindir}/piper/ru_RU-ruslan-medium.onnx
    install -m 0755 ${DL_DIR}/ru_RU-ruslan-medium.onnx.json ${D}${bindir}/piper/ru_RU-ruslan-medium.onnx.json
    install -m 0755 ${DL_DIR}/en_US-bryce-medium.onnx ${D}${bindir}/piper/en_US-bryce-medium.onnx
    install -m 0755 ${DL_DIR}/en_US-bryce-medium.onnx.json ${D}${bindir}/piper/en_US-bryce-medium.onnx.json
}

# Указываем, что будет включено в образ
FILES_${PN} = "${bindir}/piper/* ${libdir}/*.so* ${sysconfdir}/profile.d/piper.sh"
