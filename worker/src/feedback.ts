import {
  FEEDBACK_CATEGORIES,
  FEEDBACK_CONTACT_MAX,
  FEEDBACK_DEVICE_MAX,
  FEEDBACK_EXCHANGE_MAX,
  FEEDBACK_LOCALE_MAX,
  FEEDBACK_MESSAGE_MAX,
  FEEDBACK_PROVIDERS_MAX,
  FEEDBACK_VERSION_MAX,
} from "./contract";
import { asNonEmptyString, asString, clamp, guardedPostBody, isResponse, json } from "./http";

/// 反馈比打赏更容易被灌。10 分钟 5 条：正常人一次提一条，
/// 连提五条已经是「写完发现漏了再补」的上限。
const RATE_WINDOW_SEC = 600;
const RATE_LIMIT = 5;

/// 不认的值一律落成 other，而不是 400 ——
/// 老版本 App 发来一个新类别时，反馈本身比分类重要。

interface FeedbackBody {
  id?: unknown;
  category?: unknown;
  message?: unknown;
  contact?: unknown;
  appVersion?: unknown;
  osVersion?: unknown;
  locale?: unknown;
  deviceModel?: unknown;
  providers?: unknown;
  exchange?: unknown;
}

export async function handleFeedback(request: Request, db: D1Database): Promise<Response> {
  const parsed = await guardedPostBody(request, db, "feedback", RATE_WINDOW_SEC, RATE_LIMIT);
  if (isResponse(parsed)) return parsed;

  const body = parsed as FeedbackBody;
  const id = asNonEmptyString(body.id);
  const message = clamp(asString(body.message), FEEDBACK_MESSAGE_MAX);
  if (!id || !message) {
    return json({ error: "id and message are required" }, 400);
  }

  const rawCategory = asNonEmptyString(body.category) ?? "other";
  const category = FEEDBACK_CATEGORIES.has(rawCategory) ? rawCategory : "other";

  // INSERT OR IGNORE：POST 超时重发不会变成两条，重复直接幂等成功。
  await db
    .prepare(
      `INSERT OR IGNORE INTO feedback (
        id, category, message, contact,
        app_version, os_version, locale, device_model, providers, exchange, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(
      id,
      category,
      message,
      clamp(asString(body.contact), FEEDBACK_CONTACT_MAX),
      clamp(asString(body.appVersion), FEEDBACK_VERSION_MAX) ?? "",
      clamp(asString(body.osVersion), FEEDBACK_VERSION_MAX) ?? "",
      clamp(asString(body.locale), FEEDBACK_LOCALE_MAX) ?? "",
      clamp(asString(body.deviceModel), FEEDBACK_DEVICE_MAX),
      providerList(body.providers),
      clamp(asString(body.exchange), FEEDBACK_EXCHANGE_MAX),
      new Date().toISOString()
    )
    .run();

  return json({ ok: true }, 200);
}

/// 只收字符串数组，逗号拼平。任何一项不是字符串就整段丢掉——
/// 这一列纯属诊断辅助，宁可没有也不要半截脏数据。
function providerList(value: unknown): string | null {
  if (!Array.isArray(value) || value.length === 0) return null;
  if (!value.every((item) => typeof item === "string")) return null;
  const names = value
    .map((item) => (item as string).trim())
    .filter((item) => item.length > 0);
  if (names.length === 0) return null;
  return clamp(names.join(","), FEEDBACK_PROVIDERS_MAX);
}
