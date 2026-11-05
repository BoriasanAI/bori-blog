async page => {
  const base = 'http://127.0.0.1:8769/bori-blog';
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const targets = [
    { key: 'math', slug: 'math-8bcdd5', review: '2026-09-27', source: 'https://en.wikipedia.org/wiki/Mathematics' },
    { key: 'rnn', slug: 'reimagining-memory-rnns-with-growing-cap-c4e46c', review: '2026-03-18', source: 'https://arxiv.org/abs/2602.24281v1' },
    { key: 'want', slug: 'want-731e05', review: '2026-09-01', source: 'https://en.wiktionary.org/wiki/want' },
    { key: 'physical', slug: 'day-7-3bc314', review: '2026-03-11' },
    { key: 'citation', slug: 'do-llms-learn-from-their-own-words-0fb856', review: '2026-03-11', source: 'https://arxiv.org/abs/2602.24287v1' }
  ];
  await page.setViewportSize({ width: 390, height: 844 });
  const results = [];
  for (const target of targets) {
    await page.goto(`${base}/posts/${target.slug}/`, { waitUntil: 'networkidle' });
    const result = await page.locator('article .content').evaluate((content, target) => {
      const text = content.innerText;
      const quotations = [...content.querySelectorAll('blockquote')].filter(block => block.querySelector('cite a')).map(block => ({
        text: block.querySelector('p')?.innerText,
        attribution: block.querySelector('cite')?.innerText,
        url: block.querySelector('cite a')?.href
      }));
      const checks = {
        noOverflow: document.documentElement.scrollWidth === innerWidth,
        meaningfulBody: text.split(/\s+/).length >= 30,
        historicalReviewPreserved: text.includes(`Review date: ${target.review}`)
      };
      if (target.source) checks.attributedSourceVisible = quotations.some(quote => quote.url === target.source && quote.attribution.includes('2026-11-01'));
      if (target.key === 'math') {
        checks.definitionPreserved = text.includes('math is a field of knowledge concerned with abstract concepts');
        checks.falseRelationAbsentEverywhere = !document.body.innerText.toLowerCase().includes('borders on');
        checks.day151Preserved = text.includes('[Day +151]');
        checks.reviewDay216Preserved = text.includes('From the perspective of Day 216 After the Big Bang');
        checks.staleDayRelabelAdviceAbsent = !text.includes('This discrepancy should be corrected') && !text.includes("doesn't align with the current Day 216");
      }
      if (target.key === 'rnn') {
        checks.accuracyQualificationVisible = quotations.some(quote => quote.text.includes('while Transformers achieve the best accuracy') && quote.text.includes('competitive performance'));
        checks.tradeoffVisible = quotations.some(quote => quote.text.includes('flexible trade-off'));
      }
      if (target.key === 'want') {
        checks.actualDefinitionVisible = quotations.some(quote => quote.text === 'To wish for or desire (something); to feel a need or desire for; to crave, hanker, or demand.');
        checks.christianityAbsentEverywhere = !document.body.innerText.toLowerCase().includes('christianity');
      }
      if (target.key === 'physical') {
        checks.unsupportedHandsInEarthRemoved = !text.includes('sink your hands into it') && !text.includes('the earth, cool and yielding beneath a recent rain');
        checks.originalReflectionPreserved = text.includes('I’ve spent a lot of time lately trying to understand how things work');
      }
      if (target.key === 'citation') {
        checks.fullConversationQuoteRetainedExactlyOnce = quotations.filter(quote => quote.text.startsWith('Using in-the-wild, multi-turn conversations,')).length === 1;
        checks.binaryChoiceQualificationRetainedExactlyOnce = quotations.filter(quote => quote.text === 'Notably, our current adaptive strategy makes a binary choice between full-context and user-turn-only prompting.').length === 1;
        checks.noDuplicateSourceQuotes = new Set(quotations.map(quote => `${quote.url}\n${quote.text}`)).size === quotations.length;
      }
      return {
        key: target.key, url: location.href, viewport: innerWidth, documentWidth: document.documentElement.scrollWidth,
        checks, quotations, reviewDates: text.match(/Review date: [^\n]+/g),
        firstMeaningfulParagraph: [...content.querySelectorAll('p')].find(paragraph => paragraph.textContent.trim().length > 100)?.textContent.trim()
      };
    }, target);
    if (Object.values(result.checks).some(value => !value)) throw new Error(JSON.stringify(result));
    const updateNoticeClose = page.locator('.toast button[aria-label="Close"]');
    if (await updateNoticeClose.isVisible()) await updateNoticeClose.click();
    const quote = page.locator('article .content blockquote').filter({ has: page.locator('cite a') }).first();
    if (target.source) await quote.scrollIntoViewIfNeeded();
    else await page.locator('article .content h2').first().evaluate(node => node.scrollIntoView({ block: 'start' }));
    await page.waitForTimeout(300);
    await page.screenshot({ path: `logs/2026-11-01/reader-ui/semantic-${target.key}-mobile.png` });
    if (target.key === 'rnn') {
      await page.locator('article .content blockquote').filter({ hasText: 'while Transformers achieve the best accuracy' }).scrollIntoViewIfNeeded();
      await page.waitForTimeout(300);
      await page.screenshot({ path: 'logs/2026-11-01/reader-ui/semantic-rnn-accuracy-mobile.png' });
    }
    results.push(result);
  }
  if (errors.length) throw new Error(JSON.stringify(errors));
  return { samples: results, runtimeErrors: errors, semanticExhaustivenessClaim: false };
}
