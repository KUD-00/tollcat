import { catalogByKey, type CatalogEntry } from './catalogEntries';
import { absoluteUrl, localePath, type Locale } from './config';
import { t } from './i18n';
import { providerMarks, providerNames, type ProviderMark } from './providers';
import { supportTiers, type SupportTier } from './supportTiers';

const nameByKey = new Map(providerNames.map((item) => [item.key, item.name]));
const markByKey = new Map(providerMarks.map((item) => [item.key, item]));

const fallbackSwatch = { light: '#4A525D', dark: '#98A1AD' } as const;

export type SupportItem = {
  key: string;
  name: string;
  mark: ProviderMark;
  entry: CatalogEntry;
  tier: SupportTier;
};

export const supportTierOrder: readonly SupportTier[] = [
  'tested',
  'theoretical',
  'inbox',
  'unsupported',
];

export function itemsForTier(tier: SupportTier): SupportItem[] {
  return supportTiers[tier]
    .map((key) => {
      const name = nameByKey.get(key);
      if (!name) throw new Error(`supportTiers: missing name for ${key}`);
      const entry = catalogByKey[key];
      if (!entry) throw new Error(`supportTiers: missing catalog entry for ${key}`);
      const mark = markByKey.get(key) ?? { key, name, ...fallbackSwatch };
      return { key, name, mark: { ...mark, name }, entry, tier };
    })
    .sort((a, b) => {
      const byMarket = a.entry.marketTier - b.entry.marketTier;
      if (byMarket !== 0) return byMarket;
      return a.name.localeCompare(b.name, 'en');
    });
}

export function allSupportItems(): SupportItem[] {
  return supportTierOrder.flatMap(itemsForTier);
}

export function supportListHref(locale: Locale): string {
  return localePath(locale, 'providers');
}

export function supportDetailHref(locale: Locale, key: string): string {
  return `${supportListHref(locale)}#${key}`;
}

export function supportListPlain(locale: Locale): string {
  const copy = t(locale).supportListPage;
  const lines: string[] = [];
  // declineReason 的源头在 ProviderCatalog.swift，没有译文，只在中文页出现。
  const zhOnly = locale === 'zh';
  for (const tier of supportTierOrder) {
    const items = itemsForTier(tier);
    const section = copy.sections[tier];
    lines.push(`## ${section.title} (${items.length})`, '', section.lede, '');
    for (const item of items) {
      const market = copy.market[item.entry.marketTier];
      const bits = [
        `### ${item.name}`,
        '',
        `- ${copy.detail.kinds[item.entry.kind]}`,
        `- ${section.title}`,
        `- ${market.label}`,
      ];
      if (item.entry.summary) bits.push('', item.entry.summary[locale]);
      if (zhOnly) bits.push('', item.entry.marketTierReason);
      else bits.push('', market.lede);
      if (item.entry.declineReason && zhOnly) bits.push('', item.entry.declineReason);
      if (item.entry.plans.length > 0) {
        bits.push(
          '',
          ...item.entry.plans.map((plan) => `- ${plan.name[locale]}: $${plan.amountUSD}`),
        );
      }
      bits.push('');
      lines.push(...bits);
    }
  }
  lines.push(`${copy.footnote} ${absoluteUrl(locale, 'support')}`);
  return lines.join('\n');
}
