async page => {
  await page.goto("http://127.0.0.1:8783/bori-blog/posts/2603-06570v2/");
  await page.waitForLoadState("networkidle");
  const result = await page.evaluate(async () => {
    const digest = async text => [...new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text)))].map(b => b.toString(16).padStart(2, "0")).join("");
    const body = document.querySelector("article .content").cloneNode(true);
    let node = body.querySelector(":scope > #references");
    while (node) {
      const next = node.nextSibling;
      node.remove();
      node = next;
    }
    const root = document.querySelector("article .content");
    const license = root.querySelector('a[href="https://creativecommons.org/licenses/by/4.0/"]');
    const schema = [...document.querySelectorAll('script[type="application/ld+json"]')].map(e => JSON.parse(e.textContent)).find(e => e["@type"] === "BlogPosting");
    return {
      proseBeforeReferencesSha256: await digest(body.innerHTML),
      visualsSha256: await digest(document.querySelector(".reader-visuals").outerHTML),
      tableSha256: await digest(root.querySelector("table").outerHTML),
      license: license && { href: license.href, text: license.textContent, visible: license.getBoundingClientRect().height > 0 },
      doiTextPresent: root.textContent.includes("https://doi.org/10.48550/arXiv.2603.06570"),
      doiIsClickable: !!root.querySelector('a[href="https://doi.org/10.48550/arXiv.2603.06570"]'),
      authors: document.querySelector(".rv-authors").textContent,
      sourceDate: document.querySelector(".rv-published").dateTime,
      canonical: document.querySelector('link[rel="canonical"]').href,
      datePublished: schema.datePublished,
      schemaVisibleWords: schema.wordCount,
      headings: [...root.querySelectorAll(":scope > h2")].map(e => e.textContent.trim()),
      figure: { src: document.querySelector(".rv-gallery img").getAttribute("src"), caption: document.querySelector(".rv-gallery figcaption").innerText }
    };
  });
  if (result.license) {
    for (const width of [390, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      await page.waitForTimeout(500);
      await page.locator("#references").evaluate(e => scrollTo({ top: scrollY + e.getBoundingClientRect().top - 80, behavior: "instant" }));
      await page.waitForTimeout(100);
      await page.screenshot({ path: `logs/2026-11-03/sureon-validation/after-${width}-references.png` });
    }
    await page.emulateMedia({ media: "print" });
    await page.setViewportSize({ width: 794, height: 1123 });
    result.printLicenseVisible = await page.locator('article .content a[href="https://creativecommons.org/licenses/by/4.0/"]').isVisible();
    await page.pdf({ path: "logs/2026-11-03/sureon-validation/after-print.pdf", format: "A4", printBackground: true });
    await page.emulateMedia({ media: "screen" });
  }
  return result;
}
