// 发 SNS 用的「这些服务完全支持了」宣传图：星眼猫居中，头顶围一圈服务 icon，
// 下面一句标题、一句事实、一行服务名，底部品牌锁定。
//
// 素材全部取现成的单源，本脚本只持有构图：
//   猫的几何      shared/cat.json（silhouette + tail + eyeSparkle + mouthSmallO，
//                 即 App 里的 CatMood.saved——「星眼 + 小圆嘴」这个命名组合）
//   服务 icon     shared/providers.json（Simple Icons 单色 path 和 tile 配色，
//                 画法与 site/src/marqueeSvg.ts 同一套：圆角 tile + 白色 glyph，缺图回落首字母）
//   「已测试」名单 site/src/supportTiers.ts（generate-shared.py 从 ProviderCatalog.swift 生成）
//   文案          site/src/i18n 的 supportListPage.sections.tested（标题层允许自己写一句冲击句，
//                 事实层那句 lede 原样搬，不另写一份）
//   底面与字体    与 scripts/render-readme-hero.mjs 同一张纸、同一枚圆盘、同一款 Bricolage
//
// 输出到 docs/launch/sns/（.gitignore 里的商店与发布素材目录，只在本机）：
//   supported-<语言>-square.png   2160×2160，1:1，Instagram / Threads / 微博 / 小红书
//   supported-<语言>-wide.png     2400×1350，16:9，X / Bluesky / Mastodon 时间线
//
// 用法：
//   node scripts/render-sns-supported.mjs                        # 三语 × 两档，全部「已测试」家
//   ONLY=zh CANVAS=square node scripts/render-sns-supported.mjs  # 只出一张
//   PROVIDERS=neo4j,botpress MODE=new node scripts/render-sns-supported.mjs
//       # 只画这几家、标题改成「又多了 N 家，完全支持」——发「本版新增」贴子用
//   THEME=dark node scripts/render-sns-supported.mjs             # 深色底
//   TITLE="自定义标题" node scripts/render-sns-supported.mjs       # 覆盖标题（一语言时用）
import { execFileSync, spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const OUT = path.join(ROOT, "docs/launch/sns");
const TMP = path.join(ROOT, ".tmp-task-sns-supported");
const ICON = path.join(ROOT, "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png");
const FONT = path.join(
  ROOT,
  "site/node_modules/@fontsource-variable/bricolage-grotesque/files/bricolage-grotesque-latin-wght-normal.woff2",
);

const LOCALES = ["zh", "en", "ja"];
const LANG_ATTR = { zh: "zh-Hans", en: "en", ja: "ja" };
const FONT_STACK = {
  zh: `"Bricolage Grotesque", "PingFang SC", sans-serif`,
  en: `"Bricolage Grotesque", "PingFang SC", sans-serif`,
  ja: `"Bricolage Grotesque", "Hiragino Sans", sans-serif`,
};

// 标题层（BRAND.md 第一节）：可以短促有冲击，但必须是合法的三语各自的话。
// 主张的词是「完全支持」（tier 名叫「完全支持并测试过的」），「测过了」只是它的证据，不当标题。
// {n} 是本次画上去的服务数。all 是「全部已测试家」的贴子，new 是「本版新增」的贴子。
// | 是允许断行的位置：一行排得下就整句排，排不下在这里断成两行。| 前面的空格是一行时的词距，断行时会去掉。
// 没有它 Chrome 会在日文词中间随便折（「検証済 / み。」）。
// 「完全支持」这个主张单独做成主句上方的眉题，主句只说家数——把两件事塞进一句
// 逗号句（「又多了 5 家，完全支持。」）不是人在 SNS 上会说的话。
// 「接」是站点文案本来就在用的动词（「想接哪一家」「App 里也接得上」）。
const EYEBROW = { zh: "完全支持", en: "Fully supported", ja: "完全対応" };
const HEADLINE = {
  all: {
    zh: "这{n}家，|都接上了。",
    en: "All {n} |of these.",
    ja: "この{n}社、|すべて。",
  },
  new: {
    zh: "新接了|{n}家。",
    en: "{n} more |services.",
    ja: "新たに|{n}社。",
  },
};
// 全角字比同字号的拉丁字母占得满，三语各给一档。
const HEADLINE_SIZE = { zh: 112, en: 124, ja: 104 };
const LEDE_SIZE = { zh: 40, en: 38, ja: 36 };

// 底面：亮色是 README 横幅那张纸和圆盘；深色是 App 深色的猫身与画布。
const SURFACE = {
  light: {
    paper: "#e6e8ee",
    disc: "#d2d4ea",
    ink: "#14151a",
    sub: "#5c6370",
    cat: "#6E747B",
    catInk: "#FFFFFF",
    star: "#5856D6",
    tileShadow: "rgba(20, 21, 45, 0.16)",
    chip: "rgba(255, 255, 255, 0.62)",
    chipInk: "#2b3038",
  },
  dark: {
    paper: "#0B0B12",
    disc: "#1a1a2e",
    ink: "#F4F4FF",
    sub: "#a5aab8",
    cat: "#858C93",
    catInk: "#0B0B12",
    star: "#968FF5",
    tileShadow: "rgba(0, 0, 0, 0.45)",
    chip: "rgba(255, 255, 255, 0.07)",
    chipInk: "#d9dce6",
  },
};

// 两档画布。square 是上下堆：光环 → 猫 → 字。wide 是左右分：字在左、猫和光环在右，
// 跟 README 横幅（字左、机器右）同一个骨架，放在一起像一家出的。
const CANVASES = [
  {
    key: "square",
    width: 2160,
    height: 2160,
    // 字号系数。SNS 时间线里这张图只有三四百像素宽，字小了从外面根本看不见。
    scale: 1.32,
    // 猫头圆心。光环的圆心就是它。猫区压到上 60%，字区从 0.64 起。
    cat: { x: 0.5, y: 0.36, size: 0.32 },
    copy: { left: 0.07, width: 0.86, top: 0.59, align: "center" },
    halo: { inner: 0.225, gap: 0.072, from: -12, to: 192 },
    disc: { cx: 0.5, cy: 0.21, r: 0.385 },
    out: (locale) => path.join(OUT, `supported-${locale}-square.png`),
  },
  {
    key: "wide",
    width: 2400,
    height: 1350,
    scale: 1.12,
    cat: { x: 0.725, y: 0.60, size: 0.40 },
    copy: { left: 0.05, width: 0.45, top: 0, align: "left" },
    halo: { inner: 0.31, gap: 0.105, from: -20, to: 200 },
    disc: { cx: 0.735, cy: 0.58, r: 0.46 },
    out: (locale) => path.join(OUT, `supported-${locale}-wide.png`),
  },
];

// —— 猫 ——————————————————————————————————————————————————————————————

const CAT = JSON.parse(readFileSync(path.join(ROOT, "shared/cat.json"), "utf8"));
const CAT_VIEW = CAT.viewBox;
const [HEAD_X, HEAD_Y] = [512, 556]; // 两只眼的中线，光环绕这一点。

/// 星眼 + 小圆嘴（CatMood.saved）。尾巴稍微翘一点，让它看着是活的。
function catSvg(theme) {
  const p = CAT.paths;
  const s = SURFACE[theme];
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${CAT_VIEW} ${CAT_VIEW}">
  <g transform="rotate(-4 ${CAT.anchors.tailPivot.join(" ")})"><path fill="${s.cat}" d="${p.tail}"/></g>
  <path fill="${s.cat}" d="${p.silhouette}"/>
  <path fill="${s.catInk}" d="${p.eyeSparkle[0]}"/>
  <path fill="${s.catInk}" d="${p.eyeSparkle[1]}"/>
  <path fill="${s.catInk}" d="${p.mouthSmallO}"/>
</svg>`;
}

// —— 服务 icon ————————————————————————————————————————————————————————

const PROVIDERS = JSON.parse(readFileSync(path.join(ROOT, "shared/providers.json"), "utf8"));
const BY_KEY = new Map(PROVIDERS.providers.map((p) => [p.key, p]));

function xmlEscape(value) {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

/// 与 site/src/marqueeSvg.ts 同一套画法：圆角 tile 铺品牌色，glyph 用白/墨色，
/// fill 是 glyph 边长占比（默认 0.68），pathRef 指向别家共用的 path，没图回落首字母。
function tileSvg(mark, theme, size) {
  const src = mark.pathRef ? BY_KEY.get(mark.pathRef) : mark;
  const pathD = src?.path;
  const bg = theme === "dark" ? mark.dark : mark.light;
  const ink = theme === "dark" ? "#0e1116" : "#ffffff";
  const fill = mark.fill ?? PROVIDERS.defaultFill ?? 0.68;
  const pad = ((1 - fill) / 2) * size;
  const inner = size - pad * 2;
  const radius = size * 0.22;
  const glyph = pathD
    ? `<svg x="${pad}" y="${pad}" width="${inner}" height="${inner}" viewBox="0 0 24 24"><path d="${xmlEscape(pathD)}" fill="${ink}" fill-rule="${(src.evenOdd ?? mark.evenOdd) ? "evenodd" : "nonzero"}"/></svg>`
    : `<text x="${size / 2}" y="${size / 2}" text-anchor="middle" dominant-baseline="central" fill="${ink}" font-size="${size * 0.4}" font-weight="650" font-family="ui-sans-serif, system-ui, sans-serif">${xmlEscape(mark.key.charAt(0).toUpperCase())}</text>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}"><rect width="${size}" height="${size}" rx="${radius}" fill="${bg}"/>${glyph}</svg>`;
}

