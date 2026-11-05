(() => {
  'use strict';
  const initialize = () => {
    document.querySelectorAll('.rv-image img').forEach(image => {
      const failed = () => {
        const figure = image.closest('.rv-image');
        if (figure.querySelector('.rv-image-error')) return;
        image.hidden = true;
        const message = document.createElement('p');
        message.className = 'rv-image-error';
        message.setAttribute('role', 'status');
        message.textContent = 'Image preview unavailable. The original image link, source and attribution remain available.';
        image.after(message);
      };
      image.addEventListener('error', failed, { once: true });
      if (image.complete && image.naturalWidth === 0) failed();
    });
    document.querySelectorAll('.rv-original').forEach(link => {
      if (typeof HTMLDialogElement === 'undefined' || !HTMLDialogElement.prototype.showModal) return;
      link.addEventListener('click', event => {
        if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        const dialog = document.createElement('dialog');
        dialog.className = 'rv-zoom-dialog';
        dialog.setAttribute('aria-label', 'Full-resolution image');
        const toolbar = document.createElement('div');
        toolbar.className = 'rv-zoom-toolbar';
        const original = document.createElement('a');
        original.href = link.href;
        original.textContent = 'Open original file';
        const close = document.createElement('button');
        close.type = 'button';
        close.textContent = 'Close image';
        close.autofocus = true;
        close.addEventListener('click', () => dialog.close());
        toolbar.append(original, close);
        const viewport = document.createElement('div');
        viewport.className = 'rv-zoom-scroll';
        viewport.tabIndex = 0;
        viewport.setAttribute('aria-label', 'Full-resolution image; scroll to inspect details');
        const image = link.querySelector('img').cloneNode();
        image.removeAttribute('loading');
        image.hidden = false;
        viewport.append(image);
        dialog.append(toolbar, viewport);
        dialog.addEventListener('close', () => {
          dialog.remove();
          link.focus({ preventScroll: true });
        }, { once: true });
        document.body.append(dialog);
        dialog.showModal();
      });
    });
  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize, { once: true });
  } else {
    initialize();
  }
})();
