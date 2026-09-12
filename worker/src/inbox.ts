import {
  asNonEmptyString,
  clamp,
  isRateLimited,
  isResponse,
  json,
  methodNotAllowed,
  readJSONBody,
  requireJSONContentType,
} from "./http";

/// 两把 key 的前缀。写死是为了泄露时能被 secret scanner 抓到，
/// 也方便用户一眼分清哪把该放进脚本。
const READ_KEY_PREFIX = "tollr_";
const INGEST_KEY_PREFIX = "tolli_";

const MAX_INGEST_KEYS_PER_INBOX = 16;
const LABEL_MAX = 40;
const CREATE_WINDOW_SEC = 3600;
const CREATE_LIMIT = 5;
const INGEST_WINDOW_SEC = 600;
const INGEST_LIMIT = 120;

/// 服务端不认识 provider 清单——App 才是那份清单的权威。
/// 这里只保证它是个能安全落库和回显的短标识。
const PROVIDER_PATTERN = /^[a-z0-9][a-z0-9-]{0,31}$/;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
/// 十进制字符串。收下来原样存，绝不 parseFloat。
const AMOUNT_PATTERN = /^-?\d{1,9}(\.\d{1,6})?$/;

const INGEST_KEYS_PATH = /^\/v1\/inbox\/ingest-keys(?:\/([A-Za-z0-9_-]{1,64}))?$/;

export async function handleInbox(request: Request, db: D1Database): Promise<Response> {
  const pathname = new URL(request.url).pathname;
  if (pathname === "/v1/inbox") {
    if (request.method === "POST") return createInbox(request, db);
    if (request.method === "DELETE") return deleteInbox(request, db);
    return methodNotAllowed("POST, DELETE");
  }

  const keyMatch = INGEST_KEYS_PATH.exec(pathname);
  if (keyMatch) {
    const keyID = keyMatch[1];
    if (keyID) {
      if (request.method !== "DELETE") return methodNotAllowed("DELETE");
      return revokeIngestKey(request, db, keyID);
    }
    if (request.method === "GET") return listIngestKeys(request, db);
    if (request.method === "POST") return mintIngestKey(request, db);
    return methodNotAllowed("GET, POST");
  }

  if (pathname === "/v1/readings") {
    if (request.method === "POST") return postReading(request, db);
    if (request.method === "GET") return listReadings(request, db);
    return methodNotAllowed("GET, POST");
  }
  return json({ error: "not found" }, 404);
}

// MARK: - 信箱

async function createInbox(request: Request, db: D1Database): Promise<Response> {
  // 无鉴权的入口。卡 application/json 让它不再是 simple request——
  // 跨站表单没法带这个 content-type，也过不了预检（本路径不放预检），
  // 就烧不掉受害者 IP 的建箱配额。App 侧 InboxClient 对所有 POST 都带
  // application/json 的空对象体，正好对上。
  const rejected = requireJSONContentType(request);
  if (rejected) return rejected;

  const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
  if (await isRateLimited(db, `inbox-create:${ip}`, CREATE_WINDOW_SEC, CREATE_LIMIT)) {
    return json({ error: "rate limited" }, 429);
  }

  const id = randomToken("");
  const readKey = randomToken(READ_KEY_PREFIX);
  const now = new Date().toISOString();

  await db
    .prepare("INSERT INTO inboxes (id, read_key_hash, created_at) VALUES (?, ?, ?)")
    .bind(id, await sha256(readKey), now)
    .run();

  const first = await insertIngestKey(db, id, "默认", now);

  // 两把 key 只在这一次返回。之后服务端只有哈希，找不回来只能再签一把。
  return json(
    { mailbox: id, readKey, ingestKey: first.key, ingestKeyID: first.id },
    201
  );
}

async function deleteInbox(request: Request, db: D1Database): Promise<Response> {
  const inboxID = await authenticateRead(request, db);
  if (isResponse(inboxID)) return inboxID;

  await db.prepare("DELETE FROM readings WHERE inbox_id = ?").bind(inboxID).run();
  await db.prepare("DELETE FROM ingest_keys WHERE inbox_id = ?").bind(inboxID).run();
  await db.prepare("DELETE FROM inboxes WHERE id = ?").bind(inboxID).run();
  return json({ ok: true }, 200);
}

