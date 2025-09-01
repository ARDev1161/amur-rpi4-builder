amur-rpi-builder
===

Docker image for building libraries for embedded targets.
Supported platforms:

- Raspberry Pi 4
- CM3588 Plus (requires `meta-rockchip` layer)

## Prerequisites
Docker

## Build
```
git clone --recurse-submodules https://github.com/ARDev1161/amur-rpi4-builder.git
cd amur-rpi4-builder
```

To build for Raspberry Pi 4 (default):

```
./build.sh --platform rpi4
```

To build for CM3588 Plus, ensure the `meta-rockchip` layer is available at
`meta-rockchip` and then run:

```
./build.sh --platform cm3588-plus
```
