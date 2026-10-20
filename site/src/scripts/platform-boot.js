(() => {
  // 截图机型：Android 访客看 Pixel，其他人看 iPhone。手动切过就记住。
  // 首帧前写 html[data-platform]，CSS 按它只亮一套机壳和截图，不会先闪 iPhone 再换。
  const KEY = 'tollcat-platform';
  let platform = null;
  try {
    const stored = localStorage.getItem(KEY);
    if (stored === 'apple' || stored === 'android') platform = stored;
  } catch {
    /* private mode */
  }
  if (!platform) {
    const ua = navigator.userAgent || '';
    const hinted = navigator.userAgentData && navigator.userAgentData.platform;
    platform = hinted === 'Android' || /Android/i.test(ua) ? 'android' : 'apple';
  }
  document.documentElement.dataset.platform = platform;
})();
