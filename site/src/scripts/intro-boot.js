(() => {
  // 开场只在首页、每个标签页演一次，首帧前决定。CSS 只认 html[data-intro="play"]：
  // 没有 JS、减少动态效果、带锚点进来、爬虫和测速，一律直接看页面。
  // 「演过了」由 intro.js 真演起来时才记，免得 locale-boot 跳转前这一页先把次数用掉。
  const BOT = /bot|crawl|spider|slurp|Lighthouse|PageSpeed|HeadlessChrome|PTST/i;
  try {
    if (sessionStorage.getItem('tollcat-intro')) return;
  } catch {
    return;
  }
  if (location.hash) return;
  if (BOT.test(navigator.userAgent || '')) return;
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  document.documentElement.dataset.intro = 'play';
})();
