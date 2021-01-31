# Puppeteer Node for CI

Documentation how to configure continuous integration for Angular applications
is on https://satantime.github.io/puppeteer-node/.

## Motivation

The motivation of this repo is to provide all versions of node images with a single layer on top
that contains only dependencies for puppeteer.

The image does not contain puppeteer itself because different versions of the webdriver require
specific versions of Chrome Browser. This makes tough providing images with specific node version and puppeteer
for all webdriver versions.
  
Therefore, which puppeteer to install and to use is up to you, it is just one line of code.

## Warnings

- no alpine images
- should you not find node version you want, please open [an issue on GitHub](https://github.com/satanTime/puppeteer-node/issues/new)
