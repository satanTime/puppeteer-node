#!/bin/bash

docker buildx create --use --bootstrap \
  --name puppeteer-node \
  --driver docker-container \
  --config ./init-buildx.toml
