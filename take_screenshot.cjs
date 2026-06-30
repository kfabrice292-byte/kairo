const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: "new" });
  const page = await browser.newPage();
  
  await page.setViewport({ width: 375, height: 812, isMobile: true, hasTouch: true });
  
  await page.goto('file:///C:/Users/HP%20ZBOOK/Downloads/KAIRO/dist/builder.html', { waitUntil: 'networkidle0' });
  
  await page.evaluate(() => {
     document.getElementById('templateSelectionView').classList.add('view-hidden');
     document.getElementById('dashboardView').classList.remove('view-hidden');
     
     const dummyHTML = `
       <div id="doc-cv" class="document-page html2pdf__page-break template-modern watermark-draft w-[210mm] min-w-[210mm] min-h-[297mm] bg-white premium-shadow text-slate-800 text-left relative overflow-hidden shrink-0" style="padding: 40px; font-size: 20px;"><h1>TEST CV</h1><p>This is a test CV page</p></div>
       <div id="doc-lettre" class="document-page html2pdf__page-break template-modern watermark-draft w-[210mm] min-w-[210mm] min-h-[297mm] bg-white premium-shadow text-slate-800 text-left relative overflow-hidden shrink-0" style="padding: 40px; font-size: 20px;"><h1>TEST Lettre</h1><p>This is a test Lettre page</p></div>
     `;
     document.getElementById('documentContainer').innerHTML = dummyHTML;
     
     // add mobileEditMode to body so we can see what edit mode looks like
     // or preview mode (default)
  });
  
  await page.screenshot({ path: 'C:\\Users\\HP ZBOOK\\.gemini\\antigravity-ide\\brain\\313206aa-fc55-40e3-85e9-ef1f0354a4ea\\mobile_mess.png', fullPage: true });
  await browser.close();
})();