/// 默认画「完全支持并测试过的」全部家。名单不另抄一份，从生成物 supportTiers.ts 里读——
/// 它的源头是 ProviderCatalog.swift，App 里那张支持列表也是同一处。
function testedKeys() {
  const src = readFileSync(path.join(ROOT, "site/src/supportTiers.ts"), "utf8");
  const match = /tested:\s*\[([^\]]*)\]/.exec(src);
  if (!match) throw new Error("site/src/supportTiers.ts 里找不到 tested 名单");
  return [...match[1].matchAll(/"([^"]+)"/g)].map((m) => m[1]);
}

function resolveMarks() {
  const wanted = process.env.PROVIDERS?.split(",").map((s) => s.trim()).filter(Boolean) ?? testedKeys();
  const missing = wanted.filter((key) => !BY_KEY.has(key));
  if (missing.length) {
    throw new Error(`shared/providers.json 里没有这些 key：${missing.join(" ")}`);
  }
  return wanted.map((key) => BY_KEY.get(key));
}

// —— 光环：icon 绕猫头排成弧 ——————————————————————————————————————————

/// 把 N 块 tile 排到猫头上方的同心弧上。角度按数学习惯（0° 在右、逆时针为正、y 朝上），
/// from→to 是最大扫幅，家数少时按弧长收紧、绕头顶居中。内弧装得下就全在内弧；装不下按弧长按比例分到外弧，外弧的格子
/// 错半位，两圈不对齐才不像表格。每块给一点交替的小倾角，像是随手摆上去的。
function haloLayout(marks, canvas, tile) {
  const { width, height } = canvas;
  const cx = canvas.cat.x * width;
  const cy = canvas.cat.y * height;
  const short = Math.min(width, height);
  const fullSpan = ((canvas.halo.to - canvas.halo.from) * Math.PI) / 180;
  const innerRadius = canvas.halo.inner * short;
  // 家数少时别把三块 tile 撒满 200°：按「每块占 1.7 个 tile 的弧长」收紧，绕头顶（90°）居中。
  const tightSpan = Math.min(fullSpan, (marks.length * tile * 1.7) / innerRadius);
  const span = tightSpan;
  const fromRad = (Math.PI / 2) - span / 2;
  const rings = [];
  let remaining = marks.length;
  let radius = innerRadius;
  let ringIndex = 0;
  while (remaining > 0) {
    const capacity = Math.max(1, Math.floor((span * radius) / (tile * 1.28)));
    const count = Math.min(remaining, capacity);
    rings.push({ radius, count, offset: ringIndex % 2 === 1 ? 0.5 : 0 });
    remaining -= count;
    radius += canvas.halo.gap * short + tile * 0.25;
    ringIndex += 1;
  }
  // 内弧满、外弧只有两三块会头重脚轻：两圈时把总数按弧长比例摊开。
  if (rings.length === 2) {
    const total = marks.length;
    const weight = rings[0].radius / (rings[0].radius + rings[1].radius);
    rings[0].count = Math.max(1, Math.round(total * weight));
    rings[1].count = total - rings[0].count;
  }
  const placed = [];
  let index = 0;
  for (const ring of rings) {
    const step = span / ring.count;
    for (let i = 0; i < ring.count; i += 1) {
      const theta = fromRad + step * (i + 0.5);
      const x = cx + ring.radius * Math.cos(theta);
      const y = cy - ring.radius * Math.sin(theta);
      const tilt = (index % 2 === 0 ? 1 : -1) * (4 + (index % 3) * 2);
      placed.push({ mark: marks[index], x, y, tilt });
      index += 1;
    }
  }
  return placed;
}

