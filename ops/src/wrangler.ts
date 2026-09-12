import { wranglerBin } from "./paths";

export type CommandResult = {
  stdout: string;
  stderr: string;
  code: number;
};

export type Runner = (args: string[], cwd: string) => Promise<CommandResult>;

export class WranglerError extends Error {
  readonly code: number;
  readonly stderr: string;

  constructor(message: string, code: number, stderr: string) {
    super(message);
    this.name = "WranglerError";
    this.code = code;
    this.stderr = stderr;
  }
}

export function makeRunner(root: string): Runner {
  const bin = wranglerBin(root);
  return async (args, cwd) => {
    // WRANGLER_LOG=error/warn 会把 d1 --json / deployments --json 一起吞掉，
    // 只剩 whoami 还能打出 JSON。命令自己带 --json，这里不要设 log level。
    const env: Record<string, string | undefined> = {
      ...process.env,
      WRANGLER_SEND_METRICS: "false",
    };
    delete env.WRANGLER_LOG;
    const proc = Bun.spawn([bin, ...args], {
      cwd,
      stdout: "pipe",
      stderr: "pipe",
      env,
    });
    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();
    const code = await proc.exited;
    return { stdout, stderr, code };
  };
}

export async function wranglerJSON<T>(
  run: Runner,
  args: string[],
  cwd: string,
): Promise<T> {
  const result = await run(args, cwd);
  const blob = `${result.stdout}\n${result.stderr}`;
  if (result.code !== 0) {
    throw new WranglerError(
      wranglerFailure(result) || `wrangler ${args.join(" ")} 退出 ${result.code}`,
      result.code,
      result.stderr,
    );
  }
  try {
    return parseWranglerJSON<T>(blob);
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new WranglerError(`wrangler ${args.join(" ")}：${detail}`, 0, result.stderr);
  }
}

export function parseWranglerJSON<T>(text: string): T {
  const start = text.search(/[\[{]/);
  if (start < 0) {
    throw new Error(`wrangler 没有返回 JSON：${text.trim().slice(0, 200)}`);
  }
  try {
    return JSON.parse(text.slice(start)) as T;
  } catch (error) {
    throw new Error(
      `wrangler JSON 解析失败：${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

function wranglerFailure(result: CommandResult): string {
  const blob = `${result.stderr}\n${result.stdout}`.trim();
  const lines = blob
    .split("\n")
    .map((line) => line.replace(/^[-✘\s]+/, "").trim())
    .filter((line) => line.length > 0 && !line.startsWith("⛅"));
  const useful = lines.find((line) => /not logged in|login|error|unauthorized/i.test(line));
  if (useful) return useful;
  return lines[0] ?? "";
}
