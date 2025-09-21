import puppeteer from "rebrowser-puppeteer";

(async () => {
  {
    const browser = await puppeteer.launch({
      product: 'chrome',
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
      product: 'firefox',
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