/// 四角星，撒在光环和猫之间，配星眼。尺寸、位置按画布比例写死，不随机——
/// 同一份输入永远出同一张图。
const SPARKLES = [
  { dx: -0.66, dy: -0.34, size: 0.085 },
  { dx: 0.70, dy: -0.40, size: 0.065 },
  { dx: -0.78, dy: 0.14, size: 0.045 },
  { dx: 0.84, dy: 0.04, size: 0.055 },
  { dx: 0.14, dy: -0.80, size: 0.042 },
];

function starPath(size) {
  const r = size / 2;
  const k = r * 0.22;
  return `M0 ${-r} C ${k * 0.4} ${-k} ${k} ${-k * 0.4} ${r} 0 C ${k} ${k * 0.4} ${k * 0.4} ${k} 0 ${r} C ${-k * 0.4} ${k} ${-k} ${k * 0.4} ${-r} 0 C ${-k} ${-k * 0.4} ${-k * 0.4} ${-k} 0 ${-r} Z`;
}

// —— 文案 ————————————————————————————————————————————————————————————

let siteCopy;
function copyOf(locale, dotted) {
  siteCopy ??= JSON.parse(
    execFileSync("node", [path.join(ROOT, "scripts/dump-site-copy.cjs"), path.join(ROOT, "site/src/i18n/index.ts")], {
      encoding: "utf8",
    }),
  );
  const value = dotted.split(".").reduce((node, key) => node?.[key], siteCopy[locale]);
  if (typeof value !== "string") throw new Error(`site/src/i18n 里没有 ${locale}.${dotted}`);
  return value;
}

