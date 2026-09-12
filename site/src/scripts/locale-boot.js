(() => {
  // 三语对等：/zh-hans/、/en/、/ja/。无前缀的 / 只做入口，按浏览器语言跳到带前缀的地址。
  // 爬虫不跑 JS 或被 UA 拦掉，继续看无前缀中文页（canonical 指向 /zh-hans/）。
  const KEY = 'tollcat-locale';
  const LOCALES = ['zh', 'en', 'ja'];
  const PREFIX = { zh: 'zh-hans', en: 'en', ja: 'ja' };
  const PREFIX_RE = /^\/(zh-hans|en|ja)(?=\/|$)/i;
  const BOT =
    /Googlebot|AdsBot-Google|Mediapartners-Google|Bingbot|Slurp|DuckDuckBot|Baiduspider|Yandex(Bot|Images)|Sogou|Applebot|Twitterbot|facebookexternalhit|LinkedInBot|Bytespider|GPTBot|ClaudeBot|CCBot|PerplexityBot|OAI-SearchBot|ChatGPT-User|Claude-User|Google-Extended/i;

  if (BOT.test(navigator.userAgent || '')) return;

  function pathLocale(pathname) {
    const match = pathname.match(PREFIX_RE);
    if (!match) return null;
    const prefix = match[1].toLowerCase();
    if (prefix === 'zh-hans') return 'zh';
    if (prefix === 'en') return 'en';
    if (prefix === 'ja') return 'ja';
    return null;
  }

  function localePath(locale, pathname) {
    const rest = pathname.replace(PREFIX_RE, '').replace(/^\/+|\/+$/g, '');
    const prefix = PREFIX[locale];
    return rest ? `/${prefix}/${rest}/` : `/${prefix}/`;
  }

  function readStored() {
    try {
      const value = localStorage.getItem(KEY);
      if (LOCALES.includes(value)) return value;
    } catch {
      /* private mode */
    }
    return null;
  }

  function writeStored(locale) {
    try {
      localStorage.setItem(KEY, locale);
    } catch {
      /* private mode */
    }
  }

  function detect() {
    const list =
      navigator.languages && navigator.languages.length
        ? navigator.languages
        : [navigator.language];
    for (const raw of list) {
      if (!raw) continue;
      const tag = String(raw).toLowerCase();
      if (tag.startsWith('ja')) return 'ja';
      if (tag.startsWith('en')) return 'en';
      if (tag.startsWith('zh')) return 'zh';
    }
    return 'zh';
  }

  function go(locale, pathname) {
    const next = localePath(locale, pathname) + location.search + location.hash;
    const here = pathname.endsWith('/') ? pathname : `${pathname}/`;
    if (next !== here + location.search + location.hash && next !== pathname + location.search + location.hash) {
      location.replace(next);
      return true;
    }
    return false;
  }

  const current = pathLocale(location.pathname);
  const stored = readStored();

  if (current === null) {
    const wanted = stored || detect();
    writeStored(wanted);
    if (go(wanted, location.pathname)) return;
  } else {
    if (!stored) writeStored(current);
    else if (stored !== current && go(stored, location.pathname)) return;
    else if (go(current, location.pathname)) return;
  }

  document.addEventListener('click', (event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const link = target.closest('a[data-locale]');
    if (!link) return;
    const locale = link.getAttribute('data-locale');
    if (LOCALES.includes(locale)) writeStored(locale);
  });
})();
