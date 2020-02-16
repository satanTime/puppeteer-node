#!/bin/bash

for TAG in $TAGS; do \
  echo "FROM node:${TAG}" > Dockerfile && \
  cat Dockerfile.template >> Dockerfile && \
  docker build . -t satantime/puppeteer-node:$TAG && \
  docker push satantime/puppeteer-node:$TAG && \
  rm Dockerfile; \
done
