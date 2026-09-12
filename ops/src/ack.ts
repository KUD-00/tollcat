import { mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { homedir } from "node:os";

export type AckStore = {
  version: 1;
  items: Record<string, string>;
};

export function defaultAckPath(): string {
  return process.env.TOLL_OPS_ACK ?? join(homedir(), ".tollcat", "ops-ack.json");
}

export async function loadAck(path = defaultAckPath()): Promise<Set<string>> {
  const file = Bun.file(path);
  if (!(await file.exists())) return new Set();
  try {
    const parsed = (await file.json()) as Partial<AckStore>;
    return new Set(Object.keys(parsed.items ?? {}));
  } catch {
    return new Set();
  }
}

export async function saveAck(
  acked: Set<string>,
  path = defaultAckPath(),
  now = new Date(),
): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  const existing = await readStore(path);
  const stamp = now.toISOString();
  const items: Record<string, string> = {};
  for (const key of acked) {
    items[key] = existing.items[key] ?? stamp;
  }
  const store: AckStore = { version: 1, items };
  await Bun.write(path, `${JSON.stringify(store, null, 2)}\n`);
}

export function toggleAck(acked: Set<string>, id: string): Set<string> {
  const next = new Set(acked);
  if (next.has(id)) next.delete(id);
  else next.add(id);
  return next;
}

async function readStore(path: string): Promise<AckStore> {
  const file = Bun.file(path);
  if (!(await file.exists())) return { version: 1, items: {} };
  try {
    const parsed = (await file.json()) as Partial<AckStore>;
    return { version: 1, items: parsed.items ?? {} };
  } catch {
    return { version: 1, items: {} };
  }
}
