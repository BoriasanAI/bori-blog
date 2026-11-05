async page => {
  const result = { url: page.url(), viewports: [] };
  for (const width of [390, 1440]) {
    await page.setViewportSize({ width, height: 900 });
    await page.waitForTimeout(300);
    const meter = await page.evaluate(() => {
      const content = document.querySelector("article .content");
      const clone = content.cloneNode(true);
      clone.querySelectorAll("nav,svg,script,style,.cf-signature,figure").forEach(e => e.remove());
      const words = text => (text.match(/\b[A-Za-z]+(?:['’-][A-Za-z]+)*\b/g) || []).length;
      return {
        viewport: innerWidth, documentWidth: document.documentElement.scrollWidth,
        overflowPx: Math.max(0, document.documentElement.scrollWidth - innerWidth),
        contentWords: words(clone.innerText || clone.textContent),
        paragraphWords: [...clone.querySelectorAll("p")].reduce((n, e) => n + words(e.innerText || e.textContent), 0),
        headings: [...content.querySelectorAll("h2,h3")].map(e => ({ text: e.innerText, id: e.id })),
        toc: [...document.querySelectorAll("#toc a,#toc-popup-content a")].map(e => ({
          text: e.innerText, href: e.getAttribute("href"),
          resolves: !!document.getElementById(decodeURIComponent(e.hash.slice(1)))
        })),
        sourceLinks: [...content.querySelectorAll("a[href]")].map(e => ({ text: e.innerText, href: e.href })),
        references: [...content.querySelectorAll("h2,h3")].some(e => /references|bibliography/i.test(e.innerText)),
        heroImages: [...document.querySelectorAll("article img")].map(e => ({ alt: e.alt, src: e.getAttribute("src") })),
        cfCount: document.querySelectorAll(".cf-signature").length,
        overflowElements: [...document.querySelectorAll("article *")].filter(e => {
          const r = e.getBoundingClientRect();
          return r.width > 0 && (r.right > innerWidth + 1 || r.left < -1);
        }).slice(0, 10).map(e => ({ tag: e.tagName, cls: e.className, width: e.getBoundingClientRect().width, text: e.innerText?.slice(0, 100) }))
      };
    });
    result.viewports.push(meter);
    await page.locator("article").scrollIntoViewIfNeeded();
    await page.screenshot({ path: `logs/2026-11-03/sureon-validation/before-${width}-intro.png` });
    await page.locator(".cf-signature").scrollIntoViewIfNeeded();
    await page.screenshot({ path: `logs/2026-11-03/sureon-validation/before-${width}-cf.png` });
  }
  return result;
}