/// 截到第一个句号（中日「。」或英文「. 」），句号本身不要——图上的短句不带句号。
function firstSentence(text) {
  const match = /^(.*?)(。|\.(?=\s|$))/.exec(text);
  return match ? match[1] : text;
}

/// 去掉句尾的「。」或「.」。标题、事实句、品牌 blurb 上图时都不带句号。
function stripPeriod(text) {
  return text.replace(/[。.]\s*$/, "");
}

/// 估一行标题的宽度：全角字算 1 个字号，拉丁字母和空格算 0.55。只用来决定要不要断行。
function estimateWidth(text, fontSize) {
  let units = 0;
  for (const ch of text) units += /[\u3000-\u9fff\uff00-\uffef]/.test(ch) ? 1 : 0.55;
  return units * fontSize;
}

function headline(locale, count, mode, columnWidth, fontSize) {
  const template = process.env.TITLE ?? HEADLINE[mode]?.[locale];
  if (!template) throw new Error(`MODE 只认 ${Object.keys(HEADLINE).join(" / ")}`);
  const parts = stripPeriod(template.replace("{n}", String(count))).split("|");
  const oneLine = parts.join("");
  // 一行排得下就不断：「新接了 / 5 家。」这么短的句子折成两行很怪。
  if (estimateWidth(oneLine, fontSize) <= columnWidth) return xmlEscape(oneLine);
  return parts.map((part) => xmlEscape(part.trim())).join("<br>");
}

