export const MAX_BODY_BYTES = 8 * 1024;

export function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

export function methodNotAllowed(allow: string): Response {
  return new Response("Method Not Allowed", { status: 405, headers: { Allow: allow } });
}

/// HTML 表单和 no-cors fetch 只能发 text/plain 一类的 simple request，
/// 卡住 application/json 就把跨站伪造挡在预检外面（本 Worker 只给
/// /v1/feedback 放预检）。无体的 POST（如建信箱）也用它。
export function requireJSONContentType(request: Request): Response | null {
  const contentType = request.headers.get("content-type") ?? "";
  if (!contentType.toLowerCase().startsWith("application/json")) {
    return json({ error: "content-type must be application/json" }, 415);
  }
  return null;
}

/// 读 JSON 体，同时把 content-type 和体积卡住。
/// 返回 Response 表示已经出错，调用方直接原样返回。
export async function readJSONBody(request: Request): Promise<unknown | Response> {
  const rejected = requireJSONContentType(request);
  if (rejected) return rejected;
  const declared = Number(request.headers.get("content-length") ?? "0");
  if (declared > MAX_BODY_BYTES) {
    return json({ error: "payload too large" }, 413);
  }
  // 声明长度可以缺席或撒谎（h2 / chunked），所以边读边数、超限立断，
  // 不把整个 body 先吞进内存再量。
  const raw = await readBodyCapped(request);
  if (isResponse(raw)) return raw;
  try {
    return JSON.parse(raw) as unknown;
  } catch {
    return json({ error: "invalid json" }, 400);
  }
}

async function readBodyCapped(request: Request): Promise<string | Response> {
  if (!request.body) return "";
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > MAX_BODY_BYTES) {
      await reader.cancel();
      return json({ error: "payload too large" }, 413);
    }
    chunks.push(value);
  }
  const merged = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    merged.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(merged);
}

export function isResponse(value: unknown): value is Response {
  return value instanceof Response;
}

export function asString(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

export function asNonEmptyString(value: unknown): string | null {
  const text = asString(value);
  if (!text) return null;
  const trimmed = text.trim();
  return trimmed.length === 0 ? null : trimmed;
}

export function clamp(value: string | null, limit: number): string | null {
  if (!value) return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  return trimmed.slice(0, limit);
}

/// 滑动窗口限流。bucket 由调用方拼（`tip:<ip>`、`ingest:<inbox>`），
/// 这样打赏和投递互不挤占额度。
///
/// 单条 upsert：窗口过期就重开（count 归 1），否则自增，RETURNING 拿回
/// 自增后的值。一次 D1 往返，并发请求也不会各自读到旧 count 而超额放行。
/// SET 的右侧按 SQL 语义一律读更新前的行，所以两个 CASE 看到的是同一个
/// window_start。
export async function isRateLimited(
  db: D1Database,
  bucket: string,
  windowSeconds: number,
  limit: number
): Promise<boolean> {
  const now = Math.floor(Date.now() / 1000);
  const row = await db
    .prepare(
      `INSERT INTO rate_limits (bucket, window_start, count) VALUES (?1, ?2, 1)
       ON CONFLICT(bucket) DO UPDATE SET
         count        = CASE WHEN ?2 - window_start >= ?3 THEN 1  ELSE count + 1    END,
         window_start = CASE WHEN ?2 - window_start >= ?3 THEN ?2 ELSE window_start END
       RETURNING count`
    )
    .bind(bucket, now, windowSeconds)
    .first<{ count: number }>();
  return (row?.count ?? 1) > limit;
}

/// POST endpoint 的公共前奏：method 检查 → 按 IP 限流 → 读 JSON 体。
/// 限流放在碰 body 之前：坏 JSON、超大 body 也计进同一个桶，
/// 刷废请求和刷好请求一样烧额度。
/// 返回 Response 表示已经出错，调用方直接原样返回；否则返回解析好的 body。
export async function guardedPostBody(
  request: Request,
  db: D1Database,
  bucket: string,
  windowSeconds: number,
  limit: number
): Promise<unknown | Response> {
  if (request.method !== "POST") {
    return methodNotAllowed("POST");
  }
  const rejected = requireJSONContentType(request);
  if (rejected) return rejected;
  const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
  if (await isRateLimited(db, `${bucket}:${ip}`, windowSeconds, limit)) {
    return json({ error: "rate limited" }, 429);
  }
  return readJSONBody(request);
}