// MARK: - 投递 key

interface MintBody {
  label?: unknown;
}

/// 签一把新的。**不吊销任何旧的**——轮换是「先签新的、改完脚本、再吊销旧的」，
/// 中间那段两把都能用，不会改到一半全断。
async function mintIngestKey(request: Request, db: D1Database): Promise<Response> {
  const inboxID = await authenticateRead(request, db);
  if (isResponse(inboxID)) return inboxID;

  const existing = await db
    .prepare("SELECT COUNT(*) AS n FROM ingest_keys WHERE inbox_id = ?")
    .bind(inboxID)
    .first<{ n: number }>();
  if ((existing?.n ?? 0) >= MAX_INGEST_KEYS_PER_INBOX) {
    return json({ error: "too many ingest keys" }, 409);
  }

  const parsed = await readJSONBody(request);
  if (isResponse(parsed)) return parsed;
  const label = clamp(asNonEmptyString((parsed as MintBody).label), LABEL_MAX);

  const minted = await insertIngestKey(db, inboxID, label, new Date().toISOString());
  return json({ ingestKey: minted.key, ingestKeyID: minted.id }, 201);
}

/// 只回元数据，永远不回 key 本身——服务端也没有，只有哈希。
async function listIngestKeys(request: Request, db: D1Database): Promise<Response> {
  const inboxID = await authenticateRead(request, db);
  if (isResponse(inboxID)) return inboxID;

  const rows = await db
    .prepare(
      `SELECT id, label, created_at, last_used_at FROM ingest_keys
       WHERE inbox_id = ? ORDER BY created_at`
    )
    .bind(inboxID)
    .all<{ id: string; label: string | null; created_at: string; last_used_at: string | null }>();

  return json(
    {
      keys: (rows.results ?? []).map((row) => ({
        id: row.id,
        label: row.label,
        createdAt: row.created_at,
        lastUsedAt: row.last_used_at,
      })),
    },
    200
  );
}

async function revokeIngestKey(
  request: Request,
  db: D1Database,
  keyID: string
): Promise<Response> {
  const inboxID = await authenticateRead(request, db);
  if (isResponse(inboxID)) return inboxID;

  const result = await db
    .prepare("DELETE FROM ingest_keys WHERE id = ? AND inbox_id = ?")
    .bind(keyID, inboxID)
    .run();
  if ((result.meta.changes ?? 0) === 0) {
    return json({ error: "unknown ingest key" }, 404);
  }
  return json({ ok: true }, 200);
}

async function insertIngestKey(
  db: D1Database,
  inboxID: string,
  label: string | null,
  now: string
): Promise<{ id: string; key: string }> {
  const id = randomToken("");
  const key = randomToken(INGEST_KEY_PREFIX);
  await db
    .prepare(
      `INSERT INTO ingest_keys (id, inbox_id, key_hash, label, created_at)
       VALUES (?, ?, ?, ?, ?)`
    )
    .bind(id, inboxID, await sha256(key), label, now)
    .run();
  return { id, key };
}

// MARK: - 读数

interface ReadingBody {
  provider?: unknown;
  periodStart?: unknown;
  currentSpendUSD?: unknown;
}

