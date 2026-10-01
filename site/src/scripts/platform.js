const KEY = 'tollcat-platform';

function isPlatform(value) {
  return value === 'apple' || value === 'android';
}

function current() {
  return document.documentElement.dataset.platform === 'android' ? 'android' : 'apple';
}

function syncSwitches(platform) {
  for (const option of document.querySelectorAll('[data-platform-option]')) {
    option.setAttribute('aria-checked', option.dataset.platformOption === platform ? 'true' : 'false');
    option.tabIndex = option.dataset.platformOption === platform ? 0 : -1;
  }
}

function apply(platform, persist) {
  document.documentElement.dataset.platform = platform;
  if (persist) {
    try {
      localStorage.setItem(KEY, platform);
    } catch {
      /* private mode */
    }
  }
  syncSwitches(platform);
  document.dispatchEvent(new CustomEvent('tollcat:platform', { detail: { platform } }));
}

document.addEventListener('click', (event) => {
  const target = event.target instanceof Element ? event.target : null;
  const option = target?.closest('[data-platform-option]');
  if (option && isPlatform(option.dataset.platformOption)) {
    apply(option.dataset.platformOption, true);
    return;
  }
  // 弹窗里的「在这页换成 Android 截图」：切过去、关弹窗、回到首屏看手机。
  const setter = target?.closest('[data-platform-set]');
  if (setter && isPlatform(setter.dataset.platformSet)) {
    event.preventDefault();
    apply(setter.dataset.platformSet, true);
    const dialog = setter.closest('dialog');
    if (dialog instanceof HTMLDialogElement && dialog.open) dialog.close();
    const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
  }
});

// 单选组的方向键：左右在两个选项间移动并选中，和原生 radio 一样。
document.addEventListener('keydown', (event) => {
  const target = event.target instanceof Element ? event.target.closest('[data-platform-option]') : null;
  if (!target) return;
  if (!['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(event.key)) return;
  event.preventDefault();
  const next = current() === 'apple' ? 'android' : 'apple';
  apply(next, true);
  const group = target.closest('[data-platform-switch]');
  group?.querySelector(`[data-platform-option="${next}"]`)?.focus();
});

window.addEventListener('storage', (event) => {
  if (event.key === KEY && isPlatform(event.newValue)) apply(event.newValue, false);
});

syncSwitches(current());
