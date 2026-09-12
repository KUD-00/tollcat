import { describe, expect, test } from "bun:test";
import { parseArgs } from "../src/args";

describe("parseArgs", () => {
  test("defaults to the queue TUI", () => {
    expect(parseArgs([])).toEqual({
      json: false,
      help: false,
      once: false,
      section: "queue",
    });
  });

  test("accepts json, once, section aliases", () => {
    expect(parseArgs(["--json", "--once", "--section", "反馈"])).toEqual({
      json: true,
      help: false,
      once: true,
      section: "feedback",
    });
  });

  test("rejects unknown flags", () => {
    expect(() => parseArgs(["--wat"])).toThrow(/不认识/);
  });
});
