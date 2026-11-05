(() => {
  'use strict';
  const initialize = () => {
    document.querySelectorAll('.reader-visuals .rv-image img').forEach(image => {
      const failed = () => {
        const figure = image.closest('.rv-image');
        if (figure.querySelector('.rv-image-error')) return;
        image.hidden = true;
        const message = document.createElement('p');
        message.className = 'rv-image-error';
        message.setAttribute('role', 'status');
        message.textContent = 'Preview unavailable / 미리보기를 불러오지 못했습니다. Source and attribution remain below / 출처와 저작자 표시는 아래에 유지됩니다.';
        image.after(message);
      };
      image.addEventListener('error', failed, { once: true });
      if (image.complete && image.naturalWidth === 0) failed();
    });
  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize, { once: true });
  } else {
    initialize();
  }
})();
