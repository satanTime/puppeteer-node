# How to set up continuous integration that executes unit and end to end tests for an Angular 2+ app

This article describes **how to configure continuous integration for Angular** applications
to automatically execute their tests. 

There are examples for [Bitbucket Pipelines](#configure-bitbucket-pipelines) and [CircleCI](#configure-circleci).

- [1. Install puppeteer as a dev dependency](#1-install-puppeteer-as-a-dev-dependency)
- [2. Configure webdriver](#2-configure-webdriver)
- [3. Configure Karma in Angular 2+ app to use puppeteer for CI](#3-configure-karma-in-angular-2-app-to-use-puppeteer-for-ci)
- [4. Configure Protractor in Angular 2+ app to use puppeteer for CI](#4-configure-protractor-in-angular-2-app-to-use-puppeteer-for-ci)
* [Configure BitBucket pipelines](#configure-bitbucket-pipelines)
* [Configure CircleCI](#configure-circleci)
  - [IE11 on CI](#ie11-on-ci)
- [Fast match of versions](#fast-match-of-versions)

## 1. Install puppeteer as a dev dependency

The first step is to decide which Chromium version (Chrome Browser) you want to use for tests.

Not all version are supported. You need to check puppeteer versions first.
At the moment of writing the article puppeteer version `15.3.x` works with the version `103.x` of Chromium (Chrome Browser).
Let's proceed with it.

```bash
npm install --save-dev 'puppeteer@~15.3.0'
```

## 2. Configure webdriver

Another news is that the webdriver also needs a specific version of the chromedriver to work with the chosen Chromium.

We need to go to [chromedriver downloads](https://chromedriver.chromium.org/downloads) and to choose a version
that supports `103.x`. At the moment of writing the article it is `ChromeDriver 103.0.5060.53`.

To configure it we need to edit `package.json` and add there a `postinstall` script.

```json
{
  "scripts": {
    "postinstall": "webdriver-manager update --versions.chrome 103.0.5060.53 --gecko=false"
  }
}
```

The next step is to disable automatic updates of the webdriver when we're executing `e2e` tests.
For that we need to add `--webdriver-update=false` flag to `e2e` script in `package.json`.

```json
{
  "scripts": {
    "e2e": "ng e2e --webdriver-update=false"
  }
}
```

## 3. Configure Karma in Angular 2+ app to use puppeteer for CI

Update `src/karma.conf.js` with the next changes.

```javascript
// important to add
process.env.CHROME_BIN = require('puppeteer').executablePath();

module.exports = function(config) {
  config.set({
    // ...
    customLaunchers: {
      // you can define a browser configuration, 
      // then simply copy the whole section
      ChromeCi: {
        base: 'ChromeHeadless',
        flags: [
          '--headless',
          '--disable-gpu',
          '--window-size=800,600',
          // important to add
          '--no-sandbox',
          // important to add
          '--disable-dev-shm-usage',
        ],
      },
    },
    // ...
  });
};
```

## 4. Configure Protractor in Angular 2+ app to use puppeteer for CI

Update `e2e/protractor.conf.js` with the next changes.

```javascript
exports.config = {
  // ...
  capabilities: {
    browserName: 'chrome',
    chromeOptions: {
      args: [
        '--headless',
        '--disable-gpu',
        '--window-size=800,600',
        // important to add
        '--no-sandbox',
        // important to add
        '--disable-dev-shm-usage',
      ],
      // important to add
      binary: require('puppeteer').executablePath(),
    },
  },
  // ...
};
```

## Configure BitBucket pipelines

Let's assume you want to use [puppeteer](https://pptr.dev)
with `node` `v20.9.0` on `bookworm`,
which means base image is `node:20.9.0-bookworm`,
then you only need to replace `node` with `satantime/puppeteer-node`.

An example of `bitbucket-pipelines.yml` how to run unit and e2e tests:

```yaml
# replace 20.9.0-bookworm here with the version of node you need
image: satantime/puppeteer-node:20.9.0-bookworm

pipelines:
  default:
    - step: &Tests
        name: Tests
        caches:
          - node
        script:
          - npm install
          - npm run postinstall
          # remove --browsers=ChromeCi,
          # if you didn't configure it in karma.conf.js
          - >
            npm run test --
            --browsers=ChromeCi
            --no-watch
            --no-progress
          - npm run e2e
  pull-requests:
    '**':
      - step: *Tests
  branches:
    '**':
      - step: *Tests
```

## Configure CircleCI

Let's assume you want to use [puppeteer](https://pptr.dev)
with `node` `v20.9.0` on `bookworm`,
which means base image is `node:20.9.0-bookworm`,
then you only need to replace `node` with `satantime/puppeteer-node`.

An example of `.circleci/config.yml` how to run unit and e2e tests.

```yaml
version: 2.1
jobs:
  build:
    docker:
      # replace 20.9.0-bookworm here with the version of node you need
      - image: satantime/puppeteer-node:20.9.0-bookworm
    steps:
      - checkout
      - restore_cache:
          key: cache
      - run:
          name: Install
          command: |
            if [ ! -d "./node_modules/" ]; then
              npm ci && npm run postinstall
            fi
      - save_cache:
          key: cache
          paths:
            - ./node_modules
      - run:
          name: Unit Tests
          # remove --browsers=ChromeCi,
          # if you didn't configure it in karma.conf.js
          command: >
            npm run test --
            --browsers=ChromeCi
            --no-watch
            --no-progress
      - run:
          name: End to End Tests
          command: npm run e2e
```

### IE11 on CI

`CicleCI` provides Windows machines,
therefore we can use continuous integration to **run tests in Internet Explorer 11**, if it is needed.

Update `src/karma.conf.js` with info about `IECi` in `customLaunchers`:

```javascript
module.exports = function(config) {
  config.set({
    // ...
    customLaunchers: {
      // ...
      // Add the definition for IE
      IECi: {
        base: 'IE',
        // important to add
        flags: ['-extoff'],
      },
      // ...
    },
    // ...
  });
};
```

Then update `.circleci/config.yml` with a new step for `IE`:

```yaml
version: 2.1
orbs:
  # important to add
  windows: circleci/windows@5.0.0
jobs:
  # important to add
  IE:
    executor:
      name: windows/server-2019
      size: medium
      shell: bash.exe
    steps:
      - checkout
      - restore_cache:
          key: cache-{{ arch }}
      - run:
          name: NPM Install
          command: |
            if [ ! -d "e2e/a5es5/node_modules/" ]; then
              npm ci --no-optional --ignore-scripts
            fi
      - save_cache:
          key: root-{{ arch }}
          paths:
            - ./node_modules
      - run:
          name: Unit Tests
          command: >
            npm run test --
            --browsers=IECi
            --no-watch
            --no-progress
    environment:
      IE_BIN: 'C:\Program Files\Internet Explorer\iexplore.exe'
```

## Fast match of versions

| puppeteer |    chromedriver |
|----------:|----------------:|
|    15.3.x |   103.0.5060.53 |
|    15.2.x |   103.0.5060.53 |
|    15.1.x |   103.0.5060.53 |
|    15.0.x |   103.0.5060.53 |
|    14.4.x |   103.0.5060.53 |
|    14.3.x |   103.0.5060.53 |
|    14.2.x |   103.0.5060.53 |
|    14.1.x |   101.0.4951.41 |
|    14.0.x |   101.0.4951.41 |
|    13.7.x |   101.0.4951.41 |
|    13.6.x |   101.0.4951.41 |
|    13.5.x |    99.0.4844.51 |
|    13.4.x |    99.0.4844.51 |
|    13.3.x |    99.0.4844.51 |
|    13.2.x |    99.0.4844.51 |
|    13.1.x |    97.0.4692.71 |
|    13.0.x |    97.0.4692.71 |
|    12.0.x |    97.0.4692.71 |
|    11.0.x |    93.0.4577.63 |
|    10.4.x |    93.0.4577.63 |
|    10.2.x |    93.0.4577.63 |
|    10.1.x |    91.0.4472.19 |
|    10.0.x |    91.0.4472.19 |
|     9.1.x |    91.0.4472.19 |
|     9.0.x |    91.0.4472.19 |
|     8.0.x |    90.0.4430.24 |
|     7.1.x |    90.0.4430.24 |
|     7.0.x |    90.0.4430.24 |
|     6.0.x |    88.0.4324.27 |
|     5.5.x |    88.0.4324.27 |
|     5.4.x |    86.0.4240.22 |
|     5.3.x |    85.0.4183.38 |
|     5.2.x |    85.0.4183.38 |
|     5.1.x |    84.0.4147.30 |
|     5.0.x |    83.0.4103.39 |
|     4.0.x |    83.0.4103.39 |
|     3.3.x |    83.0.4103.39 |
|     3.2.x |    83.0.4103.39 |
|     3.1.x |    83.0.4103.39 |
|     3.0.x |    81.0.4044.69 |
|     2.1.x |   80.0.3987.106 |
|     2.0.x |    79.0.3945.36 |
|    1.20.x |   78.0.3904.105 |
|    1.19.x |    77.0.3865.40 |
|    1.17.x |   76.0.3809.126 |
|    1.15.x |   75.0.3770.140 |
