import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export function repoRoot(from = dirname(fileURLToPath(import.meta.url))): string {
  let dir = from;
  for (let i = 0; i < 10; i++) {
    if (
      existsSync(join(dir, "worker", "wrangler.toml")) &&
      existsSync(join(dir, "ARCHITECTURE.md"))
    ) {
      return dir;
    }
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  throw new Error("找不到仓库根目录（需要 worker/wrangler.toml）");
}

export function workerDir(root: string): string {
  return join(root, "worker");
}

export function siteDir(root: string): string {
  return join(root, "site");
}

export function wranglerBin(root: string): string {
  const candidates = [
    join(root, "worker", "node_modules", ".bin", "wrangler"),
    join(root, "site", "node_modules", ".bin", "wrangler"),
  ];
  for (const path of candidates) {
    if (existsSync(path)) return path;
  }
  throw new Error(
    "找不到 wrangler。先在 worker/ 执行 npm install，并确认本机已 wrangler login。",
  );
}
