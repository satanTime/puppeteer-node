#!/bin/bash

# https://stuffivelearned.org/doku.php?id=misc:docker_x_compile_crash
docker buildx rm puppeteer-node && \
docker run --privileged --rm tonistiigi/binfmt --uninstall 'qemu-*' && \
docker run --privileged --rm tonistiigi/binfmt --install all && \
docker buildx create --use --bootstrap \
  --name puppeteer-node \
  --driver docker-container \
  --config ./init-buildx.toml
