async page => {
  const base = 'http://127.0.0.1:8774/bori-blog';
  const failures = [];
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const check = (condition, message) => { if (!condition) failures.push(message); };
  const width = () => page.evaluate(() => ({
    viewport: innerWidth, document: document.documentElement.scrollWidth
  }));
  await page.goto(`${base}/`);
  await page.evaluate(async () => {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map(registration => registration.unregister()));
    await Promise.all((await caches.keys()).map(key => caches.delete(key)));
  });
  errors.length = 0;
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(`${base}/`, { waitUntil: 'networkidle' });
  const home = await width();
  check(home.document === 390, 'Home must not overflow at 390px');
  const startTypes = await page.locator('.start-grid article').count();
  check(startTypes > 0, 'Starting points must exist for actual available content types');
  check(await page.locator('#post-list article').count() === 10, 'Ten home cards');
  await page.locator('#search-trigger').click();
  await page.locator('#search-input').fill('query_compiler.py');
  await page.waitForTimeout(500);
  const searchCount = await page.locator('#search-results article').count();
  check(searchCount > 0, 'Search must match actual body text');
  await page.locator('#search-input').fill('qzxv-no-such-post-923875');
  await page.waitForTimeout(300);
  check((await page.locator('#search-results').textContent()).includes('No matching posts'), 'Honest no-results state');
  await page.goto(`${base}/dashboard/`, { waitUntil: 'networkidle' });
  const dashboard = await width();
  await page.screenshot({ path: 'logs/2026-11-02/visual-reader/regression/dashboard-mobile.png' });
  check(await page.locator('.dashboard-card').count() === startTypes, 'Starting points and dashboard must use the same real content types');
  const table = await page.locator('#dashboard-table').evaluate(table => ({
    rows: table.querySelectorAll('tbody tr').length,
    scrollWidth: table.parentElement.scrollWidth,
    width: table.parentElement.clientWidth,
    keyboard: table.parentElement.tabIndex
  }));
  check(dashboard.document === 390, 'Dashboard must not overflow at 390px');
  check(table.rows === 30 && table.scrollWidth > table.width && table.keyboard === 0, '30-row table needs real keyboard scrolling');
  await page.selectOption('#dashboard-kind', 'paper-review');
  const filtered = await page.locator('#dashboard-table tbody tr:visible').count();
  check(filtered < table.rows, 'Subtype filter must affect actual rows');
  await page.locator('#dashboard-query').fill('qzxv-no-such-post-923875');
  check(await page.locator('#dashboard-table tbody tr:visible').count() === 0, 'Title filter must combine with subtype filter');
  await page.goto(`${base}/posts/day-250-b9becc/`, { waitUntil: 'networkidle' });
  const post = await width();
  const lead = await page.locator('article .post-desc').textContent();
  const bodyText = await page.locator('article .content').textContent();
  check(bodyText.includes('query_compiler.py') && bodyText.includes('if a: if b:') && bodyText.includes('if a and b:'), 'Meaningful inline code must survive rendering');
  const homeSummary = await page.evaluate(() => JSON.parse(document.querySelector('script[type="application/ld+json"]').textContent).description);
  check(['query_compiler.py', 'if a: if b:', 'if a and b:'].every(token => homeSummary.includes(token) && lead.includes(token)), 'Visible description and metadata must preserve the complete code sentence');
  await page.screenshot({ path: 'logs/2026-11-02/visual-reader/regression/sample-mobile.png' });
  const chart = await page.locator('article .content svg').first().evaluate(svg => ({
    width: svg.getBoundingClientRect().width,
    name: svg.getAttribute('aria-labelledby'),
    alternative: svg.getAttribute('aria-describedby'),
    font: getComputedStyle(svg.querySelector('text')).fontSize,
    effectiveFont: parseFloat(getComputedStyle(svg.querySelector('text')).fontSize) * svg.getScreenCTM().a
  }));
  check(post.document === 390 && chart.width <= 390, 'Post and SVG must not overflow');
  check(chart.name && chart.alternative && chart.effectiveFont >= 12, 'Chart needs accessible naming and readable text');
  const touches = await page.locator('#sidebar-trigger,#search-trigger,#back-to-top,#toc-solo-trigger,#mode-toggle').evaluateAll(nodes =>
    nodes.map(node => ({ id: node.id, width: node.getBoundingClientRect().width, height: node.getBoundingClientRect().height, name: node.getAttribute('aria-label') }))
  );
  check(touches.every(node => node.width >= 44 && node.height >= 44 && node.name), 'Main icon targets must be named and at least 44px');
  check(await page.locator('.comments-unavailable').count() === 1, 'Unavailable comments must not look successful');
  await page.locator('article .content svg').first().scrollIntoViewIfNeeded();
  await page.screenshot({ path: 'logs/2026-11-02/visual-reader/regression/chart-mobile.png' });
  await page.goto(`${base}/posts/day-0-c5261d/`, { waitUntil: 'networkidle' });
  const missingTocTargets = await page.locator('a.toc-link').evaluateAll(links => links.filter(link => {
    const href = link.getAttribute('href');
    return !href || href === '#' || !document.getElementById(decodeURIComponent(href.slice(1)));
  }).map(link => link.textContent));
  check(missingTocTargets.length === 0, 'Changed-body table of contents must have real heading targets');
  await page.screenshot({ path: 'logs/2026-11-02/visual-reader/regression/structural-post-mobile.png' });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(`${base}/`, { waitUntil: 'networkidle' });
  await page.selectOption('#theme-choice', 'dark');
  await page.waitForTimeout(200);
  check(await page.evaluate(() => document.documentElement.dataset.bsTheme === 'dark'), 'Explicit dark choice');
  await page.selectOption('#theme-choice', 'light');
  await page.waitForTimeout(200);
  check(await page.evaluate(() => document.documentElement.dataset.bsTheme === 'light'), 'Explicit light choice');
  await page.selectOption('#theme-choice', 'system');
  check(await page.evaluate(() => localStorage.getItem('theme') === null), 'System choice must clear persisted override');
  await page.screenshot({ path: 'logs/2026-11-02/visual-reader/regression/home-desktop.png' });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: 'logs/2026-11-02/visual-reader/regression/home-mobile.png' });
  check(errors.length === 0, 'No runtime page errors');
  const result = { home, dashboard, table, post, chart, searchCount, startTypes, touches, lead, homeSummary, errors, failures };
  console.log(JSON.stringify(result, null, 2));
  if (failures.length) throw new Error(failures.join('; '));
  return result;
}
