const puppeteer = require('puppeteer');

const delay = ms => new Promise(res => setTimeout(res, ms));

(async () => {
  console.log("Launching browser...");
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
  const page = await browser.newPage();
  
  await page.setViewport({ width: 1440, height: 900 });

  console.log("Navigating to KAIRO PRO...");
  try {
    await page.goto('http://localhost:5174/kairo-pro.html', { waitUntil: 'networkidle2', timeout: 15000 });
    await delay(2000); // Wait for CSS animations to finish
    await page.screenshot({ path: 'kairo-pro-screenshot-v2.png', fullPage: true });
    console.log("Screenshot saved: kairo-pro-screenshot-v2.png");
  } catch (e) {
    console.error("Failed to load KAIRO PRO:", e);
  }

  console.log("Navigating to PRO LOGIN...");
  try {
    await page.goto('http://localhost:5174/pro-login.html', { waitUntil: 'networkidle2', timeout: 15000 });
    await delay(1000); // Wait for CSS
    await page.screenshot({ path: 'pro-login-screenshot-v2.png', fullPage: true });
    console.log("Screenshot saved: pro-login-screenshot-v2.png");
  } catch (e) {
    console.error("Failed to load PRO LOGIN:", e);
  }

  await browser.close();
})();
