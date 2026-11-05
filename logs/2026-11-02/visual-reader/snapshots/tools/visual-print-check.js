async page => {
  await page.goto('http://127.0.0.1:8774/bori-blog/posts/reimagining-memory-rnns-with-growing-cap-c4e46c/', { waitUntil: 'networkidle' });
  await page.evaluate(async () => {
    await Promise.all((await navigator.serviceWorker.getRegistrations()).map(registration => registration.unregister()));
    await Promise.all((await caches.keys()).map(key => caches.delete(key)));
  });
  await page.reload({ waitUntil: 'networkidle' });
  await page.setViewportSize({ width: 390, height: 1000 });
  await page.evaluate(() => { document.documentElement.dataset.bsTheme = 'dark'; });
  await page.emulateMedia({ media: 'print', reducedMotion: 'reduce' });
  const result = await page.locator('.reader-visuals').evaluate(panel => ({
    headingColors: [...panel.querySelectorAll('h2,h3')].map(heading => getComputedStyle(heading).color),
    cardBackground: getComputedStyle(panel.querySelector('.rv-source')).backgroundColor,
    creditColor: getComputedStyle(panel.querySelector('.rv-credit')).color,
    duplicateSvgShapesHidden: [...panel.querySelectorAll('.rv-outline svg')].every(svg => getComputedStyle(svg).display === 'none'),
    textualNodes: panel.querySelectorAll('.rv-node-list li').length
  }));
  await page.locator('.reader-visuals').screenshot({
    path: 'logs/2026-11-02/visual-reader/paper-print.png',
    style: '#topbar-wrapper,#topbar,#toc-bar,#back-to-top,#toc-solo-trigger{visibility:hidden!important}'
  });
  await page.emulateMedia({ media: 'screen', reducedMotion: 'no-preference' });
  if (!result.headingColors.every(color => color === 'rgb(17, 17, 17)') ||
      result.cardBackground !== 'rgb(255, 255, 255)' || result.creditColor !== 'rgb(51, 51, 51)' ||
      !result.duplicateSvgShapesHidden || result.textualNodes !== 6) {
    throw new Error(JSON.stringify(result));
  }
  return result;
}
