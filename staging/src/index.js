import puppeteer from "puppeteer";

async function launchChrome(options) {
  try {
    return await puppeteer.launch(options);
  } catch {
    return await puppeteer.launch({
      ...options,
      executablePath: "/root/.cache/puppeteer/chrome/chrome-linux64/chrome",
    });
  }
}

(async () => {
  {
    const browser = await launchChrome({
      browser: 'chrome',
      headless: true,
      defaultViewport: {
        width: 1920,
        height: 965,
      },
      args: ['--no-sandbox'],
    });

    let [page] = await browser.pages();
    await page.close();
    await browser.close();

    process.stdout.write("chrome success\n");
  }

  {
    const browser = await puppeteer.launch({
      browser: 'firefox',
      headless: true,
      defaultViewport: {
        width: 1920,
        height: 965,
      },
      args: ['--no-sandbox'],
    });

    let [page] = await browser.pages();
    await page.close();
    await browser.close();

    process.stdout.write("firefox success\n");
  }
})();
