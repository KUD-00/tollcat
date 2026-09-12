// 首屏 h1 轮换：iOS contentTransition(.numericText()) 的 web 版。
// 旧行向上滑出并模糊淡出，新行自下方滑入，两行错开一拍。
// 无 JS / prefers-reduced-motion 时静止在服务端渲染的第一句。

const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

const DWELL_MS = 6000;
const SWAP_MS = 450;
const STAGGER_MS = 120;

function init() {
  const h1 = document.querySelector('[data-h1-rotate]');
  if (!h1) return;

  let phrases;
  try {
    phrases = JSON.parse(h1.dataset.h1Rotate);
  } catch {
    return;
  }
  if (!Array.isArray(phrases) || phrases.length < 2) return;

  const lines = Array.from(h1.querySelectorAll('.h1-line-text'));
  if (lines.length === 0) return;

  // 视觉在轮换，但可及名称与 SEO 固定为第一句。
  h1.setAttribute('aria-label', phrases[0].join(''));
  for (const line of lines) line.setAttribute('aria-hidden', 'true');

  let index = 0;
  let timer = 0;

  function swapLine(el, text, delay) {
    setTimeout(() => {
      el.classList.add('is-out');
      setTimeout(() => {
        el.textContent = text;
        el.classList.add('is-in');
        el.classList.remove('is-out');
        // 强制 reflow，让 is-in 的起始位形生效后再过渡回原位。
        void el.offsetWidth;
        el.classList.remove('is-in');
      }, SWAP_MS);
    }, delay);
  }

  function tick() {
    if (motionQuery.matches) return schedule();
    if (document.hidden) return schedule();
    const rect = h1.getBoundingClientRect();
    if (rect.bottom < 0 || rect.top > window.innerHeight) return schedule();

    index = (index + 1) % phrases.length;
    const next = phrases[index];
    lines.forEach((el, i) => swapLine(el, next[i] ?? '', i * STAGGER_MS));
    schedule();
  }

  function schedule() {
    timer = setTimeout(tick, DWELL_MS);
  }

  schedule();

  // 页面被藏起再回来时，从头计时，避免一回来就跳字。
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
      clearTimeout(timer);
      schedule();
    }
  });
}

init();
