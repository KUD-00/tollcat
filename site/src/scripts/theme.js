const KEY = 'tollcat-theme';

function isPref(value) {
  return value === 'system' || value === 'light' || value === 'dark';
}

function readPref() {
  try {
    const stored = localStorage.getItem(KEY);
    if (isPref(stored)) return stored;
  } catch {
    /* private mode, disabled storage */
  }
  return 'system';
}

function resolved(pref) {
  if (pref === 'light' || pref === 'dark') return pref;
  return matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function syncThemeColor(pref, theme) {
  const lightColor = document.querySelector('meta[data-theme-color="light"]');
  const darkColor = document.querySelector('meta[data-theme-color="dark"]');
  if (lightColor && darkColor) {
    if (pref === 'system') {
      lightColor.setAttribute('media', '(prefers-color-scheme: light)');
      darkColor.setAttribute('media', '(prefers-color-scheme: dark)');
    } else if (theme === 'dark') {
      lightColor.setAttribute('media', 'not all');
      darkColor.setAttribute('media', 'all');
    } else {
      lightColor.setAttribute('media', 'all');
      darkColor.setAttribute('media', 'not all');
    }
  }
  const scheme = document.querySelector('meta[name="color-scheme"]');
  if (scheme) scheme.setAttribute('content', pref === 'system' ? 'light dark' : theme);
}

function syncMarquee(pref, theme) {
  for (const source of document.querySelectorAll('source[data-theme-src]')) {
    if (pref === 'system') source.media = '(prefers-color-scheme: dark)';
    else source.media = theme === 'dark' ? 'all' : 'not all';
  }
}

function syncSwitch(pref) {
  for (const root of document.querySelectorAll('[data-theme-switch]')) {
    const trigger = root.querySelector('[data-theme-trigger]');
    const labels = {
      system: root.dataset.labelSystem ?? '',
      light: root.dataset.labelLight ?? '',
      dark: root.dataset.labelDark ?? '',
    };
    const menu = root.dataset.menuLabel ?? '';
    if (trigger instanceof HTMLElement) {
      trigger.setAttribute('aria-label', `${labels[pref]}, ${menu}`);
    }
    for (const option of root.querySelectorAll('[data-theme-option]')) {
      const selected = option.dataset.themeOption === pref;
      option.setAttribute('aria-selected', selected ? 'true' : 'false');
      option.classList.toggle('is-selected', selected);
    }
  }
}

function apply(pref, persist) {
  const theme = resolved(pref);
  const root = document.documentElement;
  root.dataset.theme = theme;
  root.dataset.themePref = pref;
  if (persist) {
    try {
      localStorage.setItem(KEY, pref);
    } catch {
      /* private mode, disabled storage */
    }
  }
  syncThemeColor(pref, theme);
  syncMarquee(pref, theme);
  syncSwitch(pref);
}

function bind() {
  for (const root of document.querySelectorAll('[data-theme-switch]')) {
    const popover = root.querySelector('[popover]');
    root.addEventListener('click', (event) => {
      const option = event.target instanceof Element ? event.target.closest('[data-theme-option]') : null;
      if (!option || !root.contains(option)) return;
      const next = option.dataset.themeOption;
      if (!isPref(next)) return;
      apply(next, true);
      if (popover instanceof HTMLElement && typeof popover.hidePopover === 'function') {
        popover.hidePopover();
      }
    });
  }
}

apply(readPref(), false);
bind();

const systemQuery = matchMedia('(prefers-color-scheme: dark)');
const onSystemChange = () => {
  if (readPref() === 'system') apply('system', false);
};
if (typeof systemQuery.addEventListener === 'function') {
  systemQuery.addEventListener('change', onSystemChange);
} else {
  systemQuery.addListener(onSystemChange);
}

window.addEventListener('storage', (event) => {
  if (event.key !== KEY) return;
  apply(isPref(event.newValue) ? event.newValue : 'system', false);
});
