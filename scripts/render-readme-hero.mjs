// README 顶上那张横幅，和落地页的社交卡片：品牌锁定 + 一句标题 + 一台真机，
// 同一套版式，分语言、分画布各一张。
//
// 机身是 Apple 官方 Product Bezel 里嵌好截图的透明 PNG，走
// `scripts/apple_bezels.py composite`——和落地页、商店宣传图同一份机壳清单。
// 以前这里是手搓的一个圆角黑框配一张过期截图：同一个 App 在 README 和商店页
// 长着两台不同的机器，屏幕上还停在几个版本以前的仪表盘。
//
// 截图直接用商店那批原图（`docs/appstore/screenshots/iphone69-dashboard-<语言>-light.png`，
// 由 `scripts/capture-appstore-screenshots.sh` 出）——横幅不另截一套，
// 不然两处的仪表盘迟早对不上。
//
// 两档画布都进 git：
//   .github/readme/hero-<语言>.png   README 顶上那张，扁
//   .github/readme/og-<语言>.png     社交卡片，1.91:1（astro.config.mjs 拷成 public/og-*.png）
// 用法：node scripts/render-readme-hero.mjs                  # 六张
//       ONLY=en node scripts/render-readme-hero.mjs          # 只出这一语言的两张
//       CANVAS=hero node scripts/render-readme-hero.mjs      # 只出这一档
import { execFileSync, spawn } from "node:child_process";
import { mkdirSync, writeFileSync, existsSync, rmSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const SHOTS = path.join(ROOT, "docs/appstore/screenshots");
const OUT = path.join(ROOT, ".github/readme");
const TMP = path.join(ROOT, ".tmp-task-readme-hero");
const ICON = path.join(ROOT, "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png");
const FONT = path.join(
  ROOT,
  "site/node_modules/@fontsource-variable/bricolage-grotesque/files/bricolage-grotesque-latin-wght-normal.woff2",
);

// 亮色机壳配亮色截图，和落地页、商店宣传图一条规矩。
const BEZEL = "iphone-17-pro-max-silver";
const LOCALES = ["zh", "en", "ja"];

// 标题就是品牌主句，一字不改（事实源见下面的 BLURB）。
// 副标题是横幅自己的：一条利益点 + 一条隐私事实，中间一个间隔号。
const COPY = {
  zh: {
    lines: ["把各家云账单，", "装进口袋。"],
    sub: "各家加成一个数 · 凭据不出这台设备",
  },
  en: {
    lines: ["Your cloud bills,", "in your pocket."],
    sub: "One total across every vendor · credentials never leave this device",
  },
  ja: {
    lines: ["クラウドの請求を、", "ポケットに。"],
    sub: "全社をひとつの数字に · 認証情報はこの端末から出ない",
  },
};

const LANG_ATTR = { zh: "zh-Hans", en: "en", ja: "ja" };
const FONT_STACK = {
  zh: `"Bricolage Grotesque", "PingFang SC", sans-serif`,
  en: `"Bricolage Grotesque", "PingFang SC", sans-serif`,
  ja: `"Bricolage Grotesque", "Hiragino Sans", sans-serif`,
};
// 全角字比等号大小的拉丁字母占得满，同一个字号看着更大：三语各给一档。
const HEADLINE_SIZE = { zh: 112, en: 120, ja: 110 };
const SUB_SIZE = { zh: 46, en: 42, ja: 42 };

// 两档画布。同一套版式，但**宽高比不一样，所以不能共用一张图**：
//
// - hero：GitHub 上按栏宽铺满，看到的高度只由宽高比决定。横幅太高会把 README
//   第一屏的正文全顶下去，所以宽度不动、把高度压下来。
// - og：Facebook / X / Slack 的卡片按 1.91:1 裁。拿扁的那张去当 og:image，
//   左边的字会被切掉——而且只有别人转链接时才看得见，自己永远发现不了。
//
// `scale` 只乘字号和竖向间距；横向位置一律写成画布宽度的比例。
const CANVASES = [
  {
    key: "hero",
    width: 2400,
    height: 980,
    scale: 1,
    device: { width: 0.242, left: 0.708, top: 0.094 },
    out: (locale) => path.join(OUT, `hero-${locale}.png`),
  },
  {
    key: "og",
    width: 2400,
    height: 1260,
    scale: 1.28,
    device: { width: 0.239, left: 0.7175, top: 0.123 },
    out: (locale) => path.join(OUT, `og-${locale}.png`),
  },
];

// 1.91:1 是各家社交卡片的裁切比。og 那档偏出这个范围就是白做。
const OG_RATIO = 1.91;
const OG_RATIO_TOLERANCE = 0.03;

// 底面：一块浅灰纸配右上角一枚品牌色圆盘，圆心在画布外，只露一段弧。
// 圆盘的竖向尺寸跟着画布高度走，横向圆心跟着画布宽度走。
const SURFACE = {
  paper: "#e6e8ee",
  disc: "#d2d4ea",
  discCenterX: 0.817,
  discCenterY: -0.061,
  discRadius: 0.633,
  ink: "#14151a",
  sub: "#5c6370",
};

// 左边那一栏。横向写成画布宽度的比例，竖向由 flex 居中。
const COLUMN = { left: 0.054, width: 0.6 };

// 品牌主句（BRAND.md 第零节：全站唯一的自我介绍）。横幅的标题就是它，
// 只是断成两行——断行位置得手写，别的都不许两处各写一份。
//
// 事实源取 `site/src/i18n` 的 `footer.blurb`：README 顶上原本也印着这一句，
// 但横幅图里已经有了，那行就删掉了。剩下这一处是站点页脚在用的活文案。
const BLURB = "footer.blurb";

let siteCopy;
function tagline(locale) {
  siteCopy ??= JSON.parse(
    execFileSync("node", [path.join(ROOT, "scripts/dump-site-copy.cjs"), path.join(ROOT, "site/src/i18n/index.ts")], {
      encoding: "utf8",
    }),
  );
  return BLURB.split(".").reduce((node, key) => node?.[key], siteCopy[locale]);
}

/// 标题拼回一行必须和品牌主句一字不差：主句改了词、横幅还印着旧的，
/// 是那种谁都不会去比对的错。
function headline(locale) {
  const lines = COPY[locale].lines;
  const joined = lines.join(locale === "en" ? " " : "");
  const expected = tagline(locale);
  if (joined !== expected) {
    throw new Error(
      `hero-${locale} 的标题和品牌主句对不上：\n  横幅 ${joined}\n  ${BLURB} ${expected}`,
    );
  }
  return lines;
}

function deviceFile(locale) {
  return path.join(TMP, `device-${locale}.png`);
}

/// 把这一语言的仪表盘截图嵌进机壳。机壳、开孔、圆角都在 apple_bezels.py 里。
function buildDevice(locale) {
  const shot = path.join(SHOTS, `iphone69-dashboard-${locale}-light.png`);
  if (!existsSync(shot)) {
    throw new Error(`缺 ${path.relative(ROOT, shot)}——先跑 scripts/capture-appstore-screenshots.sh`);
  }
  execFileSync(
    "python3",
    [path.join(ROOT, "scripts/apple_bezels.py"), "composite", BEZEL, shot, deviceFile(locale), "--exact"],
    { stdio: "inherit" },
  );
}

function html(canvas, locale) {
  const copy = COPY[locale];
  const lines = headline(locale);
  const em = (size) => Math.round(size * canvas.scale);
  const cx = Math.round(SURFACE.discCenterX * canvas.width);
  const cy = Math.round(SURFACE.discCenterY * canvas.height);
  const r = Math.round(SURFACE.discRadius * canvas.height);

  return `<!doctype html>
<html lang="${LANG_ATTR[locale]}">
<head>
<meta charset="utf-8">
<style>
@font-face {
  font-family: "Bricolage Grotesque";
  font-style: normal;
  font-weight: 200 800;
  src: url("file://${FONT}") format("woff2-variations");
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  width: ${canvas.width}px;
  height: ${canvas.height}px;
  overflow: hidden;
  position: relative;
  background: ${SURFACE.paper};
}
.disc {
  position: absolute;
  left: ${cx - r}px;
  top: ${cy - r}px;
  width: ${r * 2}px;
  height: ${r * 2}px;
  border-radius: 50%;
  background: ${SURFACE.disc};
}
/* 字排在左半边，整组竖向居中：横幅压扁之后，靠上排会在底下留一条空带。 */
.copy {
  position: absolute;
  left: ${Math.round(COLUMN.left * canvas.width)}px;
  top: 0;
  bottom: 0;
  width: ${Math.round(COLUMN.width * canvas.width)}px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  z-index: 10;
}
.brand {
  display: flex;
  align-items: center;
  gap: ${em(28)}px;
}
/* 图标就是 App 的那张 1024，圆角按 iOS 的连续圆角近似取 22.4%。 */
.brand img {
  display: block;
  width: ${em(128)}px;
  height: ${em(128)}px;
  border-radius: 22.4%;
}
.brand span {
  font-family: ${FONT_STACK.en};
  font-size: ${em(62)}px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: ${SURFACE.ink};
}
h1 {
  margin-top: ${em(62)}px;
  font-family: ${FONT_STACK[locale]};
  font-size: ${em(HEADLINE_SIZE[locale])}px;
  font-weight: 640;
  line-height: 1.16;
  letter-spacing: ${locale === "en" ? "-0.02em" : "0"};
  color: ${SURFACE.ink};
}
.sub {
  margin-top: ${em(40)}px;
  font-family: ${FONT_STACK[locale]};
  font-size: ${em(SUB_SIZE[locale])}px;
  font-weight: 500;
  line-height: 1.4;
  color: ${SURFACE.sub};
  white-space: nowrap;
}
/* 机身 PNG 背景透明，投影得跟着机身轮廓走，所以是 drop-shadow 不是 box-shadow。 */
.device {
  position: absolute;
  left: ${Math.round(canvas.device.left * canvas.width)}px;
  top: ${Math.round(canvas.device.top * canvas.height)}px;
  width: ${Math.round(canvas.device.width * canvas.width)}px;
  height: auto;
  display: block;
  z-index: 5;
  filter: drop-shadow(0 22px 40px rgba(20, 21, 45, 0.20)) drop-shadow(0 4px 10px rgba(20, 21, 45, 0.10));
}
</style>
</head>
<body>
  <div class="disc"></div>
  <div class="copy">
    <div class="brand">
      <img src="file://${ICON}" alt="">
      <span translate="no">TollCat</span>
    </div>
    <h1>${lines.join("<br>")}</h1>
    <div class="sub">${copy.sub}</div>
  </div>
  <img class="device" src="file://${deviceFile(locale)}" alt="">
</body>
</html>`;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const POLL_MS = 200;
const SHOOT_TIMEOUT_MS = 60_000;

/// 文件出现、而且大小连着两次不变 = 写完了。
async function settledFile(file, deadline) {
  let previous = -1;
  while (Date.now() < deadline) {
    if (existsSync(file)) {
      const size = statSync(file).size;
      if (size > 0 && size === previous) return true;
      previous = size;
    }
    await sleep(POLL_MS);
  }
  return false;
}

async function shoot(canvas, locale) {
  const name = `${canvas.key}-${locale}`;
  const page = path.join(TMP, `${name}.html`);
  writeFileSync(page, html(canvas, locale));
  const out = canvas.out(locale);
  // 先把旧图删掉：`settledFile` 认的是「文件在、大小连着两次不变」，上一轮的产物
  // 摆在那儿就正好满足——Chrome 还没落笔就被判定写完杀掉，旧图原样当新图交上去。
  rmSync(out, { force: true });
  const child = spawn(CHROME, [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=1",
    "--no-first-run",
    "--no-default-browser-check",
    `--user-data-dir=${path.join(TMP, `profile-${name}`)}`,
    "--allow-file-access-from-files",
    `--window-size=${canvas.width},${canvas.height}`,
    "--virtual-time-budget=4000",
    "--timeout=15000",
    `--screenshot=${out}`,
    `file://${page}`,
  ], { stdio: "ignore" });
  const exited = new Promise((resolve) => child.once("exit", resolve));
  await Promise.race([settledFile(out, Date.now() + SHOOT_TIMEOUT_MS), exited]);
  child.kill("SIGKILL");
  await exited;
  if (!existsSync(out)) {
    console.error(`FAILED ${name}`);
    process.exitCode = 1;
    return;
  }
  // Chrome 超时会留下上一张旧图。尺寸对不上就当失败。
  const ident = execFileSync("sips", ["-g", "pixelWidth", "-g", "pixelHeight", out], { encoding: "utf8" });
  const width = Number(/pixelWidth:\s*(\d+)/.exec(ident)?.[1]);
  const height = Number(/pixelHeight:\s*(\d+)/.exec(ident)?.[1]);
  if (width !== canvas.width || height !== canvas.height) {
    console.error(`FAILED ${name}: ${width}×${height}, expected ${canvas.width}×${canvas.height}`);
    process.exitCode = 1;
    return;
  }
  console.log(`wrote ${path.relative(ROOT, out)} ${width}×${height}`);
}

mkdirSync(TMP, { recursive: true });
mkdirSync(OUT, { recursive: true });

// og 那档的比例是给别家平台看的，写错了本地一切正常、转出去才露馅：开工前先量。
const og = CANVASES.find((canvas) => canvas.key === "og");
if (Math.abs(og.width / og.height - OG_RATIO) > OG_RATIO_TOLERANCE) {
  console.error(`og 画布 ${og.width}×${og.height} 是 ${(og.width / og.height).toFixed(2)}:1，社交卡片要 ${OG_RATIO}:1`);
  process.exit(2);
}

const pick = (env, all, label) => {
  const only = process.env[env]?.split(",").map((s) => s.trim()).filter(Boolean);
  const kept = only ? all.filter((item) => only.includes(item.key ?? item)) : all;
  if (kept.length === 0) {
    console.error(`${env} 里没有认得的${label}，可选：${all.map((i) => i.key ?? i).join(" ")}`);
    process.exit(2);
  }
  return kept;
};

const locales = pick("ONLY", LOCALES, "语言");
const canvases = pick("CANVAS", CANVASES, "画布");

for (const locale of locales) buildDevice(locale);
for (const canvas of canvases) {
  for (const locale of locales) await shoot(canvas, locale);
}
