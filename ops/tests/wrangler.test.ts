import { describe, expect, test } from "bun:test";
import { parseWranglerJSON } from "../src/wrangler";

describe("parseWranglerJSON", () => {
  test("reads a D1 result array", () => {
    const parsed = parseWranglerJSON<Array<{ results: Array<{ n: number }> }>>(
      `[\n  {\n    "results": [{ "n": 1 }],\n    "success": true\n  }\n]\n`,
    );
    expect(parsed[0]?.results[0]?.n).toBe(1);
  });

  test("skips wrangler banners before the first bracket", () => {
    const parsed = parseWranglerJSON<{ loggedIn: boolean }>(
      "⛅️ wrangler 4.127.1\n────────────────────\n{\"loggedIn\":true}\n",
    );
    expect(parsed.loggedIn).toBe(true);
  });

  test("throws when there is no JSON", () => {
    expect(() => parseWranglerJSON("not json")).toThrow(/没有返回 JSON/);
  });
});
