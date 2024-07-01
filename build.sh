#!/bin/bash
docker build -t yocto-builder .
docker run -it  --rm --name yocto-builder-container --mount type=bind,src="$(pwd)",target=/home/build yocto-builder bash -c "sudo ./yocto-build.sh"
