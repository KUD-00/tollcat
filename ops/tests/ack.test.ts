import { describe, expect, test } from "bun:test";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { loadAck, saveAck, toggleAck } from "../src/ack";

describe("ack store", () => {
  test("round-trips keys and keeps original timestamps", async () => {
    const dir = await mkdtemp(join(tmpdir(), "tollcat-ops-"));
    const path = join(dir, "ops-ack.json");
    const first = toggleAck(new Set(), "feedback:fb-1");
    await saveAck(first, path, new Date("2026-08-31T00:00:00Z"));
    const loaded = await loadAck(path);
    expect(loaded.has("feedback:fb-1")).toBe(true);

    const second = toggleAck(loaded, "tip:1");
    await saveAck(second, path, new Date("2026-08-31T01:00:00Z"));
    const stored = (await Bun.file(path).json()) as {
      items: Record<string, string>;
    };
    expect(stored.items["feedback:fb-1"]).toBe("2026-08-31T00:00:00.000Z");
    expect(stored.items["tip:1"]).toBe("2026-08-31T01:00:00.000Z");
  });

  test("missing file is empty", async () => {
    const loaded = await loadAck("/tmp/tollcat-ops-does-not-exist.json");
    expect(loaded.size).toBe(0);
  });
});
