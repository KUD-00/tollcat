import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { diffMigrations, readLocalMigrations, tablesDeclaredIn } from "../src/migrations";
import { repoRoot } from "../src/paths";

describe("migrations", () => {
  test("parses CREATE TABLE names", () => {
    const sql = readFileSync(
      join(repoRoot(), "worker", "migrations", "0002_usage.sql"),
      "utf8",
    );
    expect(tablesDeclaredIn(sql)).toEqual(["usage_visits", "usage_screens"]);
  });

  test("flags 0002 when remote only has 0001", async () => {
    const local = await readLocalMigrations(join(repoRoot(), "worker", "migrations"));
    const diff = diffMigrations(
      local,
      ["0001_schema.sql"],
      ["feedback", "tips", "inboxes", "ingest_keys", "readings", "rate_limits"],
    );
    expect(diff.pending).toContain("0002_usage.sql");
    expect(diff.missing).toEqual(["usage_visits", "usage_screens"]);
  });
});
