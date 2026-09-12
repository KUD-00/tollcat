import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

export type LocalMigration = {
  name: string;
  tables: string[];
};

export async function readLocalMigrations(
  migrationsDir: string,
): Promise<LocalMigration[]> {
  const files = (await readdir(migrationsDir))
    .filter((name) => name.endsWith(".sql"))
    .sort();
  const out: LocalMigration[] = [];
  for (const name of files) {
    const sql = await readFile(join(migrationsDir, name), "utf8");
    out.push({ name, tables: tablesDeclaredIn(sql) });
  }
  return out;
}

export function tablesDeclaredIn(sql: string): string[] {
  const names: string[] = [];
  const seen = new Set<string>();
  const re =
    /CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["'`]?([A-Za-z_][A-Za-z0-9_]*)["'`]?/gi;
  for (const match of sql.matchAll(re)) {
    const name = match[1];
    if (!seen.has(name)) {
      seen.add(name);
      names.push(name);
    }
  }
  return names;
}

export function diffMigrations(
  local: LocalMigration[],
  appliedNames: string[],
  existingTables: string[],
): { pending: string[]; missing: string[] } {
  const applied = new Set(appliedNames);
  const pending = local.filter((item) => !applied.has(item.name)).map((item) => item.name);
  const have = new Set(existingTables);
  const missing: string[] = [];
  for (const table of local.flatMap((item) => item.tables)) {
    if (!have.has(table) && !missing.includes(table)) missing.push(table);
  }
  return { pending, missing };
}
