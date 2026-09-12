import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  MAX_BODY_BYTES,
  readJSONBody,
  requireJSONContentType,
} from "../src/http.ts";

describe("requireJSONContentType", () => {
  it("rejects a missing content-type so HTML forms cannot mint inboxes", async () => {
    const rejected = requireJSONContentType(new Request("https://api.tollcat.app/v1/inbox", { method: "POST" }));
    assert.ok(rejected);
    assert.equal(rejected.status, 415);
  });

  it("rejects text/plain", async () => {
    const rejected = requireJSONContentType(
      new Request("https://api.tollcat.app/v1/inbox", {
        method: "POST",
        headers: { "content-type": "text/plain" },
      }),
    );
    assert.ok(rejected);
    assert.equal(rejected.status, 415);
  });

  it("accepts application/json with a charset", () => {
    const rejected = requireJSONContentType(
      new Request("https://api.tollcat.app/v1/feedback", {
        method: "POST",
        headers: { "content-type": "application/json; charset=utf-8" },
        body: "{}",
      }),
    );
    assert.equal(rejected, null);
  });
});

describe("readJSONBody", () => {
  it("caps the body at 8KiB before JSON.parse", async () => {
    assert.equal(MAX_BODY_BYTES, 8 * 1024);
    const oversized = "x".repeat(MAX_BODY_BYTES + 1);
    const result = await readJSONBody(
      new Request("https://api.tollcat.app/v1/feedback", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: oversized,
      }),
    );
    assert.ok(result instanceof Response);
    assert.equal(result.status, 413);
  });

  it("parses a small JSON object", async () => {
    const result = await readJSONBody(
      new Request("https://api.tollcat.app/v1/feedback", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ message: "hi" }),
      }),
    );
    assert.ok(!(result instanceof Response));
    assert.deepEqual(result, { message: "hi" });
  });
});
