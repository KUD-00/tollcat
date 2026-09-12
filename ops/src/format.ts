const CATEGORY_LABEL: Record<string, string> = {
  bug: "缺陷",
  idea: "想法",
  provider: "服务",
  other: "其他",
};

const TIP_SIZE_LABEL: Record<string, string> = {
  small: "小档",
  medium: "中档",
  large: "大档",
};

export function categoryLabel(category: string): string {
  return CATEGORY_LABEL[category] ?? category;
}

export function tipSizeLabel(productId: string): string {
  const size = productId.split(".").at(-1) ?? "";
  return TIP_SIZE_LABEL[size] ?? size;
}

export function truncate(text: string, max: number): string {
  const trimmed = text.replace(/\s+/g, " ").trim();
  if (trimmed.length <= max) return trimmed;
  if (max <= 1) return "…";
  return `${trimmed.slice(0, max - 1)}…`;
}

export function firstLine(text: string): string {
  return text.split(/\r?\n/).find((line) => line.trim().length > 0)?.trim() ?? "";
}

export function relativeTime(iso: string, now: Date): string {
  const millis = Date.parse(normalizeTimestamp(iso));
  if (Number.isNaN(millis)) return iso;
  const sec = Math.round((now.getTime() - millis) / 1000);
  if (sec < 45) return "刚刚";
  if (sec < 3600) return `${Math.floor(sec / 60)} 分钟前`;
  if (sec < 86400) return `${Math.floor(sec / 3600)} 小时前`;
  if (sec < 86400 * 30) return `${Math.floor(sec / 86400)} 天前`;
  return normalizeTimestamp(iso).slice(0, 10);
}

export function normalizeTimestamp(value: string): string {
  const trimmed = value.trim();
  if (/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}/.test(trimmed)) {
    const withT = trimmed.replace(" ", "T");
    return /Z|[+-]\d{2}:\d{2}$/.test(withT) ? withT : `${withT}Z`;
  }
  return trimmed;
}

export function feedbackSource(row: {
  appVersion: string;
  deviceModel: string | null;
}): string {
  if (row.appVersion === "site" || row.deviceModel === "web") return "落地页";
  return row.appVersion ? `App ${row.appVersion}` : "App";
}

export function dash(value: string | null | undefined): string {
  const text = value?.trim() ?? "";
  return text.length > 0 ? text : "—";
}

export function formatUnix(seconds: number): string {
  return new Date(seconds * 1000).toISOString().replace(".000Z", "Z");
}