// —— 页面 ————————————————————————————————————————————————————————————

function html(canvas, locale, marks, theme, mode) {
  const s = SURFACE[theme];
  const { width, height } = canvas;
  const short = Math.min(width, height);
  const em = (size) => Math.round(size * canvas.scale);

  const catSize = canvas.cat.size * short;
  // 猫的 SVG 是 1024 视口，猫头中线在 (512, 556)：把这一点钉在 cat.x / cat.y 上。
  const catLeft = canvas.cat.x * width - (HEAD_X / CAT_VIEW) * catSize;
  const catTop = canvas.cat.y * height - (HEAD_Y / CAT_VIEW) * catSize;

  const tile = Math.round(short * (canvas.key === "square" ? 0.092 : 0.10) * (marks.length > 18 ? 0.82 : 1));
  const halo = haloLayout(marks, canvas, tile);
  const tiles = halo
    .map(
      ({ mark, x, y, tilt }) =>
        `<div class="tile" style="left:${Math.round(x - tile / 2)}px;top:${Math.round(y - tile / 2)}px;width:${tile}px;height:${tile}px;transform:rotate(${tilt}deg)">${tileSvg(mark, theme, tile)}</div>`,
    )
    .join("\n");

  const stars = SPARKLES.map(({ dx, dy, size }) => {
    const px = canvas.cat.x * width + dx * catSize * 0.5;
    const py = canvas.cat.y * height + dy * catSize * 0.5;
    const d = size * catSize;
    return `<svg class="star" style="left:${Math.round(px - d / 2)}px;top:${Math.round(py - d / 2)}px" width="${Math.round(d)}" height="${Math.round(d)}" viewBox="${-d / 2} ${-d / 2} ${d} ${d}"><path d="${starPath(d)}" fill="${s.star}"/></svg>`;
  }).join("\n");

  const title = headline(
    locale,
    marks.length,
    mode,
    Math.round(canvas.copy.width * width),
    em(HEADLINE_SIZE[locale]),
  );
  // 事实句只留第一句：「填入只读凭据，账单自动进来。」对账那句是支持列表页的语境，图上不要。
  const lede = firstSentence(copyOf(locale, "supportListPage.sections.tested.lede"));
  const blurb = stripPeriod(copyOf(locale, "footer.blurb"));
  // 服务名不再是一行灰字：一家一枚胶囊，小 tile 配名字，字号按家数分两档，多了自动换行。
  const many = marks.length > 8;
  const chipText = em(many ? 34 : 42);
  const chipIcon = em(many ? 52 : 64);
  const chips = marks
    .map((m) => `<span class="chip">${tileSvg(m, theme, chipIcon)}<span>${xmlEscape(m.name)}</span></span>`)
    .join("\n");
  // 胶囊排不进一行时按行数摊匀（3+2 而不是 4+1）：估每枚宽度，算出最少行数，
  // 再把容器压到「总宽 / 行数」附近，flex-wrap 自己就会折成差不多等长的几行。
  const chipGap = em(many ? 14 : 18);
  const chipPad = em(many ? 8 : 10) + em(many ? 22 : 28) + em(many ? 12 : 16);
  const chipWidths = marks.map((m) => chipIcon + chipPad + estimateWidth(m.name, chipText));
  const columnWidth = Math.round(canvas.copy.width * width);
  const chipsTotal = chipWidths.reduce((a, b) => a + b, 0) + chipGap * (marks.length - 1);
  const chipRows = Math.max(1, Math.ceil(chipsTotal / columnWidth));
  const chipsMax = chipRows === 1 ? columnWidth : Math.min(columnWidth, Math.round((chipsTotal / chipRows) * 1.16));

  const brandHtml = `<div class="brand">
    <img src="file://${ICON}" alt="">
    <span class="name" translate="no">TollCat</span>
    <span class="blurb">${xmlEscape(blurb)}</span>
  </div>`;

  const disc = {
    cx: Math.round(canvas.disc.cx * width),
    cy: Math.round(canvas.disc.cy * height),
    r: Math.round(canvas.disc.r * short),
  };

  const isSquare = canvas.key === "square";
  const copyCss = isSquare
    ? `left:${Math.round(canvas.copy.left * width)}px;width:${Math.round(canvas.copy.width * width)}px;top:${Math.round((canvas.copy.top - (many ? 0.02 : 0)) * height)}px;bottom:${em(48)}px;align-items:center;text-align:center;justify-content:flex-start;`
    : `left:${Math.round(canvas.copy.left * width)}px;width:${Math.round(canvas.copy.width * width)}px;top:0;bottom:${em(150)}px;align-items:flex-start;text-align:left;justify-content:center;`;

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
  width: ${width}px;
  height: ${height}px;
  overflow: hidden;
  position: relative;
  background: ${s.paper};
  font-family: ${FONT_STACK[locale]};
  color: ${s.ink};
}
.disc {
  position: absolute;
  left: ${disc.cx - disc.r}px;
  top: ${disc.cy - disc.r}px;
  width: ${disc.r * 2}px;
  height: ${disc.r * 2}px;
  border-radius: 50%;
  background: ${s.disc};
}
.cat {
  position: absolute;
  left: ${Math.round(catLeft)}px;
  top: ${Math.round(catTop)}px;
  width: ${Math.round(catSize)}px;
  height: ${Math.round(catSize)}px;
  z-index: 5;
}
.tile {
  position: absolute;
  z-index: 6;
  border-radius: 22%;
  box-shadow: 0 ${Math.round(tile * 0.12)}px ${Math.round(tile * 0.3)}px ${s.tileShadow};
}
.tile svg { display: block; width: 100%; height: 100%; }
.star { position: absolute; z-index: 4; }
.copy {
  position: absolute;
  display: flex;
  flex-direction: column;
  z-index: 10;
  ${copyCss}
}
.eyebrow {
  display: inline-block;
  margin-bottom: ${em(22)}px;
  padding: ${em(10)}px ${em(26)}px;
  border-radius: 999px;
  background: ${s.star};
  color: ${theme === "dark" ? "#0B0B12" : "#FFFFFF"};
  font-size: ${em(38)}px;
  font-weight: 680;
  letter-spacing: ${locale === "en" ? "0.02em" : "0.08em"};
  line-height: 1;
}
h1 {
  font-size: ${em(HEADLINE_SIZE[locale])}px;
  font-weight: 680;
  line-height: 1.12;
  letter-spacing: ${locale === "en" ? "-0.025em" : "0"};
  white-space: nowrap;
}
.lede {
  margin-top: ${em(30)}px;
  max-width: ${isSquare ? "26em" : "100%"};
  font-size: ${em(LEDE_SIZE[locale])}px;
  font-weight: 500;
  line-height: 1.45;
  color: ${s.sub};
}
.chips {
  margin-top: ${em(many ? 30 : 38)}px;
  display: flex;
  flex-wrap: wrap;
  justify-content: ${isSquare ? "center" : "flex-start"};
  gap: ${em(many ? 14 : 18)}px ${em(many ? 14 : 18)}px;
  max-width: ${chipsMax}px;
}
.chip {
  display: inline-flex;
  align-items: center;
  gap: ${em(many ? 12 : 16)}px;
  padding: ${em(many ? 8 : 10)}px ${em(many ? 22 : 28)}px ${em(many ? 8 : 10)}px ${em(many ? 8 : 10)}px;
  border-radius: 999px;
  background: ${s.chip};
  font-family: ${FONT_STACK.en};
  font-size: ${chipText}px;
  font-weight: 620;
  letter-spacing: -0.01em;
  color: ${s.chipInk};
  white-space: nowrap;
}
.chip svg { display: block; flex: none; border-radius: 26%; }
/* square 里品牌行是字栏的最后一项，margin-top:auto 把它推到底；胶囊多了它只会被顶下去，不会叠上。 */
.brand {
  ${isSquare
    ? `margin-top: auto; padding-top: ${em(40)}px; justify-content: center;`
    : `position: absolute; left: ${Math.round(canvas.copy.left * width)}px; bottom: ${em(48)}px;`}
  display: flex;
  align-items: center;
  gap: ${em(20)}px;
  z-index: 10;
}
.brand img { display: block; width: ${em(80)}px; height: ${em(80)}px; border-radius: 22.4%; }
.brand .name { font-family: ${FONT_STACK.en}; font-size: ${em(44)}px; font-weight: 700; letter-spacing: -0.02em; }
.brand .blurb { font-size: ${em(34)}px; font-weight: 500; color: ${s.sub}; margin-left: ${em(6)}px; }
</style>
</head>
<body>
  <div class="disc"></div>
  ${stars}
  <div class="cat">${catSvg(theme)}</div>
  ${tiles}
  <div class="copy">
    <div class="eyebrow">${xmlEscape(EYEBROW[locale])}</div>
    <h1>${title}</h1>
    <div class="lede">${xmlEscape(lede)}</div>
    <div class="chips">${chips}</div>
    ${isSquare ? brandHtml : ""}
  </div>
  ${isSquare ? "" : brandHtml}
