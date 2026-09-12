import { relativeTime } from "./format";
import { buildQueue } from "./queue";
import type { Snapshot } from "./types";

export function printJSON(snapshot: Snapshot, acked: Set<string>): string {
  return `${JSON.stringify(
    {
      snapshot,
      queue: buildQueue(snapshot, acked),
      acked: [...acked].sort(),
    },
    null,
    2,
  )}\n`;
}

export function printText(snapshot: Snapshot, acked: Set<string>, now = new Date()): string {
  const queue = buildQueue(snapshot, acked);
  const lines: string[] = [];
  const who = snapshot.account
    ? `${snapshot.account.name} · ${snapshot.account.email}`
    : "未登录";

  lines.push(`TollCat ops`);
  lines.push(`${who}  ·  api.tollcat.app  ·  ${snapshot.fetchedAt}`);
  lines.push("");

  lines.push(`待办 ${queue.length}`);
  if (queue.length === 0) {
    lines.push("  没有待办。");
  } else {
    for (const item of queue) {
      lines.push(
        `  [${item.kicker}] ${item.title}  ${item.summary}  ${relativeTime(item.createdAt, now)}`,
      );
    }
  }

  lines.push("");
  lines.push(`反馈 ${snapshot.feedback.length}    打赏 ${snapshot.tips.length}    信箱 ${snapshot.mailbox.inboxes}`);
  if (snapshot.health.pendingMigrations.length > 0) {
    lines.push(`未打上的迁移：${snapshot.health.pendingMigrations.join(", ")}`);
  }
  if (snapshot.health.missingTables.length > 0) {
    lines.push(`缺表：${snapshot.health.missingTables.join(", ")}`);
  }
  if (snapshot.usage) {
    const visits = snapshot.usage.visits.reduce((sum, row) => sum + row.visits, 0);
    lines.push(`近 30 天打开次数合计 ${visits}`);
  } else {
    lines.push("用量表还不存在。");
  }
  if (snapshot.health.workerDeployedAt) {
    lines.push(`Worker 上次部署 ${relativeTime(snapshot.health.workerDeployedAt, now)}`);
  }
  if (snapshot.health.siteDeployedAt) {
    lines.push(`站点上次部署 ${relativeTime(snapshot.health.siteDeployedAt, now)}`);
  }
  for (const warning of snapshot.health.warnings) {
    lines.push(`注意：${warning}`);
  }
  return `${lines.join("\n")}\n`;
}
