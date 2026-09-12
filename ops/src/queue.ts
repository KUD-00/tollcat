import {
  categoryLabel,
  dash,
  feedbackSource,
  firstLine,
  tipSizeLabel,
  truncate,
} from "./format";
import type { FeedbackRow, QueueItem, Snapshot, TipRow } from "./types";

export function ackKey(kind: "feedback" | "tip", id: string): string {
  return `${kind}:${id}`;
}

export function buildQueue(snapshot: Snapshot, acked: Set<string>): QueueItem[] {
  const items: QueueItem[] = [];

  for (const name of snapshot.health.pendingMigrations) {
    items.push(migrationItem(snapshot, name));
  }
  if (
    snapshot.health.pendingMigrations.length === 0 &&
    snapshot.health.missingTables.length > 0
  ) {
    items.push(missingTablesItem(snapshot));
  }
  for (const warning of snapshot.health.warnings) {
    items.push({
      id: `health:warning:${warning}`,
      kind: "health",
      kicker: "健康",
      title: "注意",
      summary: warning,
      createdAt: snapshot.fetchedAt,
      lines: [warning],
      copyText: warning,
    });
  }

  for (const row of snapshot.feedback) {
    if (acked.has(ackKey("feedback", row.id))) continue;
    items.push(feedbackItem(row));
  }
  for (const row of snapshot.tips) {
    if (acked.has(ackKey("tip", row.transactionId))) continue;
    items.push(tipItem(row));
  }

  return items;
}

export function feedbackItem(row: FeedbackRow): QueueItem {
  const title = firstLine(row.message) || "（没有正文）";
  return {
    id: ackKey("feedback", row.id),
    kind: "feedback",
    kicker: categoryLabel(row.category),
    title,
    summary: feedbackSource(row),
    createdAt: row.createdAt,
    lines: feedbackLines(row),
    copyText: row.contact?.trim() || row.id,
  };
}

export function tipItem(row: TipRow): QueueItem {
  const title = firstLine(row.message ?? "") || "没有留言";
  return {
    id: ackKey("tip", row.transactionId),
    kind: "tip",
    kicker: row.displayPrice || tipSizeLabel(row.productId),
    title,
    summary: [row.name, tipSizeLabel(row.productId)].filter(Boolean).join(" · "),
    createdAt: row.createdAt,
    lines: tipLines(row),
    copyText: row.transactionId,
  };
}

export function feedbackLines(row: FeedbackRow): string[] {
  return [
    `类别    ${categoryLabel(row.category)} (${row.category})`,
    `来源    ${feedbackSource(row)}`,
    `语言    ${dash(row.locale)}`,
    `系统    ${dash(row.osVersion)}`,
    `设备    ${dash(row.deviceModel)}`,
    `接入    ${dash(row.providers)}`,
    `联系    ${dash(row.contact)}`,
    `时间    ${row.createdAt}`,
    `id      ${row.id}`,
    "",
    row.message.trim() || "（没有正文）",
    ...(row.exchange?.trim()
      ? ["", "—— HTTP ——", row.exchange.trim()]
      : []),
  ];
}

export function tipLines(row: TipRow): string[] {
  return [
    `档位    ${tipSizeLabel(row.productId)}`,
    `金额    ${dash(row.displayPrice)}`,
    `产品    ${row.productId}`,
    `名字    ${dash(row.name)}`,
    `版本    ${dash(row.appVersion)}`,
    `时间    ${row.createdAt}`,
    `单号    ${row.transactionId}`,
    "",
    row.message?.trim() || "没有留言。",
  ];
}

function migrationItem(snapshot: Snapshot, name: string): QueueItem {
  const missing = snapshot.health.missingTables;
  const lines = [
    `远端 D1 还没打上 ${name}。`,
    missing.length > 0 ? `因此缺表：${missing.join(", ")}。` : null,
    "页面计数、以及任何依赖这些表的写入，现在都会失败。",
    "",
    "修法：",
    "  cd worker && npx wrangler d1 migrations apply tollcat --remote",
  ].filter((line): line is string => line !== null);

  return {
    id: `health:migration:${name}`,
    kind: "health",
    kicker: "健康",
    title: "迁移未打上",
    summary: name,
    createdAt: snapshot.fetchedAt,
    lines,
    copyText: "npx wrangler d1 migrations apply tollcat --remote",
  };
}

function missingTablesItem(snapshot: Snapshot): QueueItem {
  const missing = snapshot.health.missingTables;
  return {
    id: `health:tables:${missing.join(",")}`,
    kind: "health",
    kicker: "健康",
    title: "缺表",
    summary: truncate(missing.join(", "), 40),
    createdAt: snapshot.fetchedAt,
    lines: [
      `远端 D1 没有这些表：${missing.join(", ")}。`,
      "迁移记录却显示已经打过。库和代码对不上。",
    ],
    copyText: missing.join(", "),
  };
}
