// Run with: playwright-cli -s=reader-republication run-code --filename=tools/reader-republication-check.js
// Override via process.env.READER_BASE_URL/READER_SCREENSHOT_DIR or window.readerRepublicationConfig.
async (page, supplied = {}) => {
  const env = typeof process === 'object' ? process.env : {};
  const injected = await page.evaluate(() => window.readerRepublicationConfig || {});
  const config = {
    base: env.READER_BASE_URL || 'http://127.0.0.1:8773/bori-blog',
    article: '/posts/2603-06570v2/',
    screenshotDir: env.READER_SCREENSHOT_DIR || 'logs/2026-11-03/reader-republication',
    widths: [390, 768, 1024, 1440],
    themes: ['light', 'dark'],
    surfaces: ['/', '/about/', '/dashboard/', '/categories/', '/tags/'],
    extraArticles: [],
    legacySvgArticle: '/posts/day-250-b9becc/',
    ...injected, ...supplied
  };
  config.base = config.base.replace(/\/$/, '');
  const failures = [];
  const measurements = [];
  const errors = [];
  const samples = new Set([config.legacySvgArticle, ...config.extraArticles].filter(Boolean));
  let assertions = 0;
  const check = (condition, message) => {
    assertions++;
    if (!condition) failures.push(message);
  };
  const onError = error => errors.push(error.message);
  page.on('pageerror', onError);
  const visit = async (path, theme) => {
    await page.emulateMedia({ colorScheme: theme, reducedMotion: 'reduce' });
    const response = await page.goto(`${config.base}${path}`, { waitUntil: 'load' });
    check(response?.ok(), `HTTP ${response?.status()}: ${path}`);
    await page.evaluate(async selected => {
      if (typeof Theme !== 'undefined') Theme.update(selected);
      else document.documentElement.setAttribute('data-bs-theme', selected);
      await document.fonts.ready;
      await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    }, theme);
  };
  const inspect = () => page.evaluate(() => {
    const visible = node => {
      const style = getComputedStyle(node);
      return style.visibility !== 'hidden' && style.display !== 'none' && node.getClientRects().length > 0;
    };
    const rgb = color => {
      const values = color.match(/[\d.]+/g)?.map(Number);
      return values && values.length >= 3 ? values : null;
    };
    const luminance = channels => channels.slice(0, 3).map(value => value / 255)
      .map(value => value <= .04045 ? value / 12.92 : ((value + .055) / 1.055) ** 2.4)
      .reduce((sum, value, index) => sum + value * [.2126, .7152, .0722][index], 0);
    const contrast = (foreground, background) => {
      const first = rgb(foreground), second = rgb(background);
      if (!first || !second) return null;
      const a = luminance(first), b = luminance(second);
      return (Math.max(a, b) + .05) / (Math.min(a, b) + .05);
    };
    const background = node => {
      for (let cursor = node; cursor; cursor = cursor.parentElement) {
        const color = getComputedStyle(cursor).backgroundColor;
        if (color && color !== 'transparent' && color !== 'rgba(0, 0, 0, 0)') return color;
      }
      return getComputedStyle(document.body).backgroundColor;
    };
    const labels = [...document.querySelectorAll('main svg text')].filter(visible).map(label => {
      const rect = label.closest('g')?.querySelector('rect') || label.closest('svg')?.querySelector('rect');
      const fill = rect ? getComputedStyle(rect).fill : background(label);
      return { text: label.textContent.trim().slice(0, 70), fill, ratio: contrast(getComputedStyle(label).fill, fill) };
    });
    const svgAlternatives = [...document.querySelectorAll('article .content svg')].filter(visible).map(svg => {
      const alternative = document.getElementById(svg.getAttribute('aria-describedby'));
      const labels = [...svg.querySelectorAll('text')].map(node => node.textContent.trim()).filter(Boolean);
      return {
        complete: alternative?.textContent === `Chart text: ${labels.join(' · ')}`,
        font: alternative && parseFloat(getComputedStyle(alternative).fontSize),
        visible: alternative && visible(alternative), viewBox: svg.getAttribute('viewBox')
      };
    });
    const prose = [...document.querySelectorAll('article .content > p')].find(node => visible(node) && node.textContent.trim());
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const hangul = [];
    while (walker.nextNode()) {
      const text = walker.currentNode;
      const owner = text.parentElement;
      if (!owner || owner.closest('script, style, [lang|="ko"]') || !visible(owner)) continue;
      const value = text.textContent.replace(/보리/g, '').trim();
      if (/[가-힣]/.test(value)) hangul.push(value.slice(0, 100));
    }
    const attributes = [...document.querySelectorAll('[aria-label], [title], [placeholder]')]
      .filter(node => visible(node) && !node.closest('[lang|="ko"]'))
      .flatMap(node => ['aria-label', 'title', 'placeholder'].map(name => node.getAttribute(name) || ''))
      .filter(value => /[가-힣]/.test(value.replace(/보리/g, '')));
    const tables = [...document.querySelectorAll('article .content .table-wrapper')].map(wrapper => ({
      overflow: wrapper.scrollWidth > wrapper.clientWidth + 1,
      hint: wrapper.previousElementSibling?.classList.contains('table-scroll-hint') &&
        visible(wrapper.previousElementSibling),
      caption: Boolean(wrapper.querySelector('caption')?.textContent.trim()),
      columns: [...wrapper.querySelectorAll('thead th')].every(cell => cell.scope === 'col'),
      rows: [...wrapper.querySelectorAll('tbody tr')].every(row => row.firstElementChild?.matches('th[scope="row"]')),
      keyboard: wrapper.tabIndex === 0 && wrapper.getAttribute('role') === 'region'
    }));
    const body = getComputedStyle(document.body);
    const topbar = document.querySelector('#topbar');
    return {
      width: innerWidth, documentWidth: document.documentElement.scrollWidth,
      palette: { background: body.backgroundColor, text: body.color, main: body.getPropertyValue('--main-bg').trim() },
      topbarBackground: topbar && getComputedStyle(topbar).backgroundColor,
      firstProse: prose && Math.round(prose.getBoundingClientRect().top + scrollY),
      upfront: Boolean(document.querySelector('article .reader-visuals')?.compareDocumentPosition(document.querySelector('article .content')) & Node.DOCUMENT_POSITION_FOLLOWING),
      avatarHero: [...document.querySelectorAll('article header img, article .preview-img img')].some(image => /\/assets\/img\/avatar\//.test(image.src)),
      outlineSvgs: document.querySelectorAll('.rv-outline svg').length,
      outlines: document.querySelectorAll('.rv-outline').length,
      fakePreviews: document.querySelectorAll('.rv-preview-label, .rv-image img[src*="visual-reference-"]').length,
      giscus: document.querySelectorAll('script[src*="giscus.app"], iframe.giscus-frame, .giscus').length,
      unavailable: Boolean(document.querySelector('.comments-unavailable')?.textContent.includes('unavailable')),
      discussions: document.querySelector('.comments-unavailable a')?.href,
      labels, svgAlternatives, tables, hangul: [...new Set([...hangul, ...attributes])],
      figureCount: document.querySelectorAll('article .rv-original').length
    };
  });
  try {
    for (const width of config.widths) {
      for (const theme of config.themes) {
        await page.setViewportSize({ width, height: 900 });
        await visit(config.article, theme);
        const state = await inspect();
        const label = `${width}/${theme}`;
        check(state.documentWidth <= width + 1, `${label}: document overflow ${state.documentWidth}`);
        check(Boolean(state.palette.main), `${label}: compiled main palette is missing`);
        check(state.topbarBackground && !['transparent', 'rgba(0, 0, 0, 0)'].includes(state.topbarBackground), `${label}: transparent topbar`);
        check(!state.avatarHero, `${label}: generic avatar article hero`);
        check(!state.upfront, `${label}: companion appears before prose`);
        check(state.outlineSvgs === 0 && state.outlines <= 1, `${label}: duplicate visual outline`);
        check(state.fakePreviews === 0, `${label}: typographic fake source previews`);
        check(state.hangul.length === 0, `${label}: untagged Korean UI: ${state.hangul.join('; ')}`);
        check(state.giscus === 0 && state.unavailable, `${label}: unavailable comments must not load giscus`);
        check(state.discussions === 'https://github.com/BoriasanAI/bori-blog/discussions', `${label}: missing verified Discussions destination`);
        if (width === 390) check(state.firstProse > 0 && state.firstProse <= 1000, `${label}: first prose at ${state.firstProse}px`);
        state.labels.forEach(item => check(item.ratio !== null && item.ratio >= 4.5, `${label}: SVG label contrast ${item.ratio?.toFixed(2)}: ${item.text}`));
        state.tables.forEach((table, index) => {
          check(table.caption && table.columns && table.rows && table.keyboard, `${label}: table ${index} caption/scopes/keyboard`);
          check(table.overflow === Boolean(table.hint), `${label}: table ${index} hint does not match overflow`);
        });
        check(state.figureCount > 0, `${label}: missing original figure link`);
        if (state.figureCount) {
          const figure = page.locator('article .rv-original').first();
          await figure.focus();
          await page.keyboard.press('Enter');
          await page.locator('dialog[open]').waitFor();
          check(await page.locator('dialog[open] .rv-zoom-scroll img').evaluate(image =>
            image.width === Number(image.getAttribute('width')) && image.height > 0), `${label}: zoom must show intrinsic size, not a second fit-to-width preview`);
          check(await page.locator('dialog[open] button').evaluate(button => {
            const rect = button.getBoundingClientRect();
            return rect.top >= 0 && rect.bottom <= innerHeight;
          }), `${label}: zoom close control must remain in the viewport`);
          const viewport = page.locator('dialog[open] .rv-zoom-scroll');
          if (width === 390) await page.screenshot({ path: `${config.screenshotDir}/zoom-${width}-${theme}.png` });
          await viewport.focus();
          if (await viewport.evaluate(node => node.scrollWidth > node.clientWidth)) {
            await page.keyboard.press('ArrowRight');
            await page.waitForTimeout(150);
            check(await viewport.evaluate(node => node.scrollLeft > 0), `${label}: keyboard scroll must reveal full-resolution details`);
          }
          await page.keyboard.press('Escape');
          check(await page.locator('dialog[open]').count() === 0 && await figure.evaluate(node => node === document.activeElement), `${label}: Escape must close zoom and restore focus`);
        }
        await page.evaluate(() => scrollTo(0, 0));
        await page.screenshot({ path: `${config.screenshotDir}/article-${width}-${theme}.png`, fullPage: true });
        if (width === 390) await page.screenshot({ path: `${config.screenshotDir}/article-${width}-${theme}-first-screen.png` });
        measurements.push({ path: config.article, theme, ...state });
      }
    }
    const light = measurements.find(row => row.theme === 'light')?.palette;
    const dark = measurements.find(row => row.theme === 'dark')?.palette;
    check(Boolean(light && dark && light.background !== dark.background && light.text !== dark.text), 'Both themes must render distinct real palettes, not just switch an attribute');
    for (const path of config.surfaces) {
      for (const theme of config.themes) {
        await page.setViewportSize({ width: 390, height: 900 });
        await visit(path, theme);
        const state = await inspect();
        if (path === '/' && samples.size < 2) {
          const links = await page.locator('.start-grid h3 a').evaluateAll(nodes => nodes.map(node => new URL(node.href).pathname));
          links.filter(link => link !== new URL(`${config.base}${config.article}`).pathname)
            .slice(0, 2 - samples.size).forEach(link => {
              const prefix = new URL(config.base).pathname.replace(/\/$/, '');
              samples.add(prefix && link.startsWith(`${prefix}/`) ? link.slice(prefix.length) : link);
            });
        }
        check(state.documentWidth <= 391, `${path}/${theme}: document overflow`);
        check(state.hangul.length === 0, `${path}/${theme}: untagged Korean UI: ${state.hangul.join('; ')}`);
        await page.screenshot({ path: `${config.screenshotDir}/${path.replaceAll('/', '') || 'home'}-390-${theme}.png`, fullPage: true });
        measurements.push({ path, theme, width: state.width, documentWidth: state.documentWidth, hangul: state.hangul });
      }
    }
    let svgLabelsChecked = measurements.reduce((total, row) => total + (row.labels?.length || 0), 0);
    for (const path of samples) {
      for (const width of config.widths) {
        for (const theme of config.themes) {
          await page.setViewportSize({ width, height: 900 });
          await visit(path, theme);
          const state = await inspect();
          check(state.documentWidth <= width + 1 && !state.avatarHero, `${path}/${width}/${theme}: ordinary article overflow or generic hero`);
          state.labels.forEach(item => check(item.ratio !== null && item.ratio >= 4.5, `${path}/${width}/${theme}: SVG label contrast ${item.ratio?.toFixed(2)}: ${item.text}`));
          state.svgAlternatives.forEach(alternative => {
            check(alternative.complete && alternative.visible && alternative.font >= 16, `${path}/${width}/${theme}: all original SVG labels and values need a readable textual alternative`);
            if (path === config.legacySvgArticle) check(alternative.viewBox === '0 0 500 152', `${path}/${width}/${theme}: original SVG coordinates must remain unchanged`);
          });
          svgLabelsChecked += state.labels.length;
          measurements.push({ path, theme, width, documentWidth: state.documentWidth, labels: state.labels, svgAlternatives: state.svgAlternatives });
          if (state.labels.length && width === 390) await page.screenshot({ path: `${config.screenshotDir}/svg-${path.split('/').filter(Boolean).pop()}-${width}-${theme}.png`, fullPage: true });
        }
      }
    }
    await page.setViewportSize({ width: 390, height: 900 });
    await visit(config.article, 'light');
    await page.emulateMedia({ media: 'print', reducedMotion: 'reduce' });
    check(await page.locator('article .content .table-wrapper').evaluateAll(nodes =>
      nodes.every(node => getComputedStyle(node).overflowX === 'visible')), 'Print must not clip table columns in a scroll wrapper');
    check(await page.locator('.table-scroll-hint').evaluateAll(nodes =>
      nodes.every(node => getComputedStyle(node).display === 'none')), 'Print must omit interactive scroll instructions');
    await page.screenshot({ path: `${config.screenshotDir}/article-print.png`, fullPage: true });
    await page.emulateMedia({ media: 'screen' });
    const plainContext = await page.context().browser().newContext({
      javaScriptEnabled: false, viewport: { width: 390, height: 900 }, colorScheme: 'light'
    });
    try {
      const plain = await plainContext.newPage();
      await plain.goto(`${config.base}${config.article}`, { waitUntil: 'load' });
      const original = plain.locator('article .rv-original').first();
      const href = await original.getAttribute('href');
      check(Boolean(href) && await original.locator('img').getAttribute('src') === href, 'No-JS figure must retain a native original-image link');
      await original.click();
      await plain.waitForURL(url => url.pathname.includes('/assets/'));
      check(plain.url() === new URL(href, config.base).href, 'No-JS native link must actually open the original image');
    } finally {
      await plainContext.close();
    }
    check(errors.length === 0, `Browser runtime errors: ${errors.join('; ')}`);
    const report = { passed: failures.length === 0, assertions, svgLabelsChecked, failures, errors, measurements };
    console.log(JSON.stringify(report));
    if (failures.length) throw new Error(`Reader republication: ${failures.length} failure(s): ${failures.join(' | ')}`);
    return report;
  } finally {
    page.off('pageerror', onError);
  }
}
