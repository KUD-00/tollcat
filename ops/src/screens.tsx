import { Box, Text } from "ink";
import { dash, formatUnix, relativeTime } from "./format";
import { ackKey, feedbackItem, tipItem } from "./queue";
import { accent } from "./theme";
import type { QueueItem, Snapshot } from "./types";
import { Detail, ScrollList, type ListRow } from "./ui";

export function MasterDetail(props: {
  rows: ListRow[];
  selected: number;
  title: string;
  lines: string[];
  empty: string;
  wide: boolean;
  width: number;
  height: number;
}) {
  const listShare = props.wide ? 0.46 : 0.42;
  const listHeight = props.wide ? props.height : Math.max(3, Math.floor(props.height * listShare));
  const detailHeight = props.wide ? props.height : Math.max(3, props.height - listHeight);

  return (
    <Box flexDirection={props.wide ? "row" : "column"} height={props.height} width={props.width}>
      <Box
        width={props.wide ? Math.floor(props.width * 0.52) : props.width}
        height={listHeight}
        flexDirection="column"
      >
        <ScrollList
          rows={props.rows}
          selected={props.selected}
          height={listHeight}
          empty={props.empty}
        />
      </Box>
      <Detail title={props.title} lines={props.lines} height={detailHeight} />
    </Box>
  );
}

export function InboxScreen(props: { snapshot: Snapshot; now: Date; height: number }) {
  const mail = props.snapshot.mailbox;
  const lines = [
    `信箱 ${mail.inboxes}    投递钥匙 ${mail.ingestKeys}    最新读数 ${mail.readings}`,
    "",
  ];
  if (mail.boxes.length === 0) {
    lines.push("还没有信箱。");
  } else {
    lines.push("信箱");
    for (const box of mail.boxes.slice(0, 8)) {
      lines.push(
        `  ${box.inboxId.slice(0, 12)}…  钥匙 ${box.keys}  读数 ${box.readings}  ${relativeTime(box.lastReadingAt ?? box.createdAt, props.now)}`,
      );
    }
    lines.push("");
  }
  if (mail.recent.length > 0) {
    lines.push("最近读数");
    for (const row of mail.recent.slice(0, 12)) {
      lines.push(
        `  ${row.provider.padEnd(10)}  ${dash(row.currentSpendUsd).padStart(10)}  ${row.periodStart}  ${relativeTime(row.reportedAt, props.now)}`,
      );
    }
  }
  return (
    <Box flexDirection="column" height={props.height} overflow="hidden">
      {lines.slice(0, props.height).map((line, index) => (
        <Text key={`${index}:${line.slice(0, 20)}`} wrap="truncate">
          {line.length === 0 ? " " : line}
        </Text>
      ))}
    </Box>
  );
}

export function UsageScreen(props: { snapshot: Snapshot; height: number }) {
  const usage = props.snapshot.usage;
  if (!usage) {
    const pending = props.snapshot.health.pendingMigrations;
    return (
      <Box flexDirection="column" height={props.height} overflow="hidden">
        <Text>用量表还不在远端 D1 上。</Text>
        <Text> </Text>
        {pending.length > 0 ? (
          <Text>未打上：{pending.join(", ")}</Text>
        ) : (
          <Text>缺表：{props.snapshot.health.missingTables.join(", ") || "—"}</Text>
        )}
        <Text> </Text>
        <Text>cd worker && npx wrangler d1 migrations apply tollcat --remote</Text>
      </Box>
    );
  }

  const byDay = new Map<string, number>();
  for (const row of usage.visits) {
    byDay.set(row.day, (byDay.get(row.day) ?? 0) + row.visits);
  }
  const days = [...byDay.entries()].sort((a, b) => b[0].localeCompare(a[0]));
  const max = Math.max(1, ...days.map(([, n]) => n));
  const barWidth = 16;
  const lines: string[] = ["近 30 天打开次数", ""];
  for (const [day, n] of days.slice(0, 14)) {
    const filled = Math.round((n / max) * barWidth);
    lines.push(`  ${day}  ${"█".repeat(filled)}${"░".repeat(barWidth - filled)}  ${n}`);
  }
  lines.push("");
  lines.push("近 7 天页面");
  for (const row of usage.screens.slice(0, 12)) {
    lines.push(
      `  ${row.day}  ${row.platform.padEnd(8)}  ${row.screen.padEnd(24)}  ${row.views}`,
    );
  }

  return (
    <Box flexDirection="column" height={props.height} overflow="hidden">
      {lines.slice(0, props.height).map((line, index) => (
        <Text key={`${index}:${line.slice(0, 20)}`} wrap="truncate">
          {line.length === 0 ? " " : line}
        </Text>
      ))}
    </Box>
  );
}

