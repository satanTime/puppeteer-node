# Puppeteer Node for CI

Documentation is on [satantime.github.io](https://satantime.github.io/puppeteer-node/).

## Motivation

The motivation of this repo is to provide all versions of node images with a single layer on top
that contains only dependencies for puppeteer.

The image does not contain puppeteer itself because different versions of the webdriver require
specific versions of Chrome Browser. This makes tough providing images with specific node version and puppeteer
for all webdriver versions.
  
Therefore, which puppeteer to install and to use is up to you, it is just one line of code.
