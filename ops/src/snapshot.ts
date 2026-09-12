import { join } from "node:path";
import { diffMigrations, readLocalMigrations } from "./migrations";
import { repoRoot, siteDir, workerDir } from "./paths";
import type {
  AppliedMigration,
  D1Result,
  FeedbackRow,
  InboxRow,
  RateLimitRow,
  ReadingRow,
  ScreenRow,
  Snapshot,
  TipRow,
  VisitRow,
} from "./types";
import { makeRunner, wranglerJSON, type Runner } from "./wrangler";

type Whoami = {
  loggedIn?: boolean;
  email?: string;
  accounts?: Array<{ id: string; name: string }>;
};

type Deployment = {
  created_on?: string;
};

type RawFeedback = {
  id: string;
  category: string;
  message: string;
  contact: string | null;
  app_version: string;
  os_version: string;
  locale: string;
  device_model: string | null;
  providers: string | null;
  exchange: string | null;
  created_at: string;
};

type RawTip = {
  transaction_id: string;
  product_id: string;
  display_price: string;
  name: string | null;
  message: string | null;
  app_version: string;
  created_at: string;
};

type RawCounts = {
  inboxes: number;
  ingest_keys: number;
  readings: number;
};

type RawInbox = {
  inbox_id: string;
  inbox_created_at: string;
  keys: number;
  readings: number;
  last_reading_at: string | null;
};

type RawReading = {
  provider: string;
  period_start: string;
  current_spend_usd: string | null;
  reported_at: string;
};

type RawMigration = {
  name: string;
  applied_at: string;
};

type RawTable = { name: string };

type RawRate = {
  bucket: string;
  window_start: number;
  count: number;
};

type RawVisit = { day: string; platform: string; visits: number };
type RawScreen = { day: string; platform: string; screen: string; views: number };

const CORE_SQL = [
  `SELECT id, category, message, contact, app_version, os_version, locale, device_model, providers, exchange, created_at
   FROM feedback ORDER BY created_at DESC LIMIT 200`,
  `SELECT transaction_id, product_id, display_price, name, message, app_version, created_at
   FROM tips ORDER BY created_at DESC LIMIT 200`,
  `SELECT
     (SELECT COUNT(*) FROM inboxes) AS inboxes,
     (SELECT COUNT(*) FROM ingest_keys) AS ingest_keys,
     (SELECT COUNT(*) FROM readings) AS readings`,
  `SELECT i.id AS inbox_id, i.created_at AS inbox_created_at,
     (SELECT COUNT(*) FROM ingest_keys k WHERE k.inbox_id = i.id) AS keys,
     (SELECT COUNT(*) FROM readings r WHERE r.inbox_id = i.id) AS readings,
     (SELECT MAX(reported_at) FROM readings r WHERE r.inbox_id = i.id) AS last_reading_at
   FROM inboxes i
   ORDER BY i.created_at DESC
   LIMIT 50`,
  `SELECT provider, period_start, current_spend_usd, reported_at
   FROM readings
   ORDER BY reported_at DESC
   LIMIT 50`,
  `SELECT name, applied_at FROM d1_migrations ORDER BY id`,
  `SELECT name FROM sqlite_master WHERE type='table' ORDER BY name`,
  `SELECT bucket, window_start, count FROM rate_limits ORDER BY window_start DESC LIMIT 40`,
].join(";\n");

const USAGE_SQL = [
  `SELECT day, platform, visits FROM usage_visits
   WHERE day >= date('now', '-30 day') ORDER BY day DESC, platform`,
  `SELECT day, platform, screen, views FROM usage_screens
   WHERE day >= date('now', '-7 day') ORDER BY day DESC, views DESC LIMIT 80`,
].join(";\n");

