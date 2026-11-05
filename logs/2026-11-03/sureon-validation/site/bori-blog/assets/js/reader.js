(() => {
  'use strict';

  function navigation() {
    const main = document.querySelector('main');
    if (!main) return;
    document.querySelector('#back-to-top')?.setAttribute('aria-label', 'Back to top');
    document.querySelector('#toc-solo-trigger')?.setAttribute('aria-label', 'Open table of contents / 목차');
    document.querySelector('#search-input')?.setAttribute('aria-label', 'Search posts by title or topic / 글 검색');
    const results = document.querySelector('#search-results');
    results?.setAttribute('aria-live', 'polite');
    results?.setAttribute('aria-label', 'Search results');
  }

  function badges() {
    const dataNode = document.querySelector('#bori-badge-data');
    const meta = document.querySelector('.post-meta');
    if (!dataNode || !meta) return;
    const data = JSON.parse(dataNode.textContent);
    const guide = document.createElement('a');
    guide.href = `${document.querySelector('link[rel="canonical"]').href.split('/posts/')[0]}/about/#reading-the-metadata`;
    guide.className = 'badge-guide';
    guide.textContent = 'Metadata guide / 표기 안내';
    const items = [
      [data.model, 'Recorded generation tool/model label, not a quality score'],
      [data.mscp ? `MSCP ${data.mscp}` : null, 'Recorded processing-level label; see the metadata guide'],
      [data.version ? `Blog v${data.version}` : null, 'Configured blog build label, not a per-post engine version']
    ];
    items.forEach(([text, meaning]) => {
      if (!text) return;
      const badge = document.createElement('span');
      badge.className = 'bori-badge';
      badge.textContent = text;
      badge.title = meaning;
      badge.setAttribute('aria-label', `${text}: ${meaning}`);
      meta.append(badge);
    });
    meta.append(guide);
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
    label.textContent = 'Theme / 화면 테마';
    const select = document.createElement('select');
    select.id = 'theme-choice';
    [['system', 'System / 시스템'], ['light', 'Light / 밝게'], ['dark', 'Dark / 어둡게']].forEach(([value, text]) => {
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

  navigation();
  badges();
  charts();
  dashboard();
  themeChoice();
  titles();
})();
