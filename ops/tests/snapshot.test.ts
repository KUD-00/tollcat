import { describe, expect, test } from "bun:test";
import { repoRoot } from "../src/paths";
import { fetchSnapshot } from "../src/snapshot";
import type { CommandResult, Runner } from "../src/wrangler";

function d1(results: unknown[]) {
  return JSON.stringify(
    results.map((rows) => ({ results: rows, success: true })),
  );
}

function runner(): Runner {
  return async (args): Promise<CommandResult> => {
    if (args[0] === "whoami") {
      return {
        stdout: JSON.stringify({
          loggedIn: true,
          email: "ops@example.com",
          accounts: [{ id: "acct", name: "tanken" }],
        }),
        stderr: "",
        code: 0,
      };
    }
    if (args[0] === "deployments") {
      const name = args.includes("--name") ? "site" : "worker";
      const created =
        name === "site" ? "2026-08-30T09:18:46.308761Z" : "2026-08-23T12:28:22.508364Z";
      return {
        stdout: JSON.stringify([{ created_on: created }]),
        stderr: "",
        code: 0,
      };
    }
    if (args[0] === "d1") {
      const sql = args.at(-1) ?? "";
      if (sql.includes("usage_visits")) {
        return { stdout: "no such table", stderr: "no such table", code: 1 };
      }
      return {
        stdout: d1([
          [
            {
              id: "fb-1",
              category: "bug",
              message: "site-form smoke test, ignore",
              contact: null,
              app_version: "site",
              os_version: "",
              locale: "zh-Hans",
              device_model: "web",
              providers: null,
              created_at: "2026-08-26T11:02:02.311Z",
            },
          ],
          [
            {
              transaction_id: "1",
              product_id: "com.zhechengqi.tollcat.tip.medium",
              display_price: "$18.00",
              name: null,
              message: null,
              app_version: "0.1.0",
              created_at: "2026-08-25T16:10:29.224Z",
            },
          ],
          [{ inboxes: 0, ingest_keys: 0, readings: 0 }],
          [],
          [],
          [{ name: "0001_schema.sql", applied_at: "2026-08-25 03:21:04" }],
          [
            { name: "feedback" },
            { name: "tips" },
            { name: "inboxes" },
            { name: "ingest_keys" },
            { name: "readings" },
            { name: "rate_limits" },
          ],
          [],
        ]),
        stderr: "",
        code: 0,
      };
    }
    return { stdout: "", stderr: `unknown ${args.join(" ")}`, code: 1 };
  };
}

describe("fetchSnapshot", () => {
  test("assembles D1 rows, pending migration, and deploys", async () => {
    const snap = await fetchSnapshot({
      root: repoRoot(),
      runner: runner(),
      now: new Date("2026-08-31T12:00:00Z"),
    });
    expect(snap.account?.name).toBe("tanken");
    expect(snap.feedback).toHaveLength(1);
    expect(snap.feedback[0]?.appVersion).toBe("site");
    expect(snap.tips[0]?.displayPrice).toBe("$18.00");
    expect(snap.health.pendingMigrations).toContain("0002_usage.sql");
    expect(snap.health.missingTables).toEqual(["usage_visits", "usage_screens"]);
    expect(snap.usage).toBeNull();
    expect(snap.health.workerDeployedAt).toContain("2026-08-23");
    expect(snap.health.siteDeployedAt).toContain("2026-08-30");
  });
});
