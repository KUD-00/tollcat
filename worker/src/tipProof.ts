/// 打赏凭证和请求体对不对得上。这**不是**签名校验——StoreKit x5c 证书链和
/// Play 的 RSA 签名都还没验——只挡两种最便宜的伪造：空凭证，以及凭证里写的
/// 交易 / 商品和请求体声称的不是同一笔。空凭证的行以后补上签名校验也验不了。
///
/// 两种客户端两种形态：
/// - iOS：StoreKit 2 `jwsRepresentation`，`header.payload.signature`，payload 里有
///   `transactionId` / `productId`；
/// - Android：`{"signature": …, "signedData": <Play originalJson>}`，originalJson 里有
///   `purchaseToken`（就是请求里的 transactionID）/ `productId`。
export function tipProofMatches(proof: string, transactionID: string, productID: string): boolean {
  if (!proof) return false;
  const segments = proof.split(".");
  if (segments.length === 3) {
    const payload = decodeJSON(base64URLDecode(segments[1]));
    return (
      payload !== null &&
      String(payload.transactionId ?? "") === transactionID &&
      payload.productId === productID
    );
  }
  const wrapper = decodeJSON(proof);
  if (wrapper === null || typeof wrapper.signature !== "string" || !wrapper.signature) return false;
  if (typeof wrapper.signedData !== "string") return false;
  const purchase = decodeJSON(wrapper.signedData);
  return purchase !== null && purchase.purchaseToken === transactionID && purchase.productId === productID;
}

function decodeJSON(text: string | null): Record<string, unknown> | null {
  if (text === null) return null;
  try {
    const value: unknown = JSON.parse(text);
    return value !== null && typeof value === "object" && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}

function base64URLDecode(segment: string): string | null {
  if (!/^[A-Za-z0-9_-]*$/.test(segment)) return null;
  const padded = segment.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(segment.length / 4) * 4, "=");
  try {
    const binary = atob(padded);
    const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    return null;
  }
}
