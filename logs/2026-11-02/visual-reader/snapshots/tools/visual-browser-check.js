async page => {
  const origin = 'http://127.0.0.1:8774';
  const base = `${origin}/bori-blog`;
  const coverage = await (await page.request.get(`${origin}/visual-coverage.json`)).json();
  const failures = [];
  const errors = [];
  const measurements = [];
  const screenshots = [];
  const check = (condition, message) => { if (!condition) failures.push(message); };
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(`${base}/`, { waitUntil: 'networkidle' });
  await page.evaluate(async () => {
    await Promise.all((await navigator.serviceWorker.getRegistrations()).map(registration => registration.unregister()));
    await Promise.all((await caches.keys()).map(key => caches.delete(key)));
  });
  const representative = [
    ['paper-outline', coverage.posts.find(post => post.path.includes('/reimagining-memory-'))],
    ['paper-timeline', coverage.posts.find(post => post.style === 'paper' && post.diagrams.includes('timeline'))],
    ['source-only', coverage.posts.find(post => post.sources && post.diagrams.length === 0)],
    ['evidence-map', coverage.posts.find(post => post.style === 'essay' && post.diagrams.includes('evidence-map') && !post.diagrams.includes('comparison'))],
    ['comparison', coverage.posts.find(post => post.diagrams.includes('comparison'))],
    ['journal', coverage.posts.find(post => post.style === 'journal')]
  ];
  check(representative.every(([, post]) => post), 'All six real showcase compositions must exist');
  const screenshotStyle = '#topbar-wrapper,#topbar,#toc-bar,#back-to-top,#toc-solo-trigger{visibility:hidden!important}';
  for (const width of [375, 390, 1440]) {
    await page.setViewportSize({ width, height: 1000 });
    for (const post of coverage.posts) {
      await page.goto(`${origin}${post.path}`, { waitUntil: 'networkidle' });
      await page.locator('.reader-visuals').scrollIntoViewIfNeeded();
      await page.locator('.reader-visuals img').evaluateAll(async images => {
        await Promise.all(images.map(image => image.decode()));
      });
      const state = await page.locator('.reader-visuals').evaluate(panel => {
        const badSvgText = [];
        panel.querySelectorAll('svg g').forEach(group => {
          const rect = group.querySelector('rect')?.getBBox();
          if (!rect) return;
          group.querySelectorAll('tspan').forEach(span => {
            const box = span.getBBox();
            if (box.x < rect.x || box.x + box.width > rect.x + rect.width + 1 ||
                box.y < rect.y || box.y + box.height > rect.y + rect.height + 1) {
              badSvgText.push(span.textContent);
            }
          });
        });
        return {
          viewport: innerWidth, document: document.documentElement.scrollWidth,
          panelWidth: panel.getBoundingClientRect().width,
          sources: panel.querySelectorAll('.rv-source').length,
          diagrams: panel.querySelectorAll('.rv-diagram').length,
          images: [...panel.querySelectorAll('img')].map(image => ({
            loaded: image.complete && image.naturalWidth > 0,
            alt: image.alt, width: image.width, height: image.height
          })),
          smallTargets: [...panel.querySelectorAll('a')].filter(link => link.getBoundingClientRect().height < 44).map(link => link.textContent),
          brokenHeadingTargets: [...panel.querySelectorAll('.rv-outline a')].filter(link => {
            const destination = new URL(link.href);
            return destination.pathname === location.pathname && !document.getElementById(decodeURIComponent(destination.hash.slice(1)));
          }).map(link => link.href),
          badSvgText,
          captionFonts: [...panel.querySelectorAll('.rv-credit,.rv-preview-label')].map(node => parseFloat(getComputedStyle(node).fontSize)),
          comparisonScroll: panel.querySelector('.rv-table-scroll') ? {
            viewport: panel.querySelector('.rv-table-scroll').clientWidth,
            content: panel.querySelector('.rv-table-scroll').scrollWidth
          } : null,
          outsideProse: !document.querySelector('.content .reader-visuals')
        };
      });
      measurements.push({ path: post.path, width, ...state });
      check(state.document <= width && state.panelWidth <= width, `${width}px overflow: ${post.path}`);
      check(state.sources === post.sources && state.diagrams === post.diagrams.length, `${width}px actual metadata coverage: ${post.path}`);
      check(state.images.every(image => image.loaded && image.alt && image.width && image.height), `${width}px loaded local images: ${post.path}`);
      check(!state.badSvgText.length, `${width}px SVG text outside node: ${post.path}: ${state.badSvgText.join(' | ')}`);
      check(!state.smallTargets.length, `${width}px touch targets: ${post.path}: ${state.smallTargets.join(' | ')}`);
      check(!state.brokenHeadingTargets.length && state.outsideProse, `${width}px prose/navigation isolation: ${post.path}`);
      check(state.captionFonts.every(size => size >= 14), `${width}px attribution readability: ${post.path}`);
      const match = representative.find(([, candidate]) => candidate?.path === post.path);
      if (match && width !== 390) {
        const path = `logs/2026-11-02/visual-reader/${match[0]}-${width}.png`;
        await page.locator('.reader-visuals').screenshot({ path, animations: 'disabled', style: screenshotStyle });
        screenshots.push(path);
      }
    }
  }
  const paper = representative[0][1];
  const comparison = representative.find(([name]) => name === 'comparison')[1];
  await page.setViewportSize({ width: 375, height: 1000 });
  await page.goto(`${origin}${comparison.path}`, { waitUntil: 'networkidle' });
  const comparisonRegion = page.locator('.rv-table-scroll');
  await comparisonRegion.focus();
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowRight');
  await page.waitForTimeout(200);
  const comparisonKeyboardScroll = await comparisonRegion.evaluate(region => ({
    offset: region.scrollLeft, viewport: region.clientWidth, content: region.scrollWidth,
    hintVisible: getComputedStyle(document.querySelector('.rv-scroll-hint')).display !== 'none'
  }));
  check(comparisonKeyboardScroll.offset > 0 && comparisonKeyboardScroll.hintVisible, 'Mobile table has a visible cue and actually scrolls by keyboard');
  await page.locator('.rv-comparison').screenshot({ path: 'logs/2026-11-02/visual-reader/comparison-scroll-375.png', style: screenshotStyle });
  screenshots.push('logs/2026-11-02/visual-reader/comparison-scroll-375.png');
  await page.goto(`${origin}${paper.path}`, { waitUntil: 'networkidle' });
  await page.setViewportSize({ width: 390, height: 1000 });
  await page.locator('.rv-outline').screenshot({
    path: 'logs/2026-11-02/visual-reader/real-headings-390.png', style: screenshotStyle
  });
  screenshots.push('logs/2026-11-02/visual-reader/real-headings-390.png');
  const firstLink = page.locator('.reader-visuals a').first();
  await firstLink.focus();
  const focus = await firstLink.evaluate(link => ({
    focused: document.activeElement === link,
    outline: getComputedStyle(link).outlineStyle,
    outlineWidth: getComputedStyle(link).outlineWidth
  }));
  check(focus.focused && focus.outline !== 'none' && parseFloat(focus.outlineWidth) >= 3, 'Visible keyboard focus');
  await page.keyboard.press('Tab');
  check(await page.evaluate(() => !!document.activeElement?.closest('.reader-visuals')), 'Keyboard moves through actual companion links');
  const contrasts = {};
  for (const theme of ['light', 'dark']) {
    await page.evaluate(theme => { document.documentElement.dataset.bsTheme = theme; }, theme);
    contrasts[theme] = await page.locator('.reader-visuals').evaluate(panel => {
      const rgba = color => (color.match(/[\d.]+/g) || []).map(Number);
      const background = node => {
        const color = rgba(getComputedStyle(node).backgroundColor);
        if (color.length === 3 || color[3] === 1) return color.slice(0, 3);
        return node.parentElement ? background(node.parentElement) : [255, 255, 255];
      };
      const luminance = color => color.map(value => {
        const s = value / 255;
        return s <= .04045 ? s / 12.92 : ((s + .055) / 1.055) ** 2.4;
      }).reduce((sum, value, index) => sum + value * [.2126, .7152, .0722][index], 0);
      return [...panel.querySelectorAll('.rv-host,.rv-kind,.rv-credit,.rv-preview-label,.rv-source h3 a,.rv-node-list a')].map(node => {
        const foreground = luminance(rgba(getComputedStyle(node).color).slice(0, 3));
        const backdrop = luminance(background(node));
        return { text: node.textContent.slice(0, 65), ratio: (Math.max(foreground, backdrop) + .05) / (Math.min(foreground, backdrop) + .05) };
      });
    });
    check(contrasts[theme].every(item => item.ratio >= 4.5), `${theme} text contrast >= 4.5:1`);
    if (theme === 'dark') {
      await page.locator('.reader-visuals').screenshot({ path: 'logs/2026-11-02/visual-reader/paper-dark-390.png', style: screenshotStyle });
      screenshots.push('logs/2026-11-02/visual-reader/paper-dark-390.png');
    }
  }
  await page.emulateMedia({ reducedMotion: 'reduce', media: 'print' });
  const print = await page.locator('.reader-visuals').evaluate(panel => ({
    svgHidden: [...panel.querySelectorAll('.rv-outline svg,.rv-evidence-map svg')].every(svg => getComputedStyle(svg).display === 'none'),
    textualNodes: panel.querySelectorAll('.rv-node-list li').length,
    color: getComputedStyle(panel).color,
    cardBackground: getComputedStyle(panel.querySelector('.rv-source')).backgroundColor,
    creditColor: getComputedStyle(panel.querySelector('.rv-credit')).color,
    headingColors: [...panel.querySelectorAll('h2,h3')].map(heading => getComputedStyle(heading).color),
    animation: getComputedStyle(panel).animationName,
    transition: getComputedStyle(panel).transitionDuration
  }));
  check(print.svgHidden && print.textualNodes > 0, 'Print keeps text without duplicate diagram shapes');
  check(print.cardBackground === 'rgb(255, 255, 255)', 'Print from dark mode uses a white card background');
  check(print.creditColor === 'rgb(51, 51, 51)', 'Print attribution remains legible from dark mode');
  check(print.headingColors.every(color => color === 'rgb(17, 17, 17)'), 'Print headings do not inherit pale dark-theme colors');
  check(print.animation === 'none' && print.transition === '0s', 'Reduced motion disables companion animation');
  await page.locator('.reader-visuals').screenshot({ path: 'logs/2026-11-02/visual-reader/paper-print.png', style: screenshotStyle });
  screenshots.push('logs/2026-11-02/visual-reader/paper-print.png');
  await page.emulateMedia({ media: 'screen', reducedMotion: 'no-preference' });
  await page.evaluate(() => { document.documentElement.dataset.bsTheme = 'light'; });
  await page.evaluate(async () => {
    await Promise.all((await navigator.serviceWorker.getRegistrations()).map(registration => registration.unregister()));
    await Promise.all((await caches.keys()).map(key => caches.delete(key)));
  });
  await page.route('**/assets/img/posts/visual-reference-*.svg', route => route.fulfill({ status: 404, body: 'Deliberately missing test preview' }));
  await page.goto(`${origin}${paper.path}`, { waitUntil: 'networkidle' });
  await page.locator('.reader-visuals').scrollIntoViewIfNeeded();
  await page.waitForFunction(() => !!document.querySelector('.rv-image-error'));
  const imageError = await page.locator('.reader-visuals').evaluate(panel => ({
    notices: panel.querySelectorAll('.rv-image-error').length,
    hiddenImages: [...panel.querySelectorAll('.rv-image img')].every(image => image.hidden),
    sourceLinks: panel.querySelectorAll('.rv-source h3 a[href^="https://"]').length,
    attribution: panel.querySelector('.rv-credit')?.textContent,
    status: panel.querySelector('.rv-image-error')?.getAttribute('role')
  }));
  check(imageError.notices === 1 && imageError.hiddenImages && imageError.sourceLinks === 1 && imageError.status === 'status', 'Honest runtime 404 notice preserves actual source and credit');
  await page.locator('.reader-visuals').screenshot({ path: 'logs/2026-11-02/visual-reader/image-error-390.png', style: screenshotStyle });
  screenshots.push('logs/2026-11-02/visual-reader/image-error-390.png');
  await page.unroute('**/assets/img/posts/visual-reference-*.svg');
  await page.goto(`${origin}${paper.path}`, { waitUntil: 'networkidle' });
  await page.locator('.reader-visuals img').evaluate(image => image.decode());
  check(await page.locator('.rv-image-error').count() === 0, 'A successful reload restores the real image without stale error state');
  const pwa = await page.evaluate(async () => ({
    serviceWorkerSupported: 'serviceWorker' in navigator,
    registrations: (await navigator.serviceWorker.getRegistrations()).map(registration => ({ scope: registration.scope, active: !!registration.active })),
    panels: document.querySelectorAll('.reader-visuals').length,
    css: document.querySelectorAll('link[href$="/reader-visuals.css"]').length,
    js: document.querySelectorAll('script[src$="/reader-visuals.js"]').length,
    errors: document.querySelectorAll('.rv-image-error').length
  }));
  check(pwa.panels === 1 && pwa.css === 1 && pwa.js === 1 && !pwa.errors, 'PWA/reload recurrence does not duplicate companion assets or state');
  check(errors.length === 0, 'No runtime page errors');
  const result = { enrichedPosts: coverage.enriched_posts, viewports: [375, 390, 1440], measurements, screenshots, comparisonKeyboardScroll, focus, contrasts, print, imageError, pwa, errors, failures };
  if (failures.length) throw new Error(JSON.stringify(result));
  return result;
}
