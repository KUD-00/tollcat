import sitemap from '@astrojs/sitemap';
import { copyFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'astro/config';

const siteRoot = dirname(fileURLToPath(import.meta.url));
// 社交卡片和 README 横幅是同一套版式的两档画布，都由
// `scripts/render-readme-hero.mjs` 出。这里拿的是 og 那档（1.91:1）——
// README 那张是扁的，当 og:image 会被各家平台裁掉左边的字。
const readmeHeroes = resolve(siteRoot, '../.github/readme');
for (const locale of ['zh', 'en', 'ja']) {
  copyFileSync(
    resolve(readmeHeroes, `og-${locale}.png`),
    resolve(siteRoot, 'public', `og-${locale}.png`),
  );
}

export default defineConfig({
  site: 'https://tollcat.app',
  trailingSlash: 'always',
  compressHTML: true,
  build: {
    format: 'directory',
    inlineStylesheets: 'always',
    assetsInlineLimit: 0,
  },
  vite: {
    build: {
      assetsInlineLimit: 0,
    },
  },
  i18n: {
    defaultLocale: 'zh',
    locales: ['zh', 'en', 'ja'],
    routing: {
      prefixDefaultLocale: false,
      redirectToDefaultLocale: false,
    },
  },
  integrations: [
    sitemap({
      changefreq: 'weekly',
      lastmod: new Date('2026-08-28'),
      filter: (page) => /^https:\/\/tollcat\.app\/(zh-hans|en|ja)(\/|$)/.test(page),
      i18n: {
        defaultLocale: 'zh-hans',
        locales: {
          'zh-hans': 'zh-Hans',
          en: 'en',
          ja: 'ja',
        },
      },
    }),
  ],
});