export async function fetchSnapshot(options?: {
  root?: string;
  runner?: Runner;
  now?: Date;
}): Promise<Snapshot> {
  const root = options?.root ?? repoRoot();
  const run = options?.runner ?? makeRunner(root);
  const worker = workerDir(root);
  const site = siteDir(root);
  const now = options?.now ?? new Date();
  const warnings: string[] = [];

  const [whoami, core, workerDeployedAt, siteDeployedAt, localMigrations] =
    await Promise.all([
      loadWhoami(run, worker),
      loadD1<unknown[]>(run, worker, CORE_SQL),
      loadLatestDeploy(run, worker, undefined, warnings),
      loadLatestDeploy(run, site, "tollcat-site", warnings),
      readLocalMigrations(join(worker, "migrations")),
    ]);

  const [
    feedbackRaw,
    tipsRaw,
    countsRaw,
    boxesRaw,
    readingsRaw,
    migrationsRaw,
    tablesRaw,
    ratesRaw,
  ] = asResults(core, 8);

  const tables = rows<RawTable>(tablesRaw).map((row) => row.name);
  const applied = rows<RawMigration>(migrationsRaw).map(
    (row): AppliedMigration => ({ name: row.name, appliedAt: row.applied_at }),
  );
  const { pending, missing } = diffMigrations(
    localMigrations,
    applied.map((item) => item.name),
    tables,
  );

  let usage: Snapshot["usage"] = null;
  if (tables.includes("usage_visits") && tables.includes("usage_screens")) {
    try {
      const usageRaw = await loadD1<unknown[]>(run, worker, USAGE_SQL);
      const [visitsRaw, screensRaw] = asResults(usageRaw, 2);
      usage = {
        visits: rows<RawVisit>(visitsRaw).map(
          (row): VisitRow => ({
            day: row.day,
            platform: row.platform,
            visits: Number(row.visits),
          }),
        ),
        screens: rows<RawScreen>(screensRaw).map(
          (row): ScreenRow => ({
            day: row.day,
            platform: row.platform,
            screen: row.screen,
            views: Number(row.views),
          }),
        ),
      };
    } catch (error) {
      warnings.push(`用量查询失败：${errorMessage(error)}`);
    }
  }

  const counts = rows<RawCounts>(countsRaw)[0] ?? {
    inboxes: 0,
    ingest_keys: 0,
    readings: 0,
  };

  return {
    fetchedAt: now.toISOString(),
    account: whoami,
    feedback: rows<RawFeedback>(feedbackRaw).map(mapFeedback),
    tips: rows<RawTip>(tipsRaw).map(mapTip),
    mailbox: {
      inboxes: Number(counts.inboxes),
      ingestKeys: Number(counts.ingest_keys),
      readings: Number(counts.readings),
      boxes: rows<RawInbox>(boxesRaw).map(mapInbox),
      recent: rows<RawReading>(readingsRaw).map(mapReading),
    },
    usage,
    health: {
      tables,
      appliedMigrations: applied,
      pendingMigrations: pending,
      missingTables: missing,
      workerDeployedAt,
      siteDeployedAt,
      rateLimits: rows<RawRate>(ratesRaw).map(
        (row): RateLimitRow => ({
          bucket: row.bucket,
          windowStart: Number(row.window_start),
          count: Number(row.count),
        }),
      ),
      warnings,
    },
  };
}

async function loadWhoami(
  run: Runner,
  cwd: string,
): Promise<Snapshot["account"]> {
  const data = await wranglerJSON<Whoami>(run, ["whoami", "--json"], cwd);
  if (data.loggedIn === false) {
    throw new Error("本机还没 wrangler login。cd worker && npx wrangler login");
  }
  const account = data.accounts?.[0];
  if (!account) {
    throw new Error("wrangler whoami 没有账号。cd worker && npx wrangler login");
  }
  return {
    email: data.email ?? "",
    name: account.name,
    id: account.id,
  };
}

async function loadD1<T>(run: Runner, cwd: string, sql: string): Promise<T> {
  return wranglerJSON<T>(
    run,
    ["d1", "execute", "tollcat", "--remote", "--json", "--yes", "--command", sql],
    cwd,
  );
}

async function loadLatestDeploy(
  run: Runner,
  cwd: string,
  name: string | undefined,
  warnings: string[],
): Promise<string | null> {
  try {
    const args = ["deployments", "list", "--json"];
    if (name) args.push("--name", name);
    const list = await wranglerJSON<Deployment[]>(run, args, cwd);
    const stamps = list
      .map((item) => item.created_on)
      .filter((item): item is string => typeof item === "string" && item.length > 0)
      .sort();
    return stamps.at(-1) ?? null;
  } catch (error) {
    warnings.push(
      `${name ?? "toll-api"} 部署记录读不到：${errorMessage(error)}`,
    );
    return null;
  }
}

function asResults(value: unknown, expected: number): D1Result<unknown>[] {
  if (!Array.isArray(value)) {
    throw new Error("wrangler d1 --json 应返回结果数组");
  }
  if (value.length < expected) {
    throw new Error(`d1 只返回了 ${value.length} 段结果，期望 ${expected}`);
  }
  return value as D1Result<unknown>[];
}

function rows<T>(result: D1Result<unknown> | undefined): T[] {
  if (!result?.success && result?.results === undefined) return [];
  return (result.results ?? []) as T[];
}

function mapFeedback(row: RawFeedback): FeedbackRow {
  return {
    id: row.id,
    category: row.category,
    message: row.message,
    contact: row.contact,
    appVersion: row.app_version,
    osVersion: row.os_version,
    locale: row.locale,
    deviceModel: row.device_model,
    providers: row.providers,
    exchange: row.exchange,
    createdAt: row.created_at,
  };
}

function mapTip(row: RawTip): TipRow {
  return {
    transactionId: row.transaction_id,
    productId: row.product_id,
    displayPrice: row.display_price,
    name: row.name,
    message: row.message,
    appVersion: row.app_version,
    createdAt: row.created_at,
  };
}

function mapInbox(row: RawInbox): InboxRow {
  return {
    inboxId: row.inbox_id,
    createdAt: row.inbox_created_at,
    keys: Number(row.keys),
    readings: Number(row.readings),
    lastReadingAt: row.last_reading_at,
  };
}

function mapReading(row: RawReading): ReadingRow {
  return {
    provider: row.provider,
    periodStart: row.period_start,
    currentSpendUsd: row.current_spend_usd,
    reportedAt: row.reported_at,
  };
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
