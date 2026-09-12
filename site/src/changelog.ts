// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。

import { siteConfig, type Locale } from './config';

export type ChangelogPlatform = 'ios' | 'mac' | 'android' | 'windows';

export type ChangelogItem = {
  /** 稳定 id。改名等于换一条，所以它也是以后远程文本 overlay 的钥匙。 */
  id: string;
  title: string;
  body: string;
};

export type ChangelogLocaleCopy = {
  title: string;
  items: readonly ChangelogItem[];
};

export type ChangelogEntry = {
  version: string;
  /** 上架当天的 YYYY-MM-DD。没上架就省略，页面不编造日期。 */
  date?: string;
  platforms: readonly ChangelogPlatform[];
  /** hero 截图。只有最新一条会带。 */
  shot?: { light: ImageMetadata; dark: ImageMetadata };
  copy: Record<Locale, ChangelogLocaleCopy>;
};

const PLATFORM_ORDER: readonly ChangelogPlatform[] = ['ios', 'mac', 'android', 'windows'];

/** 厂名不进 catalog。ios 那一班车是 iPhone 和 iPad 同一份。 */
export const platformNames: Record<ChangelogPlatform, string> = {
  ios: 'iPhone · iPad',
  mac: 'Mac',
  android: 'Android',
  windows: 'Windows',
};

export const changelog: readonly ChangelogEntry[] = [];

export function latestChangelog(): ChangelogEntry | undefined {
  return changelog[0];
}

export function changelogAnchor(version: string): string {
  return `v${version}`;
}

export function formatChangelogDate(locale: Locale, iso: string): string {
  const [year, month, day] = iso.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return new Intl.DateTimeFormat(siteConfig.localeBcp47[locale], {
    dateStyle: 'long',
    timeZone: 'UTC',
  }).format(date);
}

export function formatChangelogPlatforms(
  platforms: readonly ChangelogPlatform[]
): string {
  return PLATFORM_ORDER.filter((item) => platforms.includes(item))
    .map((item) => platformNames[item])
    .join(' · ');
}
