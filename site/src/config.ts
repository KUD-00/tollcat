export const locales = ['zh', 'en', 'ja'] as const;
export type Locale = (typeof locales)[number];

/** URL 前缀。内部 locale 仍是 zh / en / ja；中文对外路径用 zh-hans，和 en、ja 对等。 */
export const localePrefixes = {
  zh: 'zh-hans',
  en: 'en',
  ja: 'ja',
} as const satisfies Record<Locale, string>;

export const localePrefixPattern = Object.values(localePrefixes).join('|');

export const siteConfig = {
  name: 'TollCat',
  url: 'https://tollcat.app',
  /** App Store 链接。不带国家段，Apple 按访客地区跳转。空则主按钮显示「即将上架」，不是假链接。 */
  appStoreUrl: 'https://apps.apple.com/app/tollcat/id6805479811' as string | null,
  /** 源码仓库，public。 */
  githubUrl: 'https://github.com/KUD-00/tollcat',
  /** 反馈、目录、信箱。站点表单和 App 打同一个 origin。 */
  apiUrl: 'https://api.tollcat.app',
  /** iTunes 数字 ID，给 Smart App Banner 和 JSON-LD 用。 */
  appId: '6805479811' as string | null,
  localeBcp47: {
    zh: 'zh-Hans',
    en: 'en',
    ja: 'ja',
  } satisfies Record<Locale, string>,
  ogLocale: {
    zh: 'zh_CN',
    en: 'en_US',
    ja: 'ja_JP',
  } satisfies Record<Locale, string>,
};

/** `.github/readme/og-{locale}.png`，构建时拷到 `/og-{locale}.png`。1.91:1 是各家卡片的裁切比。 */
export const ogImageSize = { width: 2400, height: 1260 } as const;

export function ogImageUrl(locale: Locale): string {
  return `${siteConfig.url}/og-${locale}.png`;
}

export function localePath(locale: Locale, path = ''): string {
  const clean = path.replace(/^\/+|\/+$/g, '');
  const prefix = localePrefixes[locale];
  return clean ? `/${prefix}/${clean}/` : `/${prefix}/`;
}

export function absoluteUrl(locale: Locale, path = ''): string {
  return new URL(localePath(locale, path), siteConfig.url).toString();
}

/** HTML `/zh-hans/privacy/` → Markdown `/zh-hans/privacy.md`. Home is `/zh-hans/index.md`. */
export function markdownPath(locale: Locale, path = ''): string {
  const clean = path.replace(/^\/+|\/+$/g, '');
  const prefix = localePrefixes[locale];
  return clean ? `/${prefix}/${clean}.md` : `/${prefix}/index.md`;
}

export function absoluteMarkdownUrl(locale: Locale, path = ''): string {
  return new URL(markdownPath(locale, path), siteConfig.url).toString();
}

export function siblingPath(current: Locale, next: Locale, path: string): string {
  const rest = path
    .replace(new RegExp(`^\\/(${localePrefixPattern})(?=\\/|$)`, 'i'), '')
    .replace(/^\/+|\/+$/g, '');
  return localePath(next, rest);
}
