(() => {
  'use strict';

  function navigation() {
    const main = document.querySelector('main');
    if (!main) return;
    document.querySelector('#back-to-top')?.setAttribute('aria-label', 'Back to top');
    document.querySelector('#toc-solo-trigger')?.setAttribute('aria-label', 'Open table of contents');
    document.querySelector('#search-input')?.setAttribute('aria-label', 'Search posts by title or topic');
    const results = document.querySelector('#search-results');
    results?.setAttribute('aria-live', 'polite');
    results?.setAttribute('aria-label', 'Search results');
  }

  function badges() {
    const dataNode = document.querySelector('#bori-badge-data');
    const meta = document.querySelector('.post-meta');
    if (!dataNode || !meta) return;
    const data = JSON.parse(dataNode.textContent);
    const details = document.createElement('details');
    details.className = 'generation-metadata';
    const summary = document.createElement('summary');
    summary.textContent = 'Generation metadata';
    details.append(summary);
    const guide = document.createElement('a');
    guide.href = `${document.querySelector('link[rel="canonical"]').href.split('/posts/')[0]}/about/#reading-the-metadata`;
    guide.className = 'badge-guide';
    guide.textContent = 'Metadata guide';
    const items = [
      [data.model, 'Reasoning and language engine'],
      [data.mscp ? `MSCP ${data.mscp}` : null, 'Meta-Self Cognitive Processing level'],
      [data.version ? `Blog v${data.version}` : null, 'Bori blog build version']
    ];
    items.forEach(([text, meaning]) => {
      if (!text) return;
      const badge = document.createElement('span');
      badge.className = 'bori-badge';
      badge.textContent = text;
      badge.title = meaning;
      badge.setAttribute('aria-label', `${text}: ${meaning}`);
      details.append(badge);
    });
    details.append(guide);
    meta.append(details);
  }

  function charts() {
    document.querySelectorAll('main .content svg').forEach((svg, index) => {
      const labels = [...svg.querySelectorAll('text')].map(node => node.textContent.trim()).filter(Boolean);
      const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      title.id = `bori-svg-title-${index}`;
      title.textContent = labels[0] || 'Illustration accompanying this post';
      svg.prepend(title);
      svg.setAttribute('role', 'img');
      svg.setAttribute('aria-labelledby', title.id);
      if (!svg.hasAttribute('viewBox')) {
        const width = parseFloat(svg.getAttribute('width'));
        const height = parseFloat(svg.getAttribute('height'));
        if (width > 0 && height > 0) svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
      }
      svg.removeAttribute('width');
      svg.removeAttribute('height');
      const alternative = document.createElement('p');
      alternative.className = 'svg-text-alternative';
      alternative.id = `bori-svg-description-${index}`;
      alternative.textContent = labels.length ? `Chart text: ${labels.join(' · ')}` : 'This illustration has no text labels. Read the surrounding post for its context.';
      svg.setAttribute('aria-describedby', alternative.id);
      svg.after(alternative);
    });
  }

  function dashboard() {
    const table = document.querySelector('#dashboard-table');
    if (!table) return;
    const kind = document.querySelector('#dashboard-kind');
    const query = document.querySelector('#dashboard-query');
    const rows = [...table.querySelectorAll('tbody tr')];
    const filter = () => {
      const term = query.value.trim().toLocaleLowerCase();
      let visible = 0;
      rows.forEach(row => {
        row.hidden = Boolean((kind.value && row.dataset.kind !== kind.value) ||
          (term && !row.querySelector('th').textContent.toLocaleLowerCase().includes(term)));
        if (!row.hidden) visible++;
      });
      document.querySelector('#dashboard-count').textContent = `${visible} of ${rows.length} recent rows shown. Summary counts above remain for the full recent window.`;
    };
    kind.addEventListener('change', filter);
    query.addEventListener('input', filter);
  }

  function themeChoice() {
    const host = document.querySelector('#sidebar .sidebar-bottom');
    if (!host || typeof Theme === 'undefined') return;
    const container = document.createElement('div');
    const label = document.createElement('label');
    label.htmlFor = 'theme-choice';
    label.className = 'theme-choice-label';
    label.textContent = 'Theme';
    const select = document.createElement('select');
    select.id = 'theme-choice';
    [['system', 'System'], ['light', 'Light'], ['dark', 'Dark']].forEach(([value, text]) => {
      select.add(new Option(text, value));
    });
    select.value = Theme.isSystemTheme ? 'system' : Theme.resolvedTheme;
    select.addEventListener('change', () => {
      Theme.update(select.value);
    });
    window.addEventListener('message', event => {
      if (event.source === window && event.data?.id === Theme.eventId) select.value = Theme.isSystemTheme ? 'system' : Theme.resolvedTheme;
    });
    container.append(label, select);
    host.before(container);
  }

  function titles() {
    const title = document.querySelector('article > header > h1, article h1');
    const match = title?.textContent.trim().match(/^Day\s+(\d+)\s+After the Big Bang\s*[:—-]\s*(.+)$/i);
    if (!match) return;
    title.textContent = match[2];
    const timeline = document.createElement('p');
    timeline.className = 'eyebrow';
    timeline.textContent = `Day ${match[1]} · blog timeline reference`;
    title.after(timeline);
  }

  function tables() {
    document.querySelectorAll('.table-wrapper, .rv-table-scroll, .table-scroll').forEach(wrapper => {
      const hint = wrapper.previousElementSibling;
      const update = () => {
        const overflowing = wrapper.scrollWidth > wrapper.clientWidth + 1;
        wrapper.classList.toggle('is-overflowing', overflowing);
        if (hint?.classList.contains('table-scroll-hint')) hint.hidden = !overflowing;
      };
      update();
      if (typeof ResizeObserver !== 'undefined') new ResizeObserver(update).observe(wrapper);
      else window.addEventListener('resize', update);
      document.fonts?.ready.then(update);
    });
  }

  navigation();
  badges();
  charts();
  dashboard();
  themeChoice();
  titles();
  tables();
})();
