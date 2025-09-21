#!/bin/bash

echo "FROM node:${1}" > ./Dockerfile && \
  cat ../docker/Dockerfile >> ./Dockerfile && \
  cat ./docker/Dockerfile >> ./Dockerfile && \
  docker compose run --rm --build staging
