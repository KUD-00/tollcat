import {
  USAGE_COUNT_MAX,
  USAGE_PLATFORMS,
  USAGE_SCREENS,
  USAGE_SCREENS_MAX,
  USAGE_VERSION_MAX,
} from "./contract";
import { asNonEmptyString, asString, clamp, guardedPostBody, isResponse, json } from "./http";

/// 正常使用是几秒攒一批。10 分钟 120 次已经远超手点页面。
const RATE_WINDOW_SEC = 600;
const RATE_LIMIT = 120;

interface UsageBody {
  platform?: unknown;
  appVersion?: unknown;
  newVisit?: unknown;
  screens?: unknown;
}

interface ScreenCount {
  id: string;
  n: number;
}

export async function handleUsage(request: Request, db: D1Database): Promise<Response> {
  const parsed = await guardedPostBody(request, db, "usage", RATE_WINDOW_SEC, RATE_LIMIT);
  if (isResponse(parsed)) return parsed;

  const body = parsed as UsageBody;
  const platform = asNonEmptyString(body.platform);
  if (!platform || !USAGE_PLATFORMS.has(platform)) {
    return json({ error: "platform must be ios, android, macos, or windows" }, 400);
  }

  // appVersion 只校验长度，不入库。带上是给以后看版本存活，现在计数不按版本切。
  clamp(asString(body.appVersion), USAGE_VERSION_MAX);

  const newVisit = body.newVisit === true;
  const screens = parseScreens(body.screens);
  if (screens === null) {
    return json({ error: "screens must be an array of {id, n}" }, 400);
  }
  if (!newVisit && screens.length === 0) {
    return json({ ok: true }, 200);
  }

  const day = utcDay(new Date());
  const statements: D1PreparedStatement[] = [];
  if (newVisit) {
    statements.push(
      db
        .prepare(
          `INSERT INTO usage_visits (day, platform, visits) VALUES (?1, ?2, 1)
           ON CONFLICT(day, platform) DO UPDATE SET visits = visits + 1`
        )
        .bind(day, platform)
    );
  }
  for (const screen of screens) {
    statements.push(
      db
        .prepare(
          `INSERT INTO usage_screens (day, platform, screen, views) VALUES (?1, ?2, ?3, ?4)
           ON CONFLICT(day, platform, screen) DO UPDATE SET views = views + excluded.views`
        )
        .bind(day, platform, screen.id, screen.n)
    );
  }
  if (statements.length > 0) {
    await db.batch(statements);
  }
  return json({ ok: true }, 200);
}

/// 未知页面丢掉、合法的留下。整段不是数组才算坏请求。
function parseScreens(value: unknown): ScreenCount[] | null {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) return null;
  const screens: ScreenCount[] = [];
  for (const item of value.slice(0, USAGE_SCREENS_MAX)) {
    if (!item || typeof item !== "object") continue;
    const row = item as { id?: unknown; n?: unknown };
    const id = asNonEmptyString(row.id);
    if (!id || !USAGE_SCREENS.has(id)) continue;
    const n = asCount(row.n);
    if (n === null) continue;
    screens.push({ id, n });
  }
  return screens;
}

function asCount(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isInteger(value)) return null;
  if (value < 1 || value > USAGE_COUNT_MAX) return null;
  return value;
}

function utcDay(date: Date): string {
  return date.toISOString().slice(0, 10);
}
