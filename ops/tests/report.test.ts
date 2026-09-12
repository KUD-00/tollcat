import { describe, expect, test } from "bun:test";
import { printText } from "../src/report";
import type { Snapshot } from "../src/types";

describe("printText", () => {
  test("mentions pending migration and feedback", () => {
    const snapshot: Snapshot = {
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
      tips: [],
      mailbox: { inboxes: 0, ingestKeys: 0, readings: 0, boxes: [], recent: [] },
      usage: null,
      health: {
        tables: [],
        appliedMigrations: [],
        pendingMigrations: ["0002_usage.sql"],
        missingTables: ["usage_visits"],
        workerDeployedAt: null,
        siteDeployedAt: null,
        rateLimits: [],
        warnings: [],
      },
    };
    const text = printText(snapshot, new Set(), new Date("2026-08-31T12:00:00Z"));
    expect(text).toContain("待办 2");
    expect(text).toContain("0002_usage.sql");
    expect(text).toContain("site-form smoke test, ignore");
    expect(text).toContain("用量表还不存在");
  });
});
