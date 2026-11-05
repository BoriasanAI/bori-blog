(() => {
  'use strict';
  const container = document.querySelector('#bori-comments');
  if (!container) return;
  const script = document.createElement('script');
  script.src = 'https://giscus.app/client.js';
  const attributes = JSON.parse(container.dataset.config);
  Object.entries(attributes).forEach(([key, value]) => script.setAttribute(key, value));
  script.setAttribute('data-theme', Theme.isDark ? 'dark_dimmed' : 'light');
  script.crossOrigin = 'anonymous';
  script.async = true;
  const unavailable = () => {
    const status = document.querySelector('#bori-comments-status');
    if (status) status.firstChild.textContent = 'Embedded comments are unavailable. You can use ';
  };
  script.addEventListener('error', unavailable);
  container.append(script);
  const timer = window.setTimeout(unavailable, 15000);
  window.addEventListener('message', event => {
    if (event.origin === 'https://giscus.app' && event.source === container.querySelector('iframe')?.contentWindow && event.data?.giscus) {
      if (event.data.giscus.error) unavailable();
      if (event.data.giscus.discussion) {
        window.clearTimeout(timer);
        document.querySelector('#bori-comments-status')?.remove();
      }
    }
    if (event.source === window && event.data?.id === Theme.eventId) {
      container.querySelector('iframe')?.contentWindow.postMessage({
        giscus: { setConfig: { theme: Theme.isDark ? 'dark_dimmed' : 'light' } }
      }, 'https://giscus.app');
    }
  });
})();
