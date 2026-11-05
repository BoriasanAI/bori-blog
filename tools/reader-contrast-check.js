async page => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('http://127.0.0.1:8769/bori-blog/posts/day-250-b9becc/', { waitUntil: 'networkidle' });
  await page.evaluate(() => Theme.update('light'));
  const card = page.locator('.cf-signature');
  await card.scrollIntoViewIfNeeded();
  const geometry = await card.evaluate(card => {
    const bounds = card.getBoundingClientRect();
    return {
      width: bounds.width, height: bounds.height,
      samples: [...card.querySelectorAll(':scope > div:not(.cf-formula)')].map(node => {
        const rect = node.getBoundingClientRect();
        const style = getComputedStyle(node);
        return {
          text: node.textContent.trim(), color: style.color, fontSize: style.fontSize,
          x: rect.right - bounds.left - 8, y: rect.top - bounds.top + rect.height / 2
        };
      })
    };
  });
  const png = await card.screenshot({ path: 'logs/2026-11-01/reader-ui/metadata-light.png' });
  const measurements = await page.evaluate(async ({ image, geometry }) => {
    const img = new Image();
    img.src = `data:image/png;base64,${image}`;
    await img.decode();
    const canvas = document.createElement('canvas');
    canvas.width = img.width;
    canvas.height = img.height;
    const context = canvas.getContext('2d');
    context.drawImage(img, 0, 0);
    const luminance = channels => channels.slice(0, 3).map(value => {
      const channel = value / 255;
      return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
    }).reduce((sum, channel, index) => sum + channel * [0.2126, 0.7152, 0.0722][index], 0);
    return geometry.samples.map(sample => {
      const x = Math.floor(sample.x * img.width / geometry.width);
      const y = Math.floor(sample.y * img.height / geometry.height);
      const background = [...context.getImageData(x, y, 1, 1).data].slice(0, 3);
      const foreground = sample.color.match(/[\d.]+/g).map(Number).slice(0, 3);
      const a = luminance(foreground), b = luminance(background);
      return { ...sample, background, contrast: (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) };
    });
  }, { image: png.toString('base64'), geometry });
  return {
    measurements,
    minimumContrast: Math.min(...measurements.map(item => item.contrast)),
    meetsNormalTextAA: measurements.every(item => item.contrast >= 4.5)
  };
}
