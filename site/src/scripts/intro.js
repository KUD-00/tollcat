// 开场：和 App 启动画面同一屏——整屏品牌紫，完整的口袋居中——停一拍，
// 猫微微放大、淡掉，接着从口袋中心开一个圆洞往外扩，页面从洞里展开。
const root = document.documentElement;
const overlay = document.querySelector('[data-intro-stage]');
const HOLD = 450;
const OPEN = 720;
const EASE = 'cubic-bezier(0.32, 0.72, 0, 1)';
const PURPLE = '#5856D6';

if (root.dataset.intro === 'play' && overlay instanceof HTMLElement) {
  play(overlay);
}

function play(stage) {
  try {
    sessionStorage.setItem('tollcat-intro', '1');
  } catch {
    /* private mode */
  }
  stage.style.animation = 'none';
  const card = stage.querySelector('.intro-card');
  const art = stage.querySelector('.intro-art');
  const restoreTheme = tintThemeColor();
  let done = false;
  const animations = [];

  const finish = () => {
    if (done) return;
    done = true;
    for (const animation of animations) animation.cancel();
    removeListeners();
    restoreTheme();
    root.dataset.intro = 'done';
    stage.remove();
  };

  // 用户等不及：滚、点、按键都直接淡掉，不跟手抢页面。
  const skip = () => {
    if (done) return;
    const fade = stage.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 180, easing: 'ease-out', fill: 'forwards' });
    animations.push(fade);
    fade.finished.then(finish, finish);
  };
  const events = ['wheel', 'touchstart', 'keydown', 'pointerdown'];
  const removeListeners = () => {
    for (const name of events) window.removeEventListener(name, skip, { capture: true });
  };
  for (const name of events) window.addEventListener(name, skip, { capture: true, passive: true });

  window.setTimeout(() => {
    if (done) return;
    if (!(card instanceof HTMLElement) || !(art instanceof Element) || !CSS.supports('mask', 'none')) {
      skip();
      return;
    }
    const box = art.getBoundingClientRect();
    const cx = box.left + box.width / 2;
    const cy = box.top + box.height / 2;
    // 洞要扩到盖过离圆心最远的那个屏角。
    const reach = Math.hypot(Math.max(cx, window.innerWidth - cx), Math.max(cy, window.innerHeight - cy));
    card.style.setProperty('--intro-x', `${cx}px`);
    card.style.setProperty('--intro-y', `${cy}px`);
    // 猫先淡，洞晚一拍再开：页面露出来的时候猫已经不在了。
    const opening = card.animate([{ '--intro-hole': '0px' }, { '--intro-hole': `${reach}px` }], {
      duration: OPEN,
      delay: 120,
      easing: EASE,
      fill: 'forwards',
    });
    animations.push(opening);
    animations.push(
      art.animate(
        [
          { scale: 1, opacity: 1 },
          { scale: 1.18, opacity: 0 },
        ],
        { duration: 220, easing: 'cubic-bezier(0.4, 0, 1, 1)', fill: 'forwards' },
      ),
    );
    opening.finished.then(finish, finish);
  }, HOLD);
}

// 手机浏览器的状态栏跟着 theme-color 走：开场那一秒涂成同一块紫，演完还原。
function tintThemeColor() {
  const metas = [...document.querySelectorAll('meta[name="theme-color"]')];
  const saved = metas.map((meta) => meta.getAttribute('content'));
  for (const meta of metas) meta.setAttribute('content', PURPLE);
  return () => metas.forEach((meta, index) => meta.setAttribute('content', saved[index] ?? ''));
}
