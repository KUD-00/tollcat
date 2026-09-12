import { SECTIONS, type Section } from "./types";

export type Args = {
  json: boolean;
  help: boolean;
  once: boolean;
  section: Section;
};

const SECTION_ALIASES: Record<string, Section> = {
  queue: "queue",
  todo: "queue",
  待办: "queue",
  feedback: "feedback",
  反馈: "feedback",
  tips: "tips",
  tip: "tips",
  打赏: "tips",
  inbox: "inbox",
  mailbox: "inbox",
  信箱: "inbox",
  usage: "usage",
  用量: "usage",
  health: "health",
  健康: "health",
};

export const HELP = `TollCat ops — 用本机 wrangler 权限看 api.tollcat.app 上要处理的事。

用法:
  bun ops/src/cli.tsx
  bun ops/src/cli.tsx --json
  bun ops/src/cli.tsx --once
  bun ops/src/cli.tsx --section feedback

选项:
  --json              打一份快照 JSON，不进 TUI
  --once              纯文本摘要，不进 TUI
  --section <name>    打开时停在哪一页：queue / feedback / tips / inbox / usage / health
  -h, --help          这份说明

不读 api.tollcat.app 的 HTTP。数据走 wrangler d1 / deployments，凭据是本机 wrangler login。
已读标记存在 ~/.tollcat/ops-ack.json，不改远端库。
`;

export function parseArgs(argv: string[]): Args {
  const args: Args = {
    json: false,
    help: false,
    once: false,
    section: "queue",
  };

  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (token === "--json") {
      args.json = true;
      continue;
    }
    if (token === "--once") {
      args.once = true;
      continue;
    }
    if (token === "-h" || token === "--help") {
      args.help = true;
      continue;
    }
    if (token === "--section") {
      const value = argv[++i];
      if (!value) throw new Error("--section 需要一个名字");
      args.section = parseSection(value);
      continue;
    }
    if (token.startsWith("--section=")) {
      args.section = parseSection(token.slice("--section=".length));
      continue;
    }
    throw new Error(`不认识的参数：${token}。--help 看用法。`);
  }

  return args;
}

function parseSection(value: string): Section {
  const mapped = SECTION_ALIASES[value];
  if (mapped) return mapped;
  throw new Error(`不认识的页面：${value}。可选 ${SECTIONS.join(" / ")}`);
}
