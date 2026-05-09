#!/bin/sh

set -e

export PUPPETEER_SKIP_DOWNLOAD=true
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends unzip
rm -rf /var/lib/apt/lists/*

npm install
npx puppeteer browsers install chrome
npx puppeteer browsers install firefox
find /root/.cache/puppeteer/ -name '*.zip' -execdir unzip -oq {} \;

node index.js
