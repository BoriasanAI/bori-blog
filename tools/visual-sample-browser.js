async page => {
  const url = 'http://127.0.0.1:8774/bori-blog/posts/reimagining-memory-rnns-with-growing-cap-c4e46c/';
  await page.goto(url, { waitUntil: 'networkidle' });
  const checks = {};
  const failures = [];
  for (const width of [1440, 390, 375]) {
    await page.setViewportSize({ width, height: 1000 });
    await page.locator('.reader-visuals').scrollIntoViewIfNeeded();
    await page.locator('.reader-visuals img').evaluateAll(async images => {
      await Promise.all(images.map(image => image.decode()));
    });
    checks[width] = await page.evaluate(() => ({
      viewport: innerWidth, document: document.documentElement.scrollWidth,
      sourceCards: document.querySelectorAll('.rv-source').length,
      loadedImages: [...document.querySelectorAll('.reader-visuals img')].filter(image => image.naturalWidth > 0).length,
      previewLabel: document.querySelector('.rv-preview-label')?.textContent,
      authors: document.querySelector('.rv-authors')?.textContent,
      timelineDates: [...document.querySelectorAll('.rv-timeline time')].map(time => time.dateTime),
      outlineNodes: document.querySelectorAll('.rv-outline svg rect').length,
      svgLabels: [...document.querySelectorAll('.rv-outline svg g')].map(group => [...group.querySelectorAll('tspan')].map(span => span.textContent).join(' ')),
      inputLabels: [...document.querySelectorAll('.rv-outline .rv-node-list li > span')].map(node => node.textContent),
      outsideProse: !document.querySelector('article .content .reader-visuals'),
      credit: document.querySelector('.rv-credit')?.textContent
    }));
    const state = checks[width];
    if (state.document > width) failures.push(`${width}px document overflow`);
    if (state.sourceCards !== 1 || state.loadedImages !== 1 || !state.previewLabel?.includes('not a paper figure')) failures.push(`${width}px actual source preview missing`);
    if (state.timelineDates.length !== 0) failures.push(`${width}px stale timeline from an earlier sample`);
    if (JSON.stringify(state.svgLabels) !== JSON.stringify(state.inputLabels)) failures.push(`${width}px real heading words split or changed`);
    if (!state.outsideProse || !state.outlineNodes || !state.credit?.includes('CC-BY-4.0')) failures.push(`${width}px semantics or attribution`);
    const style = '#topbar-wrapper,#topbar,#toc-bar,#back-to-top,#toc-solo-trigger{visibility:hidden!important}';
    await page.locator('.reader-visuals').screenshot({ path: `logs/2026-11-02/visual-reader/sample-final-${width}.png`, style });
    await page.locator('.rv-outline').screenshot({ path: `logs/2026-11-02/visual-reader/sample-rnn-outline-${width}.png`, style });
  }
  const result = { checks, failures };
  await page.evaluate(result => {
    document.documentElement.dataset.sampleVisualResult = JSON.stringify(result);
  }, result);
  if (failures.length) throw new Error(JSON.stringify(result));
  return result;
}
