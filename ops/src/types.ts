export type FeedbackRow = {
  id: string;
  category: string;
  message: string;
  contact: string | null;
  appVersion: string;
  osVersion: string;
  locale: string;
  deviceModel: string | null;
  providers: string | null;
  exchange: string | null;
  createdAt: string;
};

export type TipRow = {
  transactionId: string;
  productId: string;
  displayPrice: string;
  name: string | null;
  message: string | null;
  appVersion: string;
  createdAt: string;
};

export type InboxRow = {
  inboxId: string;
  createdAt: string;
  keys: number;
  readings: number;
  lastReadingAt: string | null;
};

export type ReadingRow = {
  provider: string;
  periodStart: string;
  currentSpendUsd: string | null;
  reportedAt: string;
};

export type VisitRow = {
  day: string;
  platform: string;
  visits: number;
};

export type ScreenRow = {
  day: string;
  platform: string;
  screen: string;
  views: number;
};

export type RateLimitRow = {
  bucket: string;
  windowStart: number;
  count: number;
};

export type AppliedMigration = {
  name: string;
  appliedAt: string;
};

export type AccountInfo = {
  email: string;
  name: string;
  id: string;
};

export type Snapshot = {
  fetchedAt: string;
  account: AccountInfo | null;
  feedback: FeedbackRow[];
  tips: TipRow[];
  mailbox: {
    inboxes: number;
    ingestKeys: number;
    readings: number;
    boxes: InboxRow[];
    recent: ReadingRow[];
  };
  usage: {
    visits: VisitRow[];
    screens: ScreenRow[];
  } | null;
  health: {
    tables: string[];
    appliedMigrations: AppliedMigration[];
    pendingMigrations: string[];
    missingTables: string[];
    workerDeployedAt: string | null;
    siteDeployedAt: string | null;
    rateLimits: RateLimitRow[];
    warnings: string[];
  };
};

export type Section = "queue" | "feedback" | "tips" | "inbox" | "usage" | "health";

export const SECTIONS: Section[] = [
  "queue",
  "feedback",
  "tips",
  "inbox",
  "usage",
  "health",
];

export type QueueItem = {
  id: string;
  kind: "feedback" | "tip" | "health";
  kicker: string;
  title: string;
  summary: string;
  createdAt: string;
  lines: string[];
  copyText: string | null;
};

export type D1Result<T> = {
  results: T[];
  success: boolean;
};
