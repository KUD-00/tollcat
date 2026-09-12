// App Store 宣传图：标题 + 真机机身，站点同源视觉。
//
// 机身是 Apple 官方 Product Bezel 里嵌好截图的透明 PNG（scripts/render-appstore-devices.py，
// 和落地页共用 scripts/apple_bezels.py）——以前这里是 CSS 画的一个圆角黑框，
// 同一个 App 在落地页和商店页长着两台不同的机器。
//
// 帧结构六种：center / tilt / iconwall / duo（横竖两台叠着）/ homescreen（主屏 mock-up）/
// sidebyside（字在左、竖着的机身在右），
// paper 与 indigo 两种底面，light / dark 两套主题（各用对应外观的截图）。
//
// 输入 .tmp-task-marketing/devices/ + docs/appstore/screenshots/（小组件那几格），
// 输出 docs/appstore/marketing/。输入和输出都**不进仓库**（见 .gitignore 末尾）：
// 商店素材只在本机，CI 上没有这些目录。
// 用法：node scripts/render-appstore-marketing.mjs           # 全量 84 张
//       ONLY=ipad13-* node scripts/render-appstore-marketing.mjs          # 只出 iPad 那一档
//       ONLY=ipad13-widgets-zh-light node ...                             # 只出一张
//       ONLY='*-widgets-*,ipad13-services-*' node ...                     # 逗号分隔，能用 *
//
// 名字就是 `<档>-<屏>-<语言>-<明暗>`：改哪张出哪张，不用为一处版式微调跑一整轮。
import { execFileSync, spawn } from "node:child_process";
import { mkdirSync, writeFileSync, existsSync, readFileSync, rmSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const SHOTS = path.join(ROOT, "docs/appstore/screenshots");
const OUT = path.join(ROOT, "docs/appstore/marketing");
const TMP = path.join(ROOT, ".tmp-task-marketing");
const DEVICES = path.join(TMP, "devices");
const MARQUEE = path.join(TMP, "marquee");

// 一格小组件多大、内容边距多少：和 App 里那一格同一份事实源。
const WIDGETS = JSON.parse(readFileSync(path.join(ROOT, "shared/widgets.json"), "utf8"));
const WIDGET_FRAMES = WIDGETS.frames;
const WIDGET_KINDS = WIDGETS.modules.filter((m) => m.sizes.length > 0).length;

// 接入分层的权威在 ProviderCatalog.swift；落地页这份是它的生成物。
// 宣传图只数「都能接」：完全支持并测过 + 理论完全支持。读数信箱和不接入不算。
const SUPPORT_TIERS = readFileSync(path.join(ROOT, "site/src/supportTiers.ts"), "utf8");

function countSupportTier(name) {
  const match = SUPPORT_TIERS.match(new RegExp(`${name}: \\[(.*?)]`, "s"));
  if (!match) {
    throw new Error(`supportTiers.ts 没有 ${name} 这一档`);
  }
  const keys = [...match[1].matchAll(/"([^"]+)"/g)].map((hit) => hit[1]);
  if (keys.length === 0) {
    throw new Error(`supportTiers.ts 的 ${name} 是空的`);
  }
  return keys.length;
}

const FULLY_SUPPORTED =
  countSupportTier("tested") + countSupportTier("theoretical");
// 229 → 220+：向下取整到十位。精确个数留给支持名单页，标题层只说下限。
const SERVICE_FLOOR = Math.floor(FULLY_SUPPORTED / 10) * 10;
if (SERVICE_FLOOR < 10) {
  throw new Error(`完全支持只有 ${FULLY_SUPPORTED} 家，不像能写进宣传图`);
}

function copyCount(screen) {
  if (screen === "services") return SERVICE_FLOOR;
  if (screen === "widgets") return WIDGET_KINDS;
  return null;
}

function copyLines(screen, locale) {
  const n = copyCount(screen);
  const lines = COPY[screen][locale].map((line) =>
    n == null ? line : line.replaceAll("{n}", String(n)),
  );
  if (lines.some((line) => line.includes("{n}"))) {
    throw new Error(`${screen}/${locale} 还有没填的 {n}`);
  }
  return lines;
}

// 标题走 BRAND 的标题层：短促、合法、三语各自原创；行尾不带句号。
// `{n}` 是这一屏自己的个数：小组件那页从 shared/widgets.json 数有小组件的模块，
// 服务那页从目录的完全支持向下取整到十位。写死一个数字，目录一长那行字就成了假话。
const COPY = {
  dashboard: {
    zh: ["一眼看出", "这个月花了多少"],
    en: ["See it at a glance", "What you spent this month"],
    ja: ["一目でわかる", "今月いくら使った"],
  },
  detail: {
    zh: ["钱花在哪了", "看得见"],
    en: ["See where", "the money went"],
    ja: ["どこに使ったか", "内訳まで"],
  },
  services: {
    zh: ["{n} 多家服务", "都能接"],
    en: ["Works with", "{n}+ services"],
    ja: ["{n} を超える", "サービスに対応"],
  },
  wizard: {
    zh: ["每家都有", "接入说明"],
    en: ["Step-by-step setup", "read-only keys"],
    ja: ["どのサービスにも", "手順ガイド付き"],
  },
  widgets: {
    zh: ["{n} 种小组件", "主屏上就看得见"],
    en: ["{n} widgets", "right on the Home Screen"],
    ja: ["ウィジェットは {n} 種類", "ホーム画面で見える"],
  },
};

// BRAND 红线：截图旁保留「演示数字」声明。
const NOTE = {
  zh: "图中为演示数据",
  en: "Shown with demo data",
  ja: "画面はデモデータです",
};

const HEADLINE_SIZE = { zh: 112, en: 92, ja: 104 };
const LANG_ATTR = { zh: "zh-Hans", en: "en", ja: "ja" };
const FONT_STACK = {
  zh: `"Bricolage Grotesque", "PingFang SC", sans-serif`,
  en: `"Bricolage Grotesque", "PingFang SC", sans-serif`,
  ja: `"Bricolage Grotesque", "Hiragino Sans", sans-serif`,
};
const FONT = path.join(
  ROOT,
  "site/node_modules/@fontsource-variable/bricolage-grotesque/files/bricolage-grotesque-latin-wght-normal.woff2",
);

// 底面配色：paper 承落地页纸墨，indigo 用品牌色当强调帧。
// drop 是投影：机身 PNG 背景透明，所以走 drop-shadow 而不是 box-shadow，
// 影子跟着机身轮廓走。
const SURFACES = {
  paper: {
    light: {
      bg: "linear-gradient(180deg, #ffffff 0%, #f2f2f7 100%)",
      ink: "#111111",
      note: "#5c5c5c",
      drop: "drop-shadow(0 24px 44px rgba(17, 17, 24, 0.26)) drop-shadow(0 4px 12px rgba(17, 17, 24, 0.10))",
    },
    dark: {
      bg: "linear-gradient(180deg, #17171c 0%, #0a0a0c 100%)",
      ink: "#f4f4f2",
      note: "#b4b4ae",
      drop: "drop-shadow(0 24px 48px rgba(0, 0, 0, 0.62)) drop-shadow(0 4px 12px rgba(0, 0, 0, 0.42))",
    },
  },
  indigo: {
    light: {
      bg: "linear-gradient(180deg, #605ee2 0%, #4b49c9 100%)",
      ink: "#ffffff",
      note: "rgba(255, 255, 255, 0.82)",
      drop: "drop-shadow(0 24px 48px rgba(20, 18, 60, 0.45)) drop-shadow(0 4px 12px rgba(20, 18, 60, 0.22))",
    },
    dark: {
      bg: "linear-gradient(180deg, #47449f 0%, #302e77 100%)",
      ink: "#ffffff",
      note: "rgba(255, 255, 255, 0.82)",
      drop: "drop-shadow(0 24px 48px rgba(0, 0, 0, 0.55)) drop-shadow(0 4px 12px rgba(0, 0, 0, 0.32))",
    },
  },
};

// 主屏 mock-up 的壁纸和那层毛玻璃底材。主屏上的 widget 截不到
// （simctl 不认识它），所以那一屏是搭出来的：壁纸和底材归这里，
// 一格格里的内容是 App 用 widget 扩展的同一份视图渲出来的。
const WALLPAPER = {
  light: {
    wallpaper:
      "radial-gradient(120% 90% at 22% 8%, #8f8cf5 0%, #6b68e8 42%, #4f4dc4 78%, #3f3da8 100%)",
    tile: "rgba(255, 255, 255, 0.88)",
    tileEdge: "rgba(255, 255, 255, 0.55)",
    statusInk: "#ffffff",
  },
  dark: {
    wallpaper:
      "radial-gradient(120% 90% at 22% 8%, #3a377f 0%, #26245a 44%, #15142f 80%, #0b0b18 100%)",
    tile: "rgba(24, 24, 30, 0.80)",
    tileEdge: "rgba(255, 255, 255, 0.14)",
    statusInk: "#ffffff",
  },
};

// 主屏上摆哪几格。位置是 pt（和真机主屏同一套坐标），左上角起算，
// 尺寸取自 `shared/widgets.json`——手机和 iPad 的一格不一样大，所以分两套。
//
// 手机上摆四格，挑的是**四种长得不一样的**：一个大数字、一张格子图、一只圆环、
// 一列服务；摆四格同一种（三个大数字）说明不了「不止一种」。机身下沿会被画布
// 切掉一点，所以最后一格的下缘留了余量。
//
// iPad 竖屏装得下**七格**，正好是全部七块——标题说「7 种」，图上就摆得出七种。
const HOME = {
  phone: {
    // 6.9" iPhone：440×956pt，@3x。
    screen: [440, 956],
    scale: 3,
    statusInset: 44,
    statusHeight: 65,
    tiles: [
      { module: "monthToDate", size: "small", x: 38, y: 84 },
      { module: "heatmap", size: "small", x: 232, y: 84 },
      { module: "composition", size: "medium", x: 38, y: 280 },
      { module: "services", size: "large", x: 38, y: 478 },
    ],
  },
  pad: {
    // 11" iPad Pro 竖屏：834×1194pt，@2x。两列，行距 30，列距 30。
    screen: [834, 1194],
    scale: 2,
    statusInset: 46,
    statusHeight: 48,
    tiles: [
      { module: "heatmap", size: "small", x: 60, y: 200 },
      { module: "budget", size: "small", x: 247, y: 200 },
      { module: "monthToDate", size: "medium", x: 432, y: 200 },
      { module: "categories", size: "large", x: 60, y: 385 },
      { module: "services", size: "large", x: 432, y: 385 },
      { module: "composition", size: "medium", x: 60, y: 757 },
      { module: "subscriptions", size: "medium", x: 432, y: 757 },
    ],
  },
};

// 画布：一档商店尺寸一张。
//
// 帧的坐标一律写成**画布的比例**，不是像素——6.5" 档和 6.9" 档只是同一版式的
// 两个尺寸，以前两份手工缩过的像素表迟早会各改各的。
const IPHONE_FRAMES = {
  dashboard: { surface: "paper", kind: "center", devices: [{ shot: "iphone69", width: 0.882, top: 0.238 }] },
  detail: {
    surface: "indigo",
    kind: "tilt",
    // 微倾的机身横向要多占 高×sin(角度)：宽度得留出这一截，
    // 不然画布会把上面那个角削成一条斜边（看起来像出错，不像构图）。
    devices: [{ shot: "iphone69", width: 0.876, top: 0.240, tilt: -3 }],
  },
  services: {
    surface: "paper",
    kind: "iconwall",
    wall: { top: 0.241, height: 0.0293, gap: 0.0091, offsets: [-0.045, 0.03, -0.098] },
    devices: [{ shot: "iphone69", width: 0.882, top: 0.35 }],
  },
  wizard: {
    surface: "indigo",
    kind: "tilt",
    devices: [{ shot: "iphone69", width: 0.876, top: 0.240, tilt: 3 }],
  },
  widgets: {
    surface: "paper",
    kind: "homescreen",
    devices: [
      {
        idiom: "phone",
        chrome: {
          light: "iphone-17-pro-max-silver",
          dark: "iphone-17-pro-max-deep-blue",
        },
        width: 0.882,
        top: 0.238,
      },
    ],
  },
};

const CANVASES = [
  {
    // 6.9" 档（1320×2868）：选传，Pro Max 用户拿到原生分辨率，不传则 ASC 拿 6.5" 放大。
    key: "iphone69",
    width: 1320,
    height: 2868,
    scale: 1,
    headBottom: 56,
    headHeight: 644,
    frames: IPHONE_FRAMES,
  },
  {
    // 6.5" 档（1284×2778）：ASC 版本页的必填档。素材同为 6.9"，整版按比例缩。
    key: "iphone65",
    width: 1284,
    height: 2778,
    scale: 0.973,
    headBottom: 54,
    headHeight: 626,
    frames: IPHONE_FRAMES,
  },
  {
    // ASC 的 iPad 档位叫「13-inch display」，要 2752×2064——那是**画布**尺寸。
    // 画布里摆的是 11" 机身：多数人手上那台就是它，版式也更密。
    //
    // 横屏画布塞不下图标墙；换来的是横竖两台并排——iPad 上这两种拿法都常见，
    // 只给一种是漏掉一半。
    key: "ipad13",
    width: 2752,
    height: 2064,
    scale: 0.92,
    // 横构图两行标题就有约 300 高。headHeight 340 时中文只剩十几像素顶距，
    // 字像贴在画布上沿。标题是 flex-end 贴这块的底，加高这一块等于把字往下落。
    headBottom: 40,
    headHeight: 460,
    frames: {
      // 第一张就把横竖两台摆出来：iPad 上这两种拿法都常见，只给一种是漏掉一半。
      dashboard: {
        surface: "paper",
        kind: "duo",
        devices: [
          { shot: "ipad11", width: 0.700, center: 0.365, top: 0.245 },
          { shot: "ipad11p", width: 0.360, center: 0.768, top: 0.280 },
        ],
      },
      detail: {
        surface: "indigo",
        kind: "tilt",
        // 机身跟着标题区下移，不然微倾的上沿会顶到字。
        devices: [{ shot: "ipad11", width: 0.810, top: 0.245, tilt: -2 }],
      },
      // 图标墙和 iPhone 那页同一堵，横过来铺满画布——4:3 反而比竖构图更适合它。
      // 横屏是分栏壳，右半边挂着选中那一家的详情（截图那趟带 -open-provider-detail=）。
      services: {
        surface: "paper",
        kind: "iconwall",
        wall: { top: 0.242, height: 0.0465, gap: 0.0102, offsets: [-0.038, 0.026, -0.082] },
        devices: [{ shot: "ipad11", width: 0.750, top: 0.424 }],
      },
      // 只有一台竖着的机身：字排到它左边，别压在头顶。
      wizard: {
        surface: "indigo",
        kind: "sidebyside",
        devices: [{ shot: "ipad11p", width: 0.460, center: 0.708, top: 0.069 }],
      },
      // iPad 竖屏的主屏一次摆得下七格——七块模块全在上面。
      widgets: {
        surface: "paper",
        kind: "sidebyside",
        devices: [
          {
            idiom: "pad",
            chrome: {
              light: "ipad-pro-11-silver-portrait",
              dark: "ipad-pro-11-space-black-portrait",
            },
            width: 0.460,
            center: 0.708,
            top: 0.069,
          },
        ],
      },
    },
  },
];

function deviceFile(shot, screen, locale, theme) {
  return path.join(DEVICES, `${shot}-${screen}-${locale}-${theme}.png`);
}

function widgetFile(idiom, module, size, locale, theme) {
  return path.join(SHOTS, `widget-${idiom}-${module}-${size}-${locale}-${theme}.png`);
}

/// 一台机身。`center` 是它在画布上的横向中点（比例），缺省居中。
function deviceHTML(canvas, spec, screen, locale, theme, index) {
  const width = Math.round(spec.width * canvas.width);
  const top = Math.round(spec.top * canvas.height);
  const center = Math.round((spec.center ?? 0.5) * canvas.width);
  const rotate = spec.tilt ? ` rotate(${spec.tilt}deg)` : "";
  const src = deviceFile(spec.shot, screen, locale, theme);
  return `  <img class="device" style="left:${center}px; top:${top}px; width:${width}px; transform:translateX(-50%)${rotate}; z-index:${index + 1};" src="file://${src}" alt="">`;
}

/// 主屏 mock-up：壁纸 + 状态栏 + 一格格小组件，机壳当叠层盖上去。
function homeScreenHTML(canvas, spec, locale, theme) {
  const chromeName = spec.chrome[theme];
  const manifest = JSON.parse(readFileSync(path.join(DEVICES, "chrome.json"), "utf8"));
  const chrome = manifest[chromeName];
  if (!chrome) throw new Error(`chrome.json 里没有 ${chromeName}`);
  const [cw, ch] = chrome.size;
  const [hx, hy, hw, hh] = chrome.hole;
  // 开孔的包围盒是方的，屏幕四角是圆的：不切这一刀，机身外面会露出四个壁纸小三角。
  // 半径由 render-appstore-devices.py 从机壳的 alpha 量出来。
  const radius = chrome.cornerRadius;
  const width = Math.round(spec.width * canvas.width);
  const top = Math.round(spec.top * canvas.height);
  // 机壳按 width 缩，屏幕那块跟着缩；主屏内容按 pt 排，再一次性缩到屏幕像素宽。
  const k = width / cw;
  const screenW = hw * k;
  const home = WALLPAPER[theme];
  const plan = HOME[spec.idiom];
  // 主屏那一层按 pt 排版，再一次性缩到屏幕在画布上的像素宽。
  const pt = screenW / (hw / plan.scale);

  const tiles = plan.tiles.map((tile) => {
    const [fw, fh] = WIDGET_FRAMES[spec.idiom][tile.size];
    const margin = WIDGET_FRAMES.contentMargin;
    const src = widgetFile(spec.idiom, tile.module, tile.size, locale, theme);
    if (!existsSync(src)) throw new Error(`缺小组件素材：${path.basename(src)}`);
    return `      <div class="tile" style="left:${tile.x}px; top:${tile.y}px; width:${fw}px; height:${fh}px; padding:${margin}px;"><img src="file://${src}" alt=""></div>`;
  }).join("\n");

  const center = Math.round((spec.center ?? 0.5) * canvas.width);
  return `  <div class="stage" style="left:${center}px; top:${top}px; width:${width}px; transform:translateX(-50%);">
    <div class="screen" style="left:${(hx / cw) * 100}%; top:${(hy / ch) * 100}%; width:${(hw / cw) * 100}%; height:${(hh / ch) * 100}%; border-radius:${(radius * k).toFixed(1)}px;">
      <div class="home" style="width:${plan.screen[0]}px; height:${plan.screen[1]}px; transform:scale(${pt}); background:${home.wallpaper};">
        <div class="status" style="height:${plan.statusHeight}px; padding:0 ${plan.statusInset}px;">
          <span class="clock">9:41</span>
          <span class="signals">
            <svg viewBox="0 0 18 12" class="bars"><rect x="0" y="8" width="3" height="4" rx="0.6" fill="currentColor"/><rect x="5" y="5.5" width="3" height="6.5" rx="0.6" fill="currentColor"/><rect x="10" y="3" width="3" height="9" rx="0.6" fill="currentColor"/><rect x="15" y="0.5" width="3" height="11.5" rx="0.6" fill="currentColor"/></svg>
            <svg viewBox="0 0 16 12" class="wifi"><path d="M1.2 4.6a10 10 0 0 1 13.6 0M3.6 7a6.4 6.4 0 0 1 8.8 0M8 11.1a1.15 1.15 0 1 1 0-2.3 1.15 1.15 0 0 1 0 2.3Z" fill="none" stroke="currentColor" stroke-width="1.35" stroke-linecap="round"/></svg>
            <svg viewBox="0 0 27 12" class="battery"><rect x="0.6" y="1.6" width="22" height="8.8" rx="2.2" fill="none" stroke="currentColor" stroke-width="1.2"/><rect x="2.2" y="3.2" width="18.8" height="5.6" rx="1" fill="currentColor"/><rect x="23.4" y="4.1" width="2.2" height="3.8" rx="0.7" fill="currentColor"/></svg>
          </span>
        </div>
${tiles}
      </div>
    </div>
    <img class="chrome" src="file://${path.join(DEVICES, `chrome-${chromeName}.png`)}" alt="">
  </div>`;
}

function iconWallHTML(canvas, frame, theme) {
  const wall = frame.wall;
  const rows = wall.offsets
    .map((offset, row) => {
      const shift = Math.round(offset * canvas.width);
      return `    <div class="wallrow" style="transform:translateX(${shift}px)"><img src="file://${path.join(MARQUEE, `marquee-${theme}-${row}.svg`)}" alt=""></div>`;
    })
    .join("\n");
  return `  <div class="wall" style="top:${Math.round(wall.top * canvas.height)}px; gap:${Math.round(wall.gap * canvas.width)}px;">
${rows}
  </div>`;
}

function html(canvas, screen, locale, theme) {
  const frame = canvas.frames[screen];
  const palette = SURFACES[frame.surface][theme];
  const lines = copyLines(screen, locale);
  const size = Math.round(HEADLINE_SIZE[locale] * canvas.scale);
  const noteSize = Math.round(34 * canvas.scale);
  const tracking = locale === "en" ? "-0.02em" : "0";
  const home = WALLPAPER[theme];

  const wall = frame.kind === "iconwall" ? "\n" + iconWallHTML(canvas, frame, theme) : "";
  const stage =
    frame.devices[0].chrome
      ? homeScreenHTML(canvas, frame.devices[0], locale, theme)
      : frame.devices
          .map((spec, index) => deviceHTML(canvas, spec, screen, locale, theme, index))
          .join("\n");

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
  background: ${palette.bg};
}
.head {
  position: absolute;
  top: 0; left: 0; right: 0;
  height: ${canvas.headHeight}px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-end;
  padding-bottom: ${canvas.headBottom}px;
  z-index: 20;
}
/* 画布是 4:3，机身只有一台竖的：标题压在头顶会让两边空一大片。
   竖机往右站，字排到它左边，一横一竖把画面填满。 */
.head.side {
  top: 0;
  bottom: 0;
  left: ${Math.round(0.062 * canvas.width)}px;
  right: auto;
  width: ${Math.round(0.375 * canvas.width)}px;
  height: auto;
  align-items: flex-start;
  justify-content: center;
  padding-bottom: 0;
}
.head.side h1 { text-align: left; }
.head.side .note { align-self: flex-start; }
h1 {
  font-family: ${FONT_STACK[locale]};
  font-size: ${size}px;
  font-weight: 640;
  line-height: 1.16;
  letter-spacing: ${tracking};
  color: ${palette.ink};
  text-align: center;
}
.note {
  margin-top: ${Math.round(30 * canvas.scale)}px;
  font-family: ${FONT_STACK[locale]};
  font-size: ${noteSize}px;
  font-weight: 500;
  color: ${palette.note};
}
.device, .stage {
  position: absolute;
  filter: ${palette.drop};
}
.device { display: block; height: auto; }
.stage img.chrome { display: block; width: 100%; height: auto; position: relative; z-index: 2; }
.screen { position: absolute; overflow: hidden; z-index: 1; }
.home {
  position: relative;
  transform-origin: top left;
}
.status {
  position: absolute;
  left: 0; right: 0; top: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: ${home.statusInk};
  font-family: ${FONT_STACK.en};
  font-weight: 620;
  font-size: 17px;
}
.signals { display: flex; align-items: center; gap: 6px; }
.signals svg { display: block; height: 12px; }
.bars { width: 18px; }
.wifi { width: 16px; }
.battery { width: 27px; }
.tile {
  position: absolute;
  border-radius: ${WIDGET_FRAMES.cornerRadius}px;
  background: ${home.tile};
  box-shadow: inset 0 0 0 0.5px ${home.tileEdge}, 0 6px 18px rgba(0, 0, 0, 0.18);
  overflow: hidden;
}
.tile img { display: block; width: 100%; height: 100%; }
.wall {
  position: absolute;
  left: 0; right: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  -webkit-mask-image: linear-gradient(90deg, transparent 0, #000 10%, #000 90%, transparent 100%);
  mask-image: linear-gradient(90deg, transparent 0, #000 10%, #000 90%, transparent 100%);
}
.wallrow img {
  display: block;
  height: ${Math.round((canvas.frames.services?.wall?.height ?? 0) * canvas.height)}px;
  width: auto;
  max-width: none;
}
</style>
</head>
<body>
  <div class="head${frame.kind === "sidebyside" ? " side" : ""}">
    <h1>${lines.join("<br>")}</h1>
    <div class="note">${NOTE[locale]}</div>
  </div>${wall}
${stage}
</body>
</html>`;
}

// 一次开几个 Chrome。每个进程有自己的 --user-data-dir，互不打架；
// 再多就开始互相抢 CPU，单张反而变慢。
const LANES = Number(process.env.LANES ?? 4);
// 图写完到进程真的退出之间能差好几十秒（--headless=new 截完常常不退），
// 所以不等它退，等**文件**：大小连着两次不变就算写完，然后杀掉。
const POLL_MS = 200;
const SHOOT_TIMEOUT_MS = 60_000;

mkdirSync(OUT, { recursive: true });
mkdirSync(TMP, { recursive: true });

// 图标墙 SVG 从落地页源码现场求值，保持和站点一个事实源。
execFileSync("node", [path.join(ROOT, "scripts/dump-marquee-svgs.cjs"), MARQUEE], { stdio: "pipe" });

/// `ONLY` 里的一条模式配不配得上这个名字。`*` 是通配，其余原样比。
function matches(pattern, name) {
  const escaped = pattern
    .trim()
    .replace(/[.+?^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*");
  return new RegExp(`^${escaped}$`).test(name);
}

function wanted(name) {
  // PREFIX=iphone69 是 ONLY=iphone69-* 的老写法，留着不碍事。
  if (process.env.PREFIX && !name.startsWith(`${process.env.PREFIX}-`)) return false;
  const only = process.env.ONLY;
  if (!only) return true;
  return only.split(",").some((pattern) => matches(pattern, name));
}

/// 要渲的那一张：HTML 先写出来，Chrome 由 lane 去跑。
function plan() {
  const jobs = [];
  for (const canvas of CANVASES) {
    for (const screen of Object.keys(canvas.frames)) {
      for (const locale of ["zh", "en", "ja"]) {
        for (const theme of ["light", "dark"]) {
          const name = `${canvas.key}-${screen}-${locale}-${theme}`;
          if (!wanted(name)) continue;
          const frame = canvas.frames[screen];
          const missing = frame.devices
            .filter((spec) => spec.shot)
            .map((spec) => deviceFile(spec.shot, screen, locale, theme))
            .filter((file) => !existsSync(file));
          if (missing.length) {
            console.error(`missing device: ${missing.map((f) => path.basename(f)).join(", ")}`);
            process.exitCode = 1;
            continue;
          }
          const page = path.join(TMP, `${name}.html`);
          try {
            writeFileSync(page, html(canvas, screen, locale, theme));
          } catch (error) {
            console.error(`FAILED ${name}: ${error.message}`);
            process.exitCode = 1;
            continue;
          }
          jobs.push({ name, page, canvas, out: path.join(OUT, `${name}.png`) });
        }
      }
    }
  }
  return jobs;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

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

async function shoot(job) {
  // 先把旧图删掉：`settledFile` 认的是「文件在、大小连着两次不变」，
  // 上一轮的产物摆在那儿就正好满足——于是 Chrome 还没落笔就被判定写完杀掉，
  // 旧图原样留下来当新图交上去（HTML 是新的，PNG 是旧的，最难发现的那种）。
  rmSync(job.out, { force: true });
  const child = spawn(CHROME, [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=1",
    "--no-first-run",
    "--no-default-browser-check",
    `--user-data-dir=${path.join(TMP, `profile-${job.name}`)}`,
    "--allow-file-access-from-files",
    `--window-size=${job.canvas.width},${job.canvas.height}`,
    "--virtual-time-budget=4000",
    "--timeout=15000",
    `--screenshot=${job.out}`,
    `file://${job.page}`,
  ], { stdio: "ignore" });
  const exited = new Promise((resolve) => child.once("exit", resolve));
  await Promise.race([
    settledFile(job.out, Date.now() + SHOOT_TIMEOUT_MS),
    exited,
  ]);
  child.kill("SIGKILL");
  await exited;
  if (!existsSync(job.out)) {
    console.error(`FAILED ${job.name}`);
    process.exitCode = 1;
    return;
  }
  // Chrome 超时会留下上一张旧图。尺寸对不上就当失败，别把竖屏旧图当新横屏交上去。
  const ident = execFileSync("sips", ["-g", "pixelWidth", "-g", "pixelHeight", job.out], { encoding: "utf8" });
  const width = Number(/pixelWidth:\s*(\d+)/.exec(ident)?.[1]);
  const height = Number(/pixelHeight:\s*(\d+)/.exec(ident)?.[1]);
  if (width !== job.canvas.width || height !== job.canvas.height) {
    console.error(
      `FAILED ${job.name}: ${width}×${height}, expected ${job.canvas.width}×${job.canvas.height}`,
    );
    process.exitCode = 1;
    return;
  }
  console.log(`wrote ${job.name}.png`);
}

const queue = plan();
let next = 0;
await Promise.all(
  Array.from({ length: Math.min(LANES, queue.length) }, async () => {
    while (next < queue.length) {
      await shoot(queue[next++]);
    }
  }),
);