export function HealthScreen(props: { snapshot: Snapshot; now: Date; height: number }) {
  const health = props.snapshot.health;
  const account = props.snapshot.account;
  const lines: string[] = [
    `账号    ${account ? `${account.name}  ${account.email}` : "—"}`,
    `Worker  ${health.workerDeployedAt ? relativeTime(health.workerDeployedAt, props.now) : "—"}  ${dash(health.workerDeployedAt)}`,
    `站点    ${health.siteDeployedAt ? relativeTime(health.siteDeployedAt, props.now) : "—"}  ${dash(health.siteDeployedAt)}`,
    "",
    "迁移",
  ];
  const applied = new Set(health.appliedMigrations.map((item) => item.name));
  const known = [
    ...health.appliedMigrations.map((item) => item.name),
    ...health.pendingMigrations.filter((name) => !applied.has(name)),
  ];
  const seen = new Set<string>();
  for (const name of known) {
    if (seen.has(name)) continue;
    seen.add(name);
    const row = health.appliedMigrations.find((item) => item.name === name);
    if (row) lines.push(`  已打上  ${name}  ${row.appliedAt}`);
    else lines.push(`  未打上  ${name}`);
  }
  if (health.missingTables.length > 0) {
    lines.push("");
    lines.push(`缺表    ${health.missingTables.join(", ")}`);
  }
  if (health.warnings.length > 0) {
    lines.push("");
    for (const warning of health.warnings) lines.push(`注意    ${warning}`);
  }
  lines.push("");
  lines.push("限流桶");
  if (health.rateLimits.length === 0) {
    lines.push("  空");
  } else {
    for (const row of health.rateLimits.slice(0, 8)) {
      lines.push(`  ${row.count}  ${row.bucket}  ${formatUnix(row.windowStart)}`);
    }
  }

  return (
    <Box flexDirection="column" height={props.height} overflow="hidden">
      {health.pendingMigrations.length > 0 ? (
        <Text color="yellow">有未打上的迁移。</Text>
      ) : (
        <Text color={accent}>迁移与本地文件一致。</Text>
      )}
      {lines.slice(0, props.height - 1).map((line, index) => (
        <Text key={`${index}:${line.slice(0, 24)}`} wrap="truncate">
          {line.length === 0 ? " " : line}
        </Text>
      ))}
    </Box>
  );
}

export function queueRows(items: QueueItem[], now: Date): ListRow[] {
  return items.map((item) => ({
    id: item.id,
    kicker: item.kicker,
    title: item.title,
    meta: relativeTime(item.createdAt, now),
    warn: item.kind === "health",
  }));
}

export function feedbackRows(
  snapshot: Snapshot,
  acked: Set<string>,
  now: Date,
): ListRow[] {
  return snapshot.feedback.map((row) => {
    const item = feedbackItem(row);
    return {
      id: item.id,
      kicker: item.kicker,
      title: item.title,
      meta: relativeTime(row.createdAt, now),
      dim: acked.has(ackKey("feedback", row.id)),
    };
  });
}

export function tipRows(snapshot: Snapshot, acked: Set<string>, now: Date): ListRow[] {
  return snapshot.tips.map((row) => {
    const item = tipItem(row);
    return {
      id: item.id,
      kicker: item.kicker,
      title: item.title,
      meta: relativeTime(row.createdAt, now),
      dim: acked.has(ackKey("tip", row.transactionId)),
    };
  });
}
