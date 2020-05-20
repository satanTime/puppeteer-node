## Motivation

The motivation of this repo is to provide all versions of node images with a single layer on top
that contains only dependencies for puppeteer.

The image does not contain puppeteer itself because different versions of the webdriver require
specific versions of Chrome Browser. This makes tough providing images with specific node version and puppeteer
for all webdriver versions.
  
Therefore, which puppeteer to install and to use is up to you, it is just one line of code.

#### Warnings

* no alpine images
* should you not find node version you want, please open an issue on https://github.com/satanTime/puppeteer-node/issues

#### Fast match of versions
| puppeteer | chromedriver  |
|----------:|--------------:|
| 3.1.x     | 83.0.4103.39  |
| 3.0.x     | 81.0.4044.69  |
| 2.1.x     | 80.0.3987.106 |
| 2.0.x     | 79.0.3945.36  |
| 1.20.x    | 78.0.3904.105 |
| 1.19.x    | 77.0.3865.40  |
| 1.17.x    | 76.0.3809.126 |
| 1.15.x    | 75.0.3770.140 |

## How to set up continuous integration that executes unit and end to end tests for an Angular 2+ app

### 1. Install puppeteer as a dev dependency

The first step is to decide which Chromium version (Chrome Browser) you want to use for tests.

Not all version are supported. You need to check puppeteer versions first.
At the moment of writing the article puppeteer version `3.0.x` works with the version `81.x` of Chromium (Chrome Browser).
Let's proceed with it.
```bash
npm install --save-dev 'puppeteer@~3.0.2'
```

### 2. Configure webdriver

Another news is that the webdriver also needs a specific version of the chromedriver to work with the chosen Chromium.

We need to go to [chromedriver downloads](https://chromedriver.chromium.org/downloads) and to choose a version
that supports `81.x`. At the moment of writing the article it is `ChromeDriver 81.0.4044.69`.

To configure it we need to edit `package.json` and add there a `postinstall` script.
```json
{
    "scripts": {
        "postinstall": "node_modules/protractor/bin/webdriver-manager update --versions.chrome 81.0.4044.69"
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

### 3. Configure Karma in Angular 2+ app to use puppeteer for CI

Update `src/karma.conf.js` with the next changes.
```javascript
process.env.CHROME_BIN = require('puppeteer').executablePath(); // <- important to add

module.exports = function(config) {
    config.set({
        // ...
        customLaunchers: {
            ChromeCi: { // <- you can define a browser configuration, then simply copy the whole section
                base: 'ChromeHeadless',
                flags: [
                    '--headless',
                    '--disable-gpu',
                    '--window-size=800,600',
                    '--no-sandbox', // <- important to add
                    '--disable-dev-shm-usage', // <- important to add
                ],
            },
        },
        // ...
    });
};
```

### 4. Configure Protractor in Angular 2+ app to use puppeteer for CI

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
                '--no-sandbox', // <- important to add
                '--disable-dev-shm-usage', // <- important to add
            ],
            binary: require('puppeteer').executablePath(), // <- important to add
        },
    },
    // ...
};
```

### Configure bitbucket pipelines
An example of `bitbucket-pipelines.yml` how to run unit and e2e tests.
```yaml
image: satantime/puppeteer-node:12.16.1-buster # put here version you need

pipelines:
    default:
        - step: &Tests
              name: Tests
              caches:
                  - node
              script:
                  - npm install
                  - npm run postinstall
                  # remove --browsers=ChromeCi if you didn't configure it in karma.conf.js
                  - npm run test -- --browsers=ChromeCi --no-watch --no-progress
                  - npm run e2e
    pull-requests:
        '**':
            - step: *Tests
    branches:
        '**':
            - step: *Tests
```

### Configure CircleCI
An example of `.circleci/config.yml` how to run unit and e2e tests.
```yaml
version: 2.1
jobs:
    build:
        docker:
            - image: satantime/puppeteer-node:12.16-buster # put here version you need
        steps:
            - checkout
            - restore_cache:
                  key: cache
            - run:
                  name: Install
                  command: npm install && npm run postinstall
            - save_cache:
                  key: cache
                  paths:
                      - ./node_modules
            - run:
                  name: Unit Tests
                  # remove --browsers=ChromeCi if you didn't configure it in karma.conf.js
                  command: npm run test -- --browsers=ChromeCi --no-watch --no-progress
            - run:
                  name: End to End Tests
                  command: npm run e2e
```
