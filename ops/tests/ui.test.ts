import { describe, expect, test } from "bun:test";
import { windowed } from "../src/ui";

describe("windowed", () => {
  test("keeps the selected row in view", () => {
    const rows = [...Array(20).keys()];
    expect(windowed(rows, 0, 5)).toEqual({ start: 0, visible: [0, 1, 2, 3, 4] });
    expect(windowed(rows, 19, 5).visible).toEqual([15, 16, 17, 18, 19]);
    expect(windowed(rows, 10, 5).visible).toContain(10);
  });
});
