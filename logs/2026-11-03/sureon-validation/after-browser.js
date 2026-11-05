async page => {
  const failures = [];
  const consoleErrors = [];
  const pageErrors = [];
  page.on("pageerror", e => pageErrors.push(e.message));
  page.on("console", e => { if (e.type() === "error") consoleErrors.push(e.text()); });
  await page.goto("http://127.0.0.1:8783/bori-blog/posts/2603-06570v2/");
  await page.waitForLoadState("networkidle");
  const expected = ["Overview", "Problem and context", "Method", "Data and curation", "Evaluation design", "Results", "Limitations", "Interpretation", "References"];
  const check = (condition, message) => { if (!condition) failures.push(message); };
  const article = await page.evaluate(() => {
    const root = document.querySelector("article .content");
    const wordCount = text => (text.match(/\b[A-Za-z]+(?:['’-][A-Za-z]+)*\b/g) || []).length;
    const tokens = text => text.trim().split(/\s+/).filter(Boolean).length;
    const prose = [];
    const citations = [];
    let section = "";
    for (const node of root.children) {
      if (node.tagName === "H2") section = node.textContent.trim();
      if (node.tagName !== "P" || section === "References") continue;
      const copy = node.cloneNode(true);
      copy.querySelectorAll("a").forEach(a => a.remove());
      const text = copy.textContent.trim();
      if (tokens(text) < 15) {
        if (node.querySelector('a[href*="arxiv.org"]')) citations.push(node.textContent.trim());
        continue;
      }
      const inline = [...node.querySelectorAll('a[href*="arxiv.org/html/2603.06570v2"]')];
      const sibling = node.nextElementSibling;
      const following = sibling?.tagName === "P" && tokens(sibling.textContent) < 25
        ? [...sibling.querySelectorAll('a[href*="arxiv.org/html/2603.06570v2"]')] : [];
      prose.push({ section, whitespaceWords: tokens(text), englishWords: wordCount(text), inlineCitations: inline.length, followingCitations: following.length });
    }
    const schemas = [...document.querySelectorAll('script[type="application/ld+json"]')].map(e => JSON.parse(e.textContent));
    const images = [...document.querySelectorAll(".reader-visuals img")].map(e => ({
      src: e.getAttribute("src"), alt: e.alt, naturalWidth: e.naturalWidth, naturalHeight: e.naturalHeight,
      width: e.getBoundingClientRect().width, height: e.getBoundingClientRect().height,
      caption: e.closest("figure")?.querySelector("figcaption")?.innerText,
      originalLink: e.closest("figure")?.querySelector("a")?.href
    }));
    return {
      title: document.title, canonical: document.querySelector('link[rel="canonical"]').href,
      headings: [...root.querySelectorAll(":scope > h2")].map(e => ({ text: e.innerText.trim(), id: e.id })),
      proseParagraphs: prose, proseWhitespaceWords: prose.reduce((n, p) => n + p.whitespaceWords, 0),
      proseEnglishWords: prose.reduce((n, p) => n + p.englishWords, 0), citationParagraphs: citations.length,
      sourceLinks: [...root.querySelectorAll("a[href]")].filter(a => a.href.startsWith("https://")).map(a => ({ text: a.textContent, href: a.href })),
      schema: schemas.filter(s => s["@type"] === "BlogPosting"),
      allSchemasValid: true, images,
      outline: [...document.querySelectorAll(".rv-outline .rv-node-list a")].map(a => ({
        text: a.textContent.trim(), href: a.getAttribute("href"),
        resolves: !!document.getElementById(new URL(a.href).hash.slice(1))
      })),
      outlineRects: document.querySelectorAll(".rv-outline svg rect").length,
      sourceAuthors: document.querySelector(".rv-authors")?.innerText,
      sourceDate: document.querySelector(".rv-published")?.getAttribute("datetime"),
      timelineDates: [...document.querySelectorAll(".rv-timeline time")].map(t => t.dateTime),
      forbiddenAuxiliary: { cf: document.querySelectorAll(".cf-signature").length, sv: document.querySelectorAll(".sv-chart").length, cta: document.querySelectorAll(".bori-cta").length, emotionalHero: [...document.querySelectorAll("article img")].filter(e => /Emotional landscape/i.test(e.alt)).length },
      tables: [...root.querySelectorAll("table")].map(t => ({ text: t.innerText, rows: t.rows.length, cells: [...t.rows].map(r => [...r.cells].map(c => c.textContent.trim())), wrapper: { cls: t.parentElement.className, role: t.parentElement.getAttribute("role"), tabIndex: t.parentElement.tabIndex, label: t.parentElement.getAttribute("aria-label") } })),
      rawMarkupMatches: root.innerText.match(/\{%|\{\{|\\begin\{|\\end\{|\\frac\{|!\[[^\]]*\]\(|\*\*|cid:\d+|\/Type\s*\/Page|endobj/g) || [],
      replacementCharacters: (root.innerText.match(/\uFFFD/g) || []).length,
      literalHtml: root.innerText.match(/<\/?(?:p|div|table|script|h[1-6])(?:\s|>)/gi) || []
    };
  });
  check(JSON.stringify(article.headings.map(h => h.text)) === JSON.stringify(expected), "Main article must have 8 roles plus References");
  check(article.proseParagraphs.length === 35, "Expected 35 substantive prose paragraphs");
  check(article.proseWhitespaceWords >= 1200 && article.proseWhitespaceWords <= 2000, "Evidence prose must be 1200–2000 words excluding citations/references");
  check(article.proseParagraphs.every(p => p.inlineCitations + p.followingCitations > 0), "Every prose paragraph needs an immediately associated paper citation");
  check(article.outlineRects === 9 && article.outline.length === 9 && article.outline.every(n => n.resolves), "All 9 outline nodes must resolve");
  check(article.sourceDate === "2026-10-30", "Source card must identify actual v2 date");
  check(article.schema.length === 1 && article.schema[0].datePublished === "2026-11-02T16:22:54+09:00", "One schema and unchanged publication date required");
  check(Object.values(article.forbiddenAuxiliary).every(n => n === 0), "CF/SV/CTA/emotional hero must actually be absent from DOM");
  check(article.rawMarkupMatches.length + article.literalHtml.length + article.replacementCharacters === 0, "No leaked raw markup, PDF fragments, or replacement characters");
  check(article.images.every(i => i.naturalWidth > 0 && i.naturalHeight > 0), "All title/actual-paper images must load");
  check(article.images.some(i => /Paper Figure 3/.test(i.caption) && /CC BY 4.0/.test(i.caption) && /#S3.F3$/.test(i.originalLink)), "Actual paper figure needs explicit figure caption, license, credit and original paper link");
  check(article.images.some(i => /Original typography, not a paper figure/.test(i.caption)), "Title preview must be explicitly distinguished from paper figure");
  const viewports = [];
  const tocClicks = [];
  for (const width of [390, 1440]) {
    await page.setViewportSize({ width, height: 900 });
    await page.evaluate(() => scrollTo(0, 0));
    await page.waitForTimeout(300);
    const meter = await page.evaluate(() => ({
      viewport: innerWidth, documentWidth: document.documentElement.scrollWidth,
      overflowPx: Math.max(0, document.documentElement.scrollWidth - innerWidth),
      toc: [...document.querySelectorAll(innerWidth < 1200 ? "#toc-popup-content a" : "#toc a")].map(a => ({ text: a.textContent.trim(), href: a.getAttribute("href"), resolves: !!document.getElementById(decodeURIComponent(new URL(a.href).hash.slice(1))) })),
      articleFont: getComputedStyle(document.querySelector("article .content p")).fontSize,
      tables: [...document.querySelectorAll("article .content table")].map(t => ({ width: t.getBoundingClientRect().width, scrollWidth: t.parentElement.scrollWidth, clientWidth: t.parentElement.clientWidth, overflowX: getComputedStyle(t.parentElement).overflowX })),
      images: [...document.querySelectorAll(".reader-visuals img")].map(e => ({ src: e.getAttribute("src"), width: e.getBoundingClientRect().width, naturalWidth: e.naturalWidth, imageAspect: e.naturalWidth / e.naturalHeight, renderedAspect: e.getBoundingClientRect().width / e.getBoundingClientRect().height, objectFit: getComputedStyle(e).objectFit })),
      svgLabels: [...document.querySelectorAll(".rv-outline svg text")].map(e => ({ font: getComputedStyle(e).fontSize, scale: e.getScreenCTM()?.a }))
    }));
    viewports.push(meter);
    check(meter.overflowPx === 0, `${width}: horizontal page overflow`);
    check(meter.toc.length >= 9 && meter.toc.every(a => a.resolves), `${width}: broken or missing TOC targets`);
    check(meter.images.every(i => Math.abs(i.imageAspect - i.renderedAspect) < 0.02), `${width}: cropped or distorted title/figure image`);
    const scrollToHeading = async target => {
      await target.evaluate(e => scrollTo({ top: scrollY + e.getBoundingClientRect().top - 80, behavior: "instant" }));
      await page.waitForTimeout(100);
    };
    const intro = page.locator("article .content > h2").first();
    await scrollToHeading(intro);
    await page.screenshot({ path: `logs/2026-11-03/sureon-validation/after-${width}-intro.png` });
    for (const [label, name] of [["Method", "method"], ["Results", "results"], ["Limitations", "limits"], ["References", "references"]]) {
      const target = page.locator("article .content > h2").filter({ hasText: new RegExp(`^${label}$`) });
      await scrollToHeading(target);
      await page.screenshot({ path: `logs/2026-11-03/sureon-validation/after-${width}-${name}.png` });
    }
    await scrollToHeading(page.locator(".rv-gallery figure"));
    await page.screenshot({ path: `logs/2026-11-03/sureon-validation/after-${width}-figure.png` });
    if (width === 390) {
      for (const heading of expected) {
        await page.evaluate(() => scrollTo({ top: 0, behavior: "instant" }));
        await page.locator("#toc-solo-trigger").click();
        await page.locator("#toc-popup-content a").filter({ hasText: new RegExp(`^${heading}$`) }).click();
        await page.waitForTimeout(1400);
        const click = await page.evaluate(() => ({ hash: location.hash, targetTop: document.getElementById(decodeURIComponent(location.hash.slice(1)))?.getBoundingClientRect().top }));
        tocClicks.push({ heading, ...click });
        check(!!click.hash && click.targetTop >= 0 && click.targetTop < 300, `Mobile TOC failed to reach visible heading: ${heading}`);
      }
      const table = page.locator("article .content .table-wrapper").first();
      await table.scrollIntoViewIfNeeded();
      await table.focus();
      await page.keyboard.press("ArrowRight");
      await page.waitForTimeout(300);
      const keyboard = await table.evaluate(e => ({ focused: document.activeElement === e, scrollLeft: e.scrollLeft, scrollWidth: e.scrollWidth, clientWidth: e.clientWidth }));
      meter.tableKeyboard = keyboard;
      check(keyboard.focused, "Table wrapper must be keyboard focusable");
      if (keyboard.scrollWidth > keyboard.clientWidth) check(keyboard.scrollLeft > 0, "Wide table must scroll by keyboard");
    }
  }
  const table4 = article.tables[0];
  check(!!table4 && table4.cells.length === 4, "Expected Table 4 with header and three stage rows");
  if (table4) for (const value of ["176.6K", "76K", "22.4", "39.5", "48.2", "13.7", "22.7", "19.1", "8.7", "16.8", "29.1"]) check(table4.text.includes(value), `Table 4 missing ${value}`);
  await page.emulateMedia({ media: "print" });
  await page.setViewportSize({ width: 794, height: 1123 });
  await page.evaluate(() => scrollTo(0, 0));
  const print = await page.evaluate(() => ({
    headings: [...document.querySelectorAll("article .content > h2")].filter(e => getComputedStyle(e).display !== "none").map(e => e.innerText),
    imageCount: [...document.querySelectorAll(".reader-visuals img")].filter(e => getComputedStyle(e).display !== "none").length,
    outlineTextCount: document.querySelectorAll(".rv-outline .rv-node-list li").length,
    outlineSvgHidden: getComputedStyle(document.querySelector(".rv-outline svg")).display === "none",
    documentWidth: document.documentElement.scrollWidth, viewport: innerWidth,
    tableWidth: document.querySelector("article .content table")?.getBoundingClientRect().width,
    tableWrapperWidth: document.querySelector("article .content table")?.parentElement.clientWidth,
    tableWhiteSpace: getComputedStyle(document.querySelector("article .content th")).whiteSpace,
    tableCellBounds: [...document.querySelectorAll("article .content table tr:first-child th")].map(e => ({ text: e.innerText, left: e.getBoundingClientRect().left, right: e.getBoundingClientRect().right }))
  }));
  check(print.headings.length === 9 && print.outlineTextCount === 9, "Print must retain all nine sections and outline text");
  check(print.tableWidth <= print.tableWrapperWidth + 1 && print.tableWhiteSpace === "normal", "Printed table must wrap and fit without clipped columns");
  await page.screenshot({ path: "logs/2026-11-03/sureon-validation/after-print.png" });
  await page.pdf({ path: "logs/2026-11-03/sureon-validation/after-print.pdf", format: "A4", printBackground: true });
  await page.emulateMedia({ media: "screen" });
  check(pageErrors.length === 0, "Browser JavaScript errors");
  return { failures, article, viewports, tocClicks, print, pageErrors, consoleErrors };
}
