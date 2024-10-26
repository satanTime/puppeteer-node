#!/bin/bash

# https://stuffivelearned.org/doku.php?id=misc:docker_x_compile_crash
# https://github.com/docker/buildx/issues/1170
# Errors were encountered while processing: libc-bin
docker buildx rm puppeteer-node && \
docker run --privileged --rm tonistiigi/binfmt --uninstall 'qemu-*' && \
docker run --privileged --rm tonistiigi/binfmt --install all && \
docker run --privileged --rm multiarch/qemu-user-static --reset -p yes -c yes && \
docker buildx create --use --bootstrap \
  --name puppeteer-node \
  --driver docker-container \
  --config ./init-buildx.toml
