import { describe, expect, test } from "bun:test";
import { ackKey, buildQueue } from "../src/queue";
import type { Snapshot } from "../src/types";

function snapshot(over: Partial<Snapshot> = {}): Snapshot {
  return {
    fetchedAt: "2026-08-31T12:00:00Z",
    account: { email: "a@b.c", name: "tanken", id: "1" },
    feedback: [
      {
        id: "fb-1",
        category: "bug",
        message: "site-form smoke test, ignore",
        contact: null,
        appVersion: "site",
        osVersion: "",
        locale: "zh-Hans",
        deviceModel: "web",
        providers: null,
        createdAt: "2026-08-26T11:02:02.311Z",
      },
    ],
    tips: [
      {
        transactionId: "1",
        productId: "com.zhechengqi.tollcat.tip.medium",
        displayPrice: "$18.00",
        name: null,
        message: null,
        appVersion: "0.1.0",
        createdAt: "2026-08-25T16:10:29.224Z",
      },
    ],
    mailbox: { inboxes: 0, ingestKeys: 0, readings: 0, boxes: [], recent: [] },
    usage: null,
    health: {
      tables: ["feedback", "tips"],
      appliedMigrations: [{ name: "0001_schema.sql", appliedAt: "2026-08-25 03:21:04" }],
      pendingMigrations: ["0002_usage.sql"],
      missingTables: ["usage_visits", "usage_screens"],
      workerDeployedAt: "2026-08-23T12:28:22Z",
      siteDeployedAt: "2026-08-30T09:18:46Z",
      rateLimits: [],
      warnings: [],
    },
    ...over,
  };
}

describe("buildQueue", () => {
  test("health first, then unacked feedback and tips", () => {
    const items = buildQueue(snapshot(), new Set());
    expect(items.map((item) => item.kind)).toEqual(["health", "feedback", "tip"]);
    expect(items[0]?.summary).toBe("0002_usage.sql");
    expect(items[1]?.title).toBe("site-form smoke test, ignore");
    expect(items[2]?.kicker).toBe("$18.00");
  });

  test("acked feedback and tips drop out; health stays", () => {
    const items = buildQueue(
      snapshot(),
      new Set([ackKey("feedback", "fb-1"), ackKey("tip", "1")]),
    );
    expect(items.map((item) => item.kind)).toEqual(["health"]);
  });
});
