(() => {
  const KEY = 'tollcat-theme';
  let pref = 'system';
  try {
    const stored = localStorage.getItem(KEY);
    if (stored === 'light' || stored === 'dark' || stored === 'system') pref = stored;
  } catch {
    /* private mode, disabled storage */
  }
  const theme =
    pref === 'dark' || (pref !== 'light' && matchMedia('(prefers-color-scheme: dark)').matches)
      ? 'dark'
      : 'light';
  const root = document.documentElement;
  root.dataset.theme = theme;
  root.dataset.themePref = pref;

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
})();
