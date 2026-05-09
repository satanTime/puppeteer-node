# Puppeteer Node for CI

The purpose of this repository is to provide all versions of the official [Node.js images](https://hub.docker.com/_/node) with a single additional layer
that contains only the dependencies required by [Puppeteer](https://pptr.dev).

The [Puppeteer](https://pptr.dev) version you install and use is up to you, and switching to this image requires only one line of code.

[`satantime/puppeteer-node` images](https://hub.docker.com/r/satantime/puppeteer-node) do not contain [Puppeteer](https://pptr.dev) itself,
because different versions of libraries, such as [WebdriverIO](https://webdriver.io), might require
specific versions of [Chrome](https://www.chromium.org/Home/).
Providing images for every possible combination would be difficult.

## Example

For example, if you want to use [Puppeteer](https://pptr.dev) with `node` `v20.9.0` on `bookworm`, where the base image is `node:20.9.0-bookworm`, you only need to replace `node` with `satantime/puppeteer-node`:

#### Dockerfile
```Dockerfile
FROM satantime/puppeteer-node:20.9.0-bookworm
```
#### compose.yml
```yaml
services:
  service-name:
    image: satantime/puppeteer-node:20.9.0-bookworm
```

## Warnings

- Alpine images are not supported.
- If you cannot find the Node.js version you need, please open [an issue on GitHub](https://github.com/satanTime/puppeteer-node/issues/new).

## Testing Angular

Documentation for configuring continuous integration for Angular applications is available at [https://sudo.eu/1/angular-e2e-with-puppeteer/](https://sudo.eu/1/angular-e2e-with-puppeteer/).
