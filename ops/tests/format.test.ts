import { describe, expect, test } from "bun:test";
import {
  categoryLabel,
  firstLine,
  normalizeTimestamp,
  relativeTime,
  tipSizeLabel,
  truncate,
} from "../src/format";

describe("format", () => {
  test("relativeTime", () => {
    const now = new Date("2026-08-31T12:00:00Z");
    expect(relativeTime("2026-08-31T11:59:30Z", now)).toBe("刚刚");
    expect(relativeTime("2026-08-31T11:10:00Z", now)).toBe("50 分钟前");
    expect(relativeTime("2026-08-31T09:00:00Z", now)).toBe("3 小时前");
    expect(relativeTime("2026-08-26T11:02:02.311Z", now)).toBe("5 天前");
    expect(relativeTime("2026-08-25 03:21:04", now)).toBe("6 天前");
  });

  test("normalizeTimestamp treats D1 migration stamps as UTC", () => {
    expect(normalizeTimestamp("2026-08-25 03:21:04")).toBe("2026-08-25T03:21:04Z");
  });

  test("labels and truncate", () => {
    expect(categoryLabel("bug")).toBe("缺陷");
    expect(tipSizeLabel("com.zhechengqi.tollcat.tip.medium")).toBe("中档");
    expect(firstLine("site-form smoke test, ignore")).toBe("site-form smoke test, ignore");
    expect(truncate("abcdefghij", 6)).toBe("abcde…");
  });
});
