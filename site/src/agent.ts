import {
  changelog,
  formatChangelogDate,
  formatChangelogPlatforms,
} from './changelog';
import {
  absoluteMarkdownUrl,
  absoluteUrl,
  locales,
  markdownPath,
  siteConfig,
  type Locale,
} from './config';
import { faqPlain, t, type Copy } from './i18n';
import { providerMarks } from './providers';
import { supportListPlain } from './supportList';

export const agentHeaders = {
  markdown: {
    'Content-Type': 'text/markdown; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'public, max-age=3600',
  },
  plain: {
    'Content-Type': 'text/plain; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'public, max-age=3600',
  },
} as const;

export function providerNameList(): string {
  return providerMarks.map((item) => item.name).join(', ');
}

export type AgentPage = 'home' | 'privacy' | 'support' | 'providers' | 'sponsors' | 'changelog';

export function agentRoutes(): { slug: string; locale: Locale; page: AgentPage }[] {
  const pages: AgentPage[] = ['home', 'privacy', 'support', 'providers', 'sponsors', 'changelog'];
  return locales.flatMap((locale) =>
    pages.map((page) => ({
      slug: markdownPath(locale, page === 'home' ? '' : page).replace(/^\//, '').replace(/\.md$/, ''),
      locale,
      page,
    })),
  );
}

function pageTitle(page: AgentPage, copy: Copy): string {
  switch (page) {
    case 'home':
      return siteConfig.name;
    case 'privacy':
      return copy.privacyPage.title;
    case 'providers':
      return copy.supportListPage.title;
    case 'sponsors':
      return copy.sponsorsPage.title;
    case 'changelog':
      return copy.changelogPage.title;
    case 'support':
      return copy.supportPage.title;
  }
}

function frontmatter(locale: Locale, page: AgentPage, copy: Copy): string {
  const path = page === 'home' ? '' : page;
  const title = pageTitle(page, copy);
  return [
    '---',
    `title: ${yamlEscape(title)}`,
    `canonical: ${absoluteUrl(locale, path)}`,
    `language: ${siteConfig.localeBcp47[locale]}`,
    `describedby: ${siteConfig.url}/llms.txt`,
    '---',
    '',
  ].join('\n');
}

function yamlEscape(value: string): string {
  return /[:#]|^\s|\s$/.test(value) ? JSON.stringify(value) : value;
}

function joinTitle(parts: string[]): string {
  return parts.join(' ').replace(/([，。、]) /g, '$1');
}

function platformSlideMarkdown(slides: Copy['platforms']['dialog']['ipad']['slides']): string[] {
  return slides.flatMap((slide) => {
    const lines = [`#### ${slide.title}`, '', ...slide.paragraphs.flatMap((paragraph) => [paragraph, ''])];
    if (slide.to === 'github' && slide.link && siteConfig.githubUrl) {
      lines.push(`[${slide.link}](${siteConfig.githubUrl})`, '');
    }
    return lines;
  });
}

export function pageMarkdown(locale: Locale, page: AgentPage): string {
  const copy = t(locale);
  if (page === 'privacy') return privacyMarkdown(locale, copy);
  if (page === 'support') return supportMarkdown(locale, copy);
  if (page === 'providers') return providersMarkdown(locale, copy);
  if (page === 'sponsors') return sponsorsMarkdown(locale, copy);
  if (page === 'changelog') return changelogMarkdown(locale, copy);
  return homeMarkdown(locale, copy);
}

function homeMarkdown(locale: Locale, copy: Copy): string {
  const lines = [
    frontmatter(locale, 'home', copy),
    `# ${siteConfig.name}`,
    '',
    copy.hero.lede,
    '',
    `## ${copy.facts.title}`,
    '',
    copy.facts.lede,
    '',
    ...copy.facts.items.map((item) => `- ${item}`),
    '',
    copy.facts.not,
    '',
    `## ${joinTitle(copy.setup.title)}`,
    '',
    copy.setup.lede,
    '',
    `## ${joinTitle(copy.providers.title)}`,
    '',
    copy.providers.note,
    '',
    `[${copy.providers.listLink}](${absoluteUrl(locale, 'providers')})`,
    '',
    providerNameList(),
    '',
    `## ${joinTitle([copy.credentials.title[0], `${copy.credentials.title[1]}*`])}`,
    '',
    copy.credentials.lede,
    '',
    `[${copy.credentials.link}](${absoluteUrl(locale, 'privacy')})`,
    '',
    ...copy.credentials.dialog.slides.flatMap((slide) => [`### ${slide.title}`, '', ...slide.paragraphs.flatMap((paragraph) => [paragraph, ''])]),
    `## ${joinTitle(copy.platforms.title)}`,
    '',
    `### ${copy.platforms.dialog.ipad.title}`,
    '',
    copy.platforms.dialog.ipad.lede,
    '',
    ...platformSlideMarkdown(copy.platforms.dialog.ipad.slides),
    `### ${copy.platforms.dialog.mac.title}`,
    '',
    copy.platforms.dialog.mac.lede,
    '',
    ...platformSlideMarkdown(copy.platforms.dialog.mac.slides),
    `### ${copy.platforms.dialog.android.title}`,
    '',
    copy.platforms.dialog.android.lede,
    '',
    ...platformSlideMarkdown(copy.platforms.dialog.android.slides),
    `### ${copy.platforms.dialog.windows.title}`,
    '',
    copy.platforms.dialog.windows.lede,
    '',
    ...platformSlideMarkdown(copy.platforms.dialog.windows.slides),
    `## ${copy.faq.title}`,
    '',
    ...copy.faq.items.flatMap((item) => [`### ${item.q}`, '', faqPlain(item), '']),
    copy.footer.blurb,
    '',
  ];
  return lines.join('\n');
}

function privacyMarkdown(locale: Locale, copy: Copy): string {
  const page = copy.privacyPage;
  const lines = [
    frontmatter(locale, 'privacy', copy),
    `# ${page.title}`,
    '',
    page.description,
    '',
    page.updated,
    '',
    ...page.sections.flatMap((section) => [
      `## ${section.h}`,
      '',
      ...section.p.flatMap((block) =>
        typeof block === 'string'
          ? [block, '']
          : [...block.list.map((item) => `- **${item.term}** ${item.text}`), ''],
      ),
      '',
    ]),
  ];
  return lines.join('\n');
}

function providersMarkdown(locale: Locale, copy: Copy): string {
  const page = copy.supportListPage;
  const lines = [
    frontmatter(locale, 'providers', copy),
    `# ${page.title}`,
    '',
    supportListPlain(locale),
    '',
  ];
  return lines.join('\n');
}

function sponsorsMarkdown(locale: Locale, copy: Copy): string {
  const page = copy.sponsorsPage;
  const lines = [
    frontmatter(locale, 'sponsors', copy),
    `# ${page.title}`,
    '',
    page.lede,
    '',
    `## ${page.offer.title}`,
    '',
    ...page.offer.p.flatMap((para) => [para, '']),
    `## ${page.refuse.title}`,
    '',
    ...page.refuse.items.map((item) => `- ${item}`),
    '',
    `## ${page.who.title}`,
    '',
    ...page.who.p.flatMap((para) => [para, '']),
    `## ${page.form.title}`,
    '',
    page.form.lede,
    '',
    `[${page.title}](${absoluteUrl(locale, 'sponsors')})`,
    '',
  ];
  return lines.join('\n');
}

function changelogMarkdown(locale: Locale, copy: Copy): string {
  const page = copy.changelogPage;
  const body =
    changelog.length === 0
      ? [page.empty, '']
      : changelog.flatMap((entry) => {
          const item = entry.copy[locale];
          const date = entry.date ? formatChangelogDate(locale, entry.date) : '';
          const platforms = formatChangelogPlatforms(entry.platforms);
          const heading = date ? `## ${entry.version} · ${date}` : `## ${entry.version}`;
          return [
            heading,
            '',
            platforms,
            '',
            item.title,
            '',
            ...item.items.map((note) => `- **${note.title}** — ${note.body}`),
            '',
          ];
        });
  const lines = [
    frontmatter(locale, 'changelog', copy),
    `# ${page.title}`,
    '',
    page.lede,
    '',
    ...body,
  ];
  return lines.join('\n');
}

function supportMarkdown(locale: Locale, copy: Copy): string {
  const page = copy.supportPage;
  const lines = [
    frontmatter(locale, 'support', copy),
    `# ${page.title}`,
    '',
    page.lede,
    '',
    page.description,
    '',
  ];
  return lines.join('\n');
}

/** llmstxt.org v2: H1, blockquote, prose, then H2 file lists only. */
export function llmsTxt(): string {
  const en = t('en');
  const optional: string[] = [];
  if (siteConfig.githubUrl) {
    optional.push(`- [Source repository](${siteConfig.githubUrl}): MIT-licensed app source. Currently private.`);
  }
  optional.push(
    `- [Optional API](${siteConfig.apiUrl}): tip notes, feedback, public catalog, reading inbox. None of those paths see provider keys.`,
  );
  if (siteConfig.appStoreUrl) {
    optional.push(`- [App Store](${siteConfig.appStoreUrl}): iOS download.`);
  }

  const pageLinks = locales.flatMap((locale) => {
    const lang = siteConfig.localeBcp47[locale];
    return (['home', 'privacy', 'support', 'providers', 'sponsors', 'changelog'] as const).map((page) => {
      const path = page === 'home' ? '' : page;
      const name =
        page === 'home'
          ? `Home (${lang})`
          : page === 'privacy'
            ? `Privacy (${lang})`
            : page === 'providers'
              ? `Support list (${lang})`
              : page === 'sponsors'
                ? `On your page (${lang})`
                : page === 'changelog'
                  ? `Changelog (${lang})`
                  : `Contact (${lang})`;
      const note =
        page === 'home'
          ? `Product page in ${lang}`
          : page === 'privacy'
            ? `Privacy policy in ${lang}`
            : page === 'providers'
              ? `Which services are fully tested, theoretically supported, inbox-only, or declined, in ${lang}`
              : page === 'sponsors'
                ? `Vendor placement on a service page; no user data, no support-list rank, in ${lang}`
                : page === 'changelog'
                  ? `Shipping versions and release notes, in ${lang}`
                  : `Contact and feedback in ${lang}`;
      return `- [${name}](${absoluteMarkdownUrl(locale, path)}): ${note}`;
    });
  });

  return [
    `# ${siteConfig.name}`,
    '',
    '> An iOS 26 app that folds cloud and AI bills into one month-to-date number on the Lock Screen and Home Screen widget. Credentials stay in on-device Keychain; the optional server never sees them. MIT licensed.',
    '',
    en.facts.lede,
    '',
    ...en.facts.items.map((item) => `- ${item}`),
    '',
    en.facts.not,
    '',
    'It reports spend. It does not shut down instances, change quotas, send remote push, or compute the bill with a cloud model. A local reminder is optional and never includes an amount.',
    '',
    `Platforms: iPhone, iPad (iOS 26+), and Mac (macOS 26+). An Android Compose shell lives in the repo (Android Keystore, not a Play Store listing). Price: free; optional in-app tips; no membership. Tracking: none. Write operations to vendors: none. Ledger currency: USD. Display currency is a presentation option. Device move: encrypted .tollcat export, 10-character code, 24-hour import window. History does not travel with the file.`,
    '',
    `Providers (catalog, subject to change; the in-app list is the source of truth): ${providerNameList()}.`,
    '',
    '## Pages',
    '',
    ...pageLinks,
    '',
    '## Optional',
    '',
    ...optional,
    '',
  ].join('\n');
}

export function llmsFullTxt(): string {
  const parts = [
    `# ${siteConfig.name}`,
    '',
    '> Full text of the marketing site in English, for one-shot ingestion. Prefer /llms.txt when you only need a map.',
    '',
    `HTML: ${siteConfig.url}/en/`,
    `Index: ${siteConfig.url}/llms.txt`,
    '',
    '---',
    '',
    pageMarkdown('en', 'home').replace(/^---[\s\S]*?---\n/, ''),
    '---',
    '',
    pageMarkdown('en', 'privacy').replace(/^---[\s\S]*?---\n/, ''),
    '---',
    '',
    pageMarkdown('en', 'support').replace(/^---[\s\S]*?---\n/, ''),
    '---',
    '',
    pageMarkdown('en', 'providers').replace(/^---[\s\S]*?---\n/, ''),
    '---',
    '',
    pageMarkdown('en', 'sponsors').replace(/^---[\s\S]*?---\n/, ''),
    '---',
    '',
    pageMarkdown('en', 'changelog').replace(/^---[\s\S]*?---\n/, ''),
  ];
  return parts.join('\n');
}

export function markdownResponse(body: string): Response {
  return new Response(body, { headers: agentHeaders.markdown });
}

export function plainResponse(body: string): Response {
  return new Response(body, { headers: agentHeaders.plain });
}
