import { TIP_MESSAGE_MAX, TIP_NAME_MAX } from "./contract";
import { asNonEmptyString, asString, clamp, guardedPostBody, isResponse, json } from "./http";
const RATE_WINDOW_SEC = 600;
const RATE_LIMIT = 20;

interface TipBody {
  transactionID?: unknown;
  jws?: unknown;
  productID?: unknown;
  displayPrice?: unknown;
  name?: unknown;
  message?: unknown;
  appVersion?: unknown;
}

export async function handleTip(request: Request, db: D1Database): Promise<Response> {
  const parsed = await guardedPostBody(request, db, "tip", RATE_WINDOW_SEC, RATE_LIMIT);
  if (isResponse(parsed)) return parsed;

  const body = parsed as TipBody;
  const transactionID = asNonEmptyString(body.transactionID);
  const productID = asNonEmptyString(body.productID);
  if (!transactionID || !productID) {
    return json({ error: "transactionID and productID are required" }, 400);
  }

  // JWS 这轮存而不验。不验的风险：有人可以伪造打赏留言
  // （transactionID / name / message），但拿不到钱，最坏是垃圾留言。
  // 以后补 StoreKit 签名校验时，这里用存下来的 jws 原样验。
  //
  // INSERT OR IGNORE：POST 超时重发不会变成两条，重复直接幂等成功。
  await db
    .prepare(
      `INSERT OR IGNORE INTO tips (
        transaction_id, product_id, display_price, name, message, app_version, jws, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(
      transactionID,
      productID,
      asString(body.displayPrice) ?? "",
      clamp(asString(body.name), TIP_NAME_MAX),
      clamp(asString(body.message), TIP_MESSAGE_MAX),
      asString(body.appVersion) ?? "",
      asString(body.jws) ?? "",
      new Date().toISOString()
    )
    .run();

  return json({ ok: true }, 200);
}