async function postReading(request: Request, db: D1Database): Promise<Response> {
  const auth = await authenticateIngest(request, db);
  if (isResponse(auth)) return auth;

  if (await isRateLimited(db, `ingest:${auth.inboxID}`, INGEST_WINDOW_SEC, INGEST_LIMIT)) {
    return json({ error: "rate limited" }, 429);
  }

  const parsed = await readJSONBody(request);
  if (isResponse(parsed)) return parsed;
  const body = parsed as ReadingBody;

  const provider = asNonEmptyString(body.provider);
  const periodStart = asNonEmptyString(body.periodStart);
  const amount = asNonEmptyString(body.currentSpendUSD);

  if (!provider || !PROVIDER_PATTERN.test(provider)) {
    return json({ error: "provider must match [a-z0-9-]{1,32}" }, 400);
  }
  if (!periodStart || !DATE_PATTERN.test(periodStart)) {
    return json({ error: "periodStart must be YYYY-MM-DD" }, 400);
  }
  // currentSpendUSD 是「本月至今累计」，不是「今天花了多少」。
  // 以后要加日粒度就在 /v1 之上另开字段，别改这一个的含义。
  if (!amount || !AMOUNT_PATTERN.test(amount)) {
    return json({ error: "currentSpendUSD must be a decimal string" }, 400);
  }

  const now = new Date().toISOString();
  await db.batch([
    db
      .prepare(
        `INSERT INTO readings (inbox_id, ingest_key_id, provider, period_start, current_spend_usd, reported_at)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(ingest_key_id) DO UPDATE SET
           provider = excluded.provider,
           period_start = excluded.period_start,
           current_spend_usd = excluded.current_spend_usd,
           reported_at = excluded.reported_at`
      )
      .bind(auth.inboxID, auth.keyID, provider, periodStart, amount, now),
    // 记一下这把 key 还活着，界面上才能提示「这把 30 天没用过了，吊销吧」。
    db.prepare("UPDATE ingest_keys SET last_used_at = ? WHERE id = ?").bind(now, auth.keyID),
  ]);

  return json({ ok: true }, 200);
}

async function listReadings(request: Request, db: D1Database): Promise<Response> {
  const inboxID = await authenticateRead(request, db);
  if (isResponse(inboxID)) return inboxID;

  const rows = await db
    .prepare(
      `SELECT ingest_key_id, provider, period_start, current_spend_usd, reported_at
       FROM readings WHERE inbox_id = ? ORDER BY provider`
    )
    .bind(inboxID)
    .all<{
      ingest_key_id: string;
      provider: string;
      period_start: string;
      current_spend_usd: string | null;
      reported_at: string;
    }>();

  return json(
    {
      readings: (rows.results ?? []).map((row) => ({
        ingestKeyID: row.ingest_key_id,
        provider: row.provider,
        periodStart: row.period_start,
        currentSpendUSD: row.current_spend_usd,
        reportedAt: row.reported_at,
      })),
    },
    200
  );
}

// MARK: - 鉴权

/// 只存哈希，所以直接按哈希查行——不需要取出来再比，也就没有时序比较的问题。
function bearer(request: Request, expectedPrefix: string): string | Response {
  const header = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  if (!match) {
    return json({ error: "missing bearer token" }, 401);
  }
  const token = match[1].trim();
  if (!token.startsWith(expectedPrefix)) {
    // 用错了 key 要给出明确信号：投递 key 读不了数，读 key 也投不了。
    return json({ error: `token must start with ${expectedPrefix}` }, 403);
  }
  return token;
}

/// 成功时返回信箱 id。
async function authenticateRead(request: Request, db: D1Database): Promise<string | Response> {
  const token = bearer(request, READ_KEY_PREFIX);
  if (isResponse(token)) return token;

  const row = await db
    .prepare("SELECT id FROM inboxes WHERE read_key_hash = ?")
    .bind(await sha256(token))
    .first<{ id: string }>();
  if (!row) {
    return json({ error: "unknown token" }, 401);
  }
  return row.id;
}

async function authenticateIngest(
  request: Request,
  db: D1Database
): Promise<{ inboxID: string; keyID: string } | Response> {
  const token = bearer(request, INGEST_KEY_PREFIX);
  if (isResponse(token)) return token;

  const row = await db
    .prepare("SELECT id, inbox_id FROM ingest_keys WHERE key_hash = ?")
    .bind(await sha256(token))
    .first<{ id: string; inbox_id: string }>();
  if (!row) {
    return json({ error: "unknown token" }, 401);
  }
  return { inboxID: row.inbox_id, keyID: row.id };
}

// MARK: - 工具

function randomToken(prefix: string): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return prefix + base64url(bytes);
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function base64url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
