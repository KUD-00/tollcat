import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { tipProofMatches } from "../src/tipProof.ts";

const b64url = (value: unknown) => Buffer.from(JSON.stringify(value)).toString("base64url");
const jws = (payload: unknown) => `${b64url({ alg: "ES256" })}.${b64url(payload)}.sig`;

describe("tipProofMatches", () => {
  it("accepts a StoreKit JWS naming the same transaction and product", () => {
    assert.equal(tipProofMatches(jws({ transactionId: "2000001", productId: "tip.small" }), "2000001", "tip.small"), true);
  });
  it("rejects a StoreKit JWS for another transaction or product", () => {
    assert.equal(tipProofMatches(jws({ transactionId: "2000002", productId: "tip.small" }), "2000001", "tip.small"), false);
    assert.equal(tipProofMatches(jws({ transactionId: "2000001", productId: "tip.large" }), "2000001", "tip.small"), false);
  });
  it("accepts a Play purchase wrapper naming the same token and product", () => {
    const proof = JSON.stringify({ signature: "c2ln", signedData: JSON.stringify({ purchaseToken: "tok", productId: "tip.small" }) });
    assert.equal(tipProofMatches(proof, "tok", "tip.small"), true);
  });
  it("rejects a Play wrapper without a signature or with another token", () => {
    const unsigned = JSON.stringify({ signature: "", signedData: JSON.stringify({ purchaseToken: "tok", productId: "tip.small" }) });
    const other = JSON.stringify({ signature: "c2ln", signedData: JSON.stringify({ purchaseToken: "x", productId: "tip.small" }) });
    assert.equal(tipProofMatches(unsigned, "tok", "tip.small"), false);
    assert.equal(tipProofMatches(other, "tok", "tip.small"), false);
  });
  it("rejects empty and garbage proofs", () => {
    for (const proof of ["", "preview-jws", "a.b.c", "{}", "[]", "a.!!.c"]) {
      assert.equal(tipProofMatches(proof, "tok", "tip.small"), false, proof);
    }
  });
});
