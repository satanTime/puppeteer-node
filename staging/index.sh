#!/bin/bash

echo "FROM node:${1}" > ./Dockerfile && \
  cat ../docker/Dockerfile >> ./Dockerfile && \
  echo "WORKDIR /src" >> ./Dockerfile && \
  echo "ENV PUPPETEER_SKIP_DOWNLOAD=true" >> ./Dockerfile && \
  echo "ENV DEBIAN_FRONTEND=noninteractive" >> ./Dockerfile && \
  echo "CMD sh test.sh" >> ./Dockerfile && \
  docker compose run --rm --build staging