</body>
</html>`;
}

// —— 截图（与 render-readme-hero.mjs 同一套护栏）————————————————————————

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

async function shoot(canvas, locale, marks, theme, mode) {
  const name = `${canvas.key}-${locale}-${theme}`;
  const page = path.join(TMP, `${name}.html`);
  writeFileSync(page, html(canvas, locale, marks, theme, mode));
  const out = theme === "light" ? canvas.out(locale) : canvas.out(locale).replace(/\.png$/, "-dark.png");
  // 先删旧图：settledFile 认「文件在、大小两次不变」，旧产物摆着会被当成写完。
  rmSync(out, { force: true });
  const child = spawn(
    CHROME,
    [
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
    ],
    { stdio: "ignore" },
  );
  const exited = new Promise((resolve) => child.once("exit", resolve));
  await Promise.race([settledFile(out, Date.now() + SHOOT_TIMEOUT_MS), exited]);
  child.kill("SIGKILL");
  await exited;
  if (!existsSync(out)) {
    console.error(`FAILED ${name}`);
    process.exitCode = 1;
    return;
  }
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

// —— 主流程 ——————————————————————————————————————————————————————————

if (!existsSync(CHROME)) {
  console.error(`缺 Chrome：${CHROME}`);
  process.exit(2);
}
if (!existsSync(FONT)) {
  console.error(`缺字体 ${path.relative(ROOT, FONT)}——先在 site/ 里跑 pnpm install`);
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

const marks = resolveMarks();
const mode = process.env.MODE ?? (process.env.PROVIDERS ? "new" : "all");
const theme = process.env.THEME ?? "light";
if (!SURFACE[theme]) {
  console.error(`THEME 只认 ${Object.keys(SURFACE).join(" / ")}`);
  process.exit(2);
}
if (process.env.TITLE && (process.env.ONLY ?? "").split(",").filter(Boolean).length !== 1) {
  console.error("TITLE 是一句话，只能配一种语言：ONLY=zh|en|ja");
  process.exit(2);
}
const locales = pick("ONLY", LOCALES, "语言");
const canvases = pick("CANVAS", CANVASES, "画布");

mkdirSync(TMP, { recursive: true });
mkdirSync(OUT, { recursive: true });
console.log(`${marks.length} 家：${marks.map((m) => m.key).join(" ")}`);
for (const canvas of canvases) {
  for (const locale of locales) await shoot(canvas, locale, marks, theme, mode);
}
