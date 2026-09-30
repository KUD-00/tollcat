#!/usr/bin/env python3
"""TollCat 口袋图标：一份构图，铺到所有槽位，外加启动过渡要用的分层图。

构图（1024 见方的「画面空间」）：
- 靛蓝底；
- 猫装在口袋里，露出耳朵、星星眼、小圆嘴和两只扒着袋口的爪子（几何来自 shared/cat.json）；
- 猫身后插着三枚通用服务圆牌：云 / 对话气泡（AI）/ 数据库。不属于任何一家——
  App 图标算商店元数据，别家的 logo 不能进（App Store 审核指南 5.2.1）；
- 口袋前片挡住猫和圆牌的下半截，袋口上方给圆牌压一道暗带，看起来是插进去的。

iOS 的方形图标整张都露出来，整组以袋口为中心放大 IOS_K；Android 的 adaptive icon
会被遮罩裁掉一圈，前景用原尺寸。启动画面（iOS 故事板、两端的过渡覆盖层、Android
系统启动图标）都用 iOS 这版构图：过渡要从同一张图起飞。

输出一律是烘焙好的绝对坐标：没有 CSS 变量、没有 <use>、没有 clipPath id、
没有 dasharray。Xcode 资源目录里的 SVG 和 Android VectorDrawable 只认这一路。
"""

from __future__ import annotations

import json
import math
import re
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = Path("/tmp/tollcat-icon-export")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

_CAT = json.loads((ROOT / "shared/cat.json").read_text(encoding="utf-8"))["paths"]
SIL = _CAT["silhouette"]
STAR_L, STAR_R = _CAT["eyeSparkle"]
MOUTH_O = _CAT["mouthO"]

GENERATED = "GENERATED — scripts/render-app-icon.py（猫的几何来自 shared/cat.json）。改脚本再跑，不要手改。"

# ---------------------------------------------------------------- 配色

VARIANTS = {
    "light": dict(bg="#5856D6", cat="#F4F4FF", pocket="#3E3CB2", stitch="#A7A5FF",
                  cloud="#FFB23F", ai="#5FE3B0", database="#FF7A6B", ink="#1F1E4D"),
    "dark": dict(bg="#0B0B12", cat="#D8DAE8", pocket="#1E1E30", stitch="#6C6AE8",
                 cloud="#F5A524", ai="#3FD19A", database="#F2665A", ink="#0B0B12"),
    # iOS 着色图标：系统只取亮度再上色，给一张黑底灰阶图。
    "tinted": dict(bg="#000000", cat="#FFFFFF", pocket="#2A2A2A", stitch="#8C8C8C",
                   cloud="#9A9A9A", ai="#C4C4C4", database="#707070", ink="#000000"),
}
INDIGO = VARIANTS["light"]["bg"]
SHADOW_ALPHA = 0.26

# ---------------------------------------------------------------- 构图

# 猫：cat.json 的剪影 + 星星眼（眼睛挖空，透出后面的底色）。
CAT_K, CAT_PIVOT, CAT_AT = 0.9, (512, 532), (512, 520)
EYE_K = 1.15
# 星星眼比 cat.json 的原位往上挪，腾出位置给嘴：嘴要露在袋口上面、两只爪子中间。
EYE_LIFT = 52
MOUTH_K, MOUTH_AT = 0.7, (512, 584)
# 口袋前片：袋口是一条二次曲线，两侧和底边出画。
POCKET_EDGE = ((84, 590), (512, 680), (940, 590))
STITCH_EDGE = ((130, 642), (512, 730), (894, 642))
STITCH_BOTTOM = 1060
STITCH_WIDTH, STITCH_DASH, STITCH_GAP = 14, 36, 24
PAWS = ((428, 632, 50, 34), (596, 632, 50, 34))
SHADOW_BAND = 30
GLYPH_K = 0.8


@dataclass(frozen=True)
class Token:
    kind: str  # 和 MeterDashboard.LaunchTokenKind 的 rawValue 一致
    cx: float
    cy: float
    r: float
    deg: float


# 画的顺序就是叠放顺序：数据库在 AI 那枚后面。
TOKENS = (
    Token("database", 872, 492, 66, 8),
    Token("cloud", 176, 540, 100, -10),
    Token("ai", 844, 540, 90, 8),
)

IOS_K = 1.15
IOS_CENTER = (512, 600)
# adaptive icon：108dp 画布，遮罩直径约 72dp。整幅按 0.76 居中，和预览里「圆形遮罩」一样大。
ANDROID_K = 0.8
# Android 系统启动图标：288dp 画布里 192dp 的圆。放的是 iOS 构图，圆刚好内切画面。
SPLASH_K = 192 / 288


# ---------------------------------------------------------------- 几何工具


@dataclass(frozen=True)
class Aff:
    """相似变换 p' = k·R(deg)·p + t。只用到均匀缩放和旋转，弧线才能照样换算。"""

    k: float = 1.0
    deg: float = 0.0
    tx: float = 0.0
    ty: float = 0.0

    def __call__(self, x: float, y: float) -> tuple[float, float]:
        a = math.radians(self.deg)
        c, s = math.cos(a), math.sin(a)
        return (self.k * (c * x - s * y) + self.tx, self.k * (s * x + c * y) + self.ty)

    def then(self, o: "Aff") -> "Aff":
        tx, ty = o(self.tx, self.ty)
        return Aff(self.k * o.k, self.deg + o.deg, tx, ty)


def about(k: float, pivot: tuple[float, float], at: tuple[float, float] | None = None, deg: float = 0.0) -> Aff:
    """以 pivot 为中心缩放 / 旋转，再把 pivot 放到 at。"""
    at = at or pivot
    base = Aff(k, deg)
    px, py = base(*pivot)
    return Aff(k, deg, at[0] - px, at[1] - py)


IDENT = Aff()
IOS = about(IOS_K, IOS_CENTER)
ANDROID_FG = about(ANDROID_K, (512, 512))
SPLASH = IOS.then(about(SPLASH_K, (512, 512)))


def num(v: float) -> str:
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


class Path2:
    """只收绝对命令 M / L / Q / C / A / Z；出图时整条过一遍变换。"""

    def __init__(self) -> None:
        self.cmds: list[tuple[str, tuple[float, ...]]] = []

    def M(self, x, y): self.cmds.append(("M", (x, y))); return self
    def L(self, x, y): self.cmds.append(("L", (x, y))); return self
    def Q(self, x1, y1, x, y): self.cmds.append(("Q", (x1, y1, x, y))); return self
    def C(self, x1, y1, x2, y2, x, y): self.cmds.append(("C", (x1, y1, x2, y2, x, y))); return self
    def A(self, rx, ry, rot, large, sweep, x, y): self.cmds.append(("A", (rx, ry, rot, large, sweep, x, y))); return self
    def Z(self): self.cmds.append(("Z", ())); return self

    def extend(self, other: "Path2") -> "Path2":
        self.cmds.extend(other.cmds)
        return self

    def d(self, t: Aff) -> str:
        out: list[str] = []
        for op, a in self.cmds:
            if op == "A":
                rx, ry, rot, large, sweep, x, y = a
                ex, ey = t(x, y)
                out.append(f"A{num(rx * t.k)} {num(ry * t.k)} {num(rot + t.deg)} {int(large)} {int(sweep)} {num(ex)} {num(ey)}")
            elif op == "Z":
                out.append("Z")
            else:
                pts = [t(a[i], a[i + 1]) for i in range(0, len(a), 2)]
                out.append(op + " ".join(f"{num(px)} {num(py)}" for px, py in pts))
        return " ".join(out)


def parse(d: str) -> Path2:
    """cat.json 的路径只有绝对 M / C / L / Q / Z。"""
    p = Path2()
    tokens = re.findall(r"[A-Za-z]|-?[\d.]+", d)
    i, op = 0, None
    arity = {"M": 2, "L": 2, "Q": 4, "C": 6, "Z": 0}
    while i < len(tokens):
        if tokens[i].isalpha():
            op = tokens[i]
            assert op in arity, f"unsupported path command {op}"
            i += 1
            if op == "Z":
                p.Z()
                continue
        n = arity[op]
        vals = [float(v) for v in tokens[i:i + n]]
        getattr(p, op)(*vals)
        i += n
        if op == "M":
            op = "L"
    return p


def transformed(p: Path2, t: Aff) -> Path2:
    out = Path2()
    for op, a in p.cmds:
        if op == "A":
            rx, ry, rot, large, sweep, x, y = a
            ex, ey = t(x, y)
            out.A(rx * t.k, ry * t.k, rot + t.deg, large, sweep, ex, ey)
        elif op == "Z":
            out.Z()
        else:
            pts = [c for i in range(0, len(a), 2) for c in t(a[i], a[i + 1])]
            getattr(out, op)(*pts)
    return out


def ellipse(cx, cy, rx, ry) -> Path2:
    return Path2().M(cx - rx, cy).A(rx, ry, 0, 1, 0, cx + rx, cy).A(rx, ry, 0, 1, 0, cx - rx, cy).Z()


def rect(x, y, w, h) -> Path2:
    return Path2().M(x, y).L(x + w, y).L(x + w, y + h).L(x, y + h).Z()


def rrect(x, y, w, h, r) -> Path2:
    return (Path2().M(x + r, y).L(x + w - r, y).A(r, r, 0, 0, 1, x + w, y + r)
            .L(x + w, y + h - r).A(r, r, 0, 0, 1, x + w - r, y + h)
            .L(x + r, y + h).A(r, r, 0, 0, 1, x, y + h - r)
            .L(x, y + r).A(r, r, 0, 0, 1, x + r, y).Z())


def quad(p0, p1, p2, t):
    u = 1 - t
    return (u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
            u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])


def pocket_edge_y(x: float) -> float:
    """袋口曲线在 x 处的高度。控制点居中，x 对参数是线性的。"""
    (x0, y0), (_, y1), (x2, _) = POCKET_EDGE
    u = (x - x0) / (x2 - x0)
    return y0 + 2 * u * (1 - u) * (y1 - y0)


def dashes(points: list[tuple[float, float]]) -> Path2:
    """沿折线按 STITCH_DASH / STITCH_GAP 切段，每段是一条小折线（dasharray 的烘焙版）。"""
    out = Path2()
    period = STITCH_DASH + STITCH_GAP
    walked = 0.0
    current: list[tuple[float, float]] = []
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        seg = math.hypot(bx - ax, by - ay)
        s = 0.0
        while s < seg:
            phase = (walked + s) % period
            on = phase < STITCH_DASH
            left = (STITCH_DASH - phase) if on else (period - phase)
            step = min(left, seg - s)
            f0, f1 = s / seg, (s + step) / seg
            p0 = (ax + (bx - ax) * f0, ay + (by - ay) * f0)
            p1 = (ax + (bx - ax) * f1, ay + (by - ay) * f1)
            if on:
                if not current:
                    current = [p0]
                current.append(p1)
            elif current:
                out.M(*current[0])
                for q in current[1:]:
                    out.L(*q)
                current = []
            s += step
        walked += seg
    if current:
        out.M(*current[0])
        for q in current[1:]:
            out.L(*q)
    return out


# ---------------------------------------------------------------- 画面元素


@dataclass
class El:
    d: str
    fill: str | None = None
    stroke: str | None = None
    width: float = 0.0
    evenodd: bool = False
    alpha: float = 1.0


def cat_path() -> Path2:
    cat = about(CAT_K, CAT_PIVOT, CAT_AT)
    eye_l = about(EYE_K, (436, 556), (428, 556 - EYE_LIFT))
    eye_r = about(EYE_K, (588, 556), (596, 556 - EYE_LIFT))
    mouth = about(MOUTH_K, (512, 668), MOUTH_AT)
    p = transformed(parse(SIL), cat)
    p.extend(transformed(parse(STAR_L), eye_l.then(cat)))
    p.extend(transformed(parse(STAR_R), eye_r.then(cat)))
    p.extend(transformed(parse(MOUTH_O), mouth.then(cat)))
    return p


def glyph_parts(kind: str) -> tuple[list[Path2], list[Path2], list[Path2]]:
    """通用服务图形，单位坐标 -1…1。返回（填充块，描边线，挖空点）。

    填充块分开画，重叠处才不会互相抵消；描边线和挖空点用圆牌自己的颜色画在图案上面。
    AI 那枚不用星芒：猫的眼睛已经是星星，旁边再来一颗会撞。用对话气泡，一眼是「和 AI 聊天」。
    """
    if kind == "cloud":
        return [ellipse(-.26, .08, .28, .28), ellipse(.08, -.08, .36, .36), ellipse(.36, .12, .22, .22),
                rrect(-.54, .06, 1.12, .3, .15)], [], []
    if kind == "ai":
        bubble = rrect(-.6, -.46, 1.2, .8, .3)
        tail = Path2().M(-.34, .26).L(-.44, .6).L(-.04, .3).Z()
        dots = [ellipse(x, -.06, .1, .1) for x in (-.28, 0, .28)]
        return [bubble, tail], [], dots
    if kind == "database":
        bands = [Path2().M(-.4, -.08).A(.4, .14, 0, 0, 0, .4, -.08), Path2().M(-.4, .14).A(.4, .14, 0, 0, 0, .4, .14)]
        return [rect(-.4, -.34, .8, .68), ellipse(0, -.34, .4, .14), ellipse(0, .34, .4, .14)], bands, []
    raise ValueError(kind)


def shadow_segment(tok: Token) -> Path2 | None:
    """袋口往上 SHADOW_BAND 那条暗带落在这枚圆牌上的部分：弓形，下面被口袋挡住。"""
    ax, bx = tok.cx - tok.r, tok.cx + tok.r
    ay, by = pocket_edge_y(ax) - SHADOW_BAND, pocket_edge_y(bx) - SHADOW_BAND
    dx, dy = bx - ax, by - ay
    fx, fy = ax - tok.cx, ay - tok.cy
    a = dx * dx + dy * dy
    b = 2 * (fx * dx + fy * dy)
    c = fx * fx + fy * fy - tok.r * tok.r
    disc = b * b - 4 * a * c
    if disc <= 0:
        return None
    t1 = (-b - math.sqrt(disc)) / (2 * a)
    t2 = (-b + math.sqrt(disc)) / (2 * a)
    left = (ax + dx * t1, ay + dy * t1)
    right = (ax + dx * t2, ay + dy * t2)
    line_y_at_center = ay + dy * (tok.cx - ax) / dx
    large = 1 if line_y_at_center < tok.cy else 0
    return Path2().M(*right).A(tok.r, tok.r, 0, large, 1, *left).Z()


def token_els(tok: Token, v: dict, t: Aff, mono: bool = False) -> list[El]:
    color = v[tok.kind]
    local = Aff(GLYPH_K * tok.r, tok.deg, tok.cx, tok.cy).then(t)
    fills, strokes, dots = glyph_parts(tok.kind)
    els: list[El] = []
    if not mono:
        els.append(El(ellipse(tok.cx, tok.cy, tok.r, tok.r).d(t), fill=color))
    ink = "#FFFFFF" if mono else v["ink"]
    els += [El(p.d(local), fill=ink) for p in fills]
    if not mono:
        els += [El(p.d(local), stroke=color, width=0.07 * local.k) for p in strokes]
        els += [El(p.d(local), fill=color) for p in dots]
        seg = shadow_segment(tok)
        if seg:
            els.append(El(seg.d(t), fill="#000000", alpha=SHADOW_ALPHA))
    return els


def pocket_els(v: dict, t: Aff, paws: bool = True) -> list[El]:
    (x0, y0), (qx, qy), (x2, y2) = POCKET_EDGE
    front = Path2().M(x0, y0).Q(qx, qy, x2, y2).L(x2, 1100).L(x0, 1100).Z()
    els = [El(front.d(t), fill=v["pocket"])]
    curve = [quad(*STITCH_EDGE, i / 400) for i in range(401)]
    (sx0, sy0), _, (sx2, sy2) = STITCH_EDGE
    stitch = dashes(curve)
    stitch.extend(dashes([(sx0, sy0), (sx0, STITCH_BOTTOM)]))
    stitch.extend(dashes([(sx2, sy2), (sx2, STITCH_BOTTOM)]))
    els.append(El(stitch.d(t), stroke=v["stitch"], width=STITCH_WIDTH * t.k))
    if paws:
        els += [El(ellipse(x, y, rx, ry).d(t), fill=v["cat"]) for x, y, rx, ry in PAWS]
    return els


def scene(variant: str, t: Aff, parts=("bg", "tokens", "cat", "pocket"), size: float = 1024) -> list[El]:
    v = VARIANTS[variant]
    els: list[El] = []
    if "bg" in parts:
        els.append(El(rect(0, 0, size, size).d(IDENT), fill=v["bg"]))
    if "tokens" in parts:
        for tok in TOKENS:
            els += token_els(tok, v, t)
    for tok in TOKENS:
        if f"token:{tok.kind}" in parts:
            els += token_els(tok, v, t)
    if "cat" in parts:
        els.append(El(cat_path().d(t), fill=v["cat"], evenodd=True))
    if "pocket" in parts:
        els += pocket_els(v, t)
    return els


# ---------------------------------------------------------------- 输出格式


def svg(els: list[El], w: float = 1024, h: float = 1024, clip_radius: float | None = None,
        root_attrs: str | None = None) -> str:
    body = []
    for e in els:
        a = [f'd="{e.d}"']
        if e.fill:
            a.append(f'fill="{e.fill}"')
            if e.evenodd:
                a.append('fill-rule="evenodd"')
            if e.alpha < 1:
                a.append(f'fill-opacity="{e.alpha}"')
        else:
            a.append('fill="none"')
        if e.stroke:
            a.append(f'stroke="{e.stroke}" stroke-width="{num(e.width)}" stroke-linecap="round" stroke-linejoin="round"')
        body.append(f"  <path {' '.join(a)}/>")
    inner = "\n".join(body)
    if clip_radius is not None:
        inner = (f'  <defs><clipPath id="r"><rect width="{num(w)}" height="{num(h)}" rx="{num(clip_radius)}"/></clipPath></defs>\n'
                 f'  <g clip-path="url(#r)">\n{inner}\n  </g>')
    head = root_attrs or f'xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {num(w)} {num(h)}" width="{num(w)}" height="{num(h)}"'
    return f"<svg {head}>\n{inner}\n</svg>\n"


def vector(els: list[El], comment: str, dp: float, w: float = 1024, h: float = 1024,
           clip: str | None = None, clip_els: list[El] | None = None) -> str:
    """VectorDrawable。clip 给了就把 clip_els（没给则全部）装进一个带 clip-path 的 group。"""

    def one(e: El, indent: str) -> str:
        a = [f'android:pathData="{e.d}"']
        if e.fill:
            a.append(f'android:fillColor="{e.fill}"')
            if e.evenodd:
                a.append('android:fillType="evenOdd"')
            if e.alpha < 1:
                a.append(f'android:fillAlpha="{e.alpha}"')
        if e.stroke:
            a.append(f'android:strokeColor="{e.stroke}"')
            a.append(f'android:strokeWidth="{num(e.width)}"')
            a.append('android:strokeLineCap="round"')
            a.append('android:strokeLineJoin="round"')
        sep = "\n" + indent + "    "
        return f"{indent}<path{sep}" + sep.join(a) + " />"

    inside = clip_els if clip_els is not None else els
    outside = [e for e in els if e not in inside] if clip_els is not None else []
    if clip:
        body = ("    <group>\n"
                f'        <clip-path android:pathData="{clip}" />\n'
                + "\n".join(one(e, "        ") for e in inside)
                + "\n    </group>")
        if outside:
            body += "\n" + "\n".join(one(e, "    ") for e in outside)
    else:
        body = "\n".join(one(e, "    ") for e in els)
    return f"""<!-- {GENERATED} {comment} -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="{num(dp * w / max(w, h))}dp"
    android:height="{num(dp * h / max(w, h))}dp"
    android:viewportWidth="{num(w)}"
    android:viewportHeight="{num(h)}">
{body}
</vector>
"""


# ---------------------------------------------------------------- 各个槽位


def icon_svg(variant: str, clip: bool = False) -> str:
    return svg(scene(variant, IOS), clip_radius=229 if clip else None)


def android_foreground() -> str:
    return vector(scene("light", ANDROID_FG, parts=("tokens", "cat", "pocket")),
                  "adaptive icon 前景层：口袋、猫、三枚服务圆牌，背景层是 ic_launcher_background 的靛蓝。", 108)


def android_monochrome() -> str:
    """主题图标（Android 13+）只有一种颜色：圆牌只留图案，猫和图案在袋口上方留一道缝，和口袋分开。"""
    t = ANDROID_FG
    v = VARIANTS["light"]
    above = []
    for tok in TOKENS:
        above += token_els(tok, v, t, mono=True)
    above.append(El(cat_path().d(t), fill="#FFFFFF", evenodd=True))
    (x0, y0), (qx, qy), (x2, y2) = POCKET_EDGE
    gap = 22
    region = (Path2().M(-200, -200).L(1224, -200).L(1224, y2 - gap).L(x2, y2 - gap)
              .Q(qx, qy - gap, x0, y0 - gap).L(-200, y0 - gap).Z())
    front = Path2().M(x0, y0).Q(qx, qy, x2, y2).L(x2, 1100).L(x0, 1100).Z()
    els = above + [El(front.d(t), fill="#FFFFFF")]
    return vector(els, "主题图标（Android 13+ 单色层），系统自己上色。", 108,
                  clip=region.d(t), clip_els=above)


def splash_icon(variant: str) -> str:
    r = 512 * SPLASH_K
    circle = ellipse(512, 512, r, r).d(IDENT)
    return vector(scene(variant, SPLASH, parts=("tokens", "cat", "pocket")),
                  f"Android 12+ 系统启动图标（{variant}）：iOS 构图缩进 192dp 的圆里，底色由 windowSplashScreenBackground 给。",
                  288, clip=circle)


def launch_layer_svg(variant: str, parts, bbox=None) -> str:
    if bbox is None:
        return svg(scene(variant, IOS, parts=parts))
    x, y, w, h = bbox
    t = IOS.then(Aff(1, 0, -x, -y))
    return svg(scene(variant, t, parts=parts, size=w), w, h)


def launch_layer_vector(variant: str, parts, name: str, bbox=None) -> str:
    if bbox is None:
        return vector(scene(variant, IOS, parts=parts), f"启动过渡的一层：{name}（{variant}），1024 画面空间，贴底铺满屏宽。", 360)
    x, y, w, h = bbox
    t = IOS.then(Aff(1, 0, -x, -y))
    return vector(scene(variant, t, parts=parts, size=w), f"启动过渡的一层：{name}（{variant}）。", 48, w, h)


def token_bbox(tok: Token) -> tuple[float, float, float, float]:
    cx, cy = IOS(tok.cx, tok.cy)
    r = tok.r * IOS.k
    return (cx - r, cy - r, 2 * r, 2 * r)


def launch_tokens() -> list[dict]:
    out = []
    for tok in TOKENS:
        cx, cy = IOS(tok.cx, tok.cy)
        out.append(dict(kind=tok.kind, x=round(cx, 2), y=round(cy, 2), r=round(tok.r * IOS.k, 2)))
    return out


def swift_geometry() -> str:
    rows = "\n".join(
        f'        LaunchPocketToken(kind: .{t["kind"]}, x: {t["x"]}, y: {t["y"]}, radius: {t["r"]}),'
        for t in launch_tokens()
    )
    return f"""// {GENERATED}
import MeterDashboard

/// 启动画面里三枚服务圆牌在画面里的位置（1024 见方，画面贴底、和屏幕一样宽）。
/// 顺序就是叠放顺序。图层图片在 `LaunchPocket.xcassets`，同一次生成。
enum LaunchPocketGeometry {{
    static let canvas: Double = 1024
    static let tokens: [LaunchPocketToken] = [
{rows}
    ]
}}
"""


def kotlin_geometry() -> str:
    rows = "\n".join(
        f'        LaunchPocketToken("{t["kind"]}", {t["x"]}f, {t["y"]}f, {t["r"]}f, R.drawable.launch_token_{t["kind"]}),'
        for t in launch_tokens()
    )
    return f"""// {GENERATED}
package com.zhechengqi.tollcat.launch

import com.zhechengqi.tollcat.R

/** 启动画面里三枚服务圆牌的位置（1024 见方，画面贴底、和屏幕一样宽）。顺序就是叠放顺序。 */
internal object LaunchPocketGeometry {{
    const val CANVAS = 1024f
    val tokens = listOf(
{rows}
    )
}}
"""


def colors_xml(variant: str) -> str:
    v = VARIANTS[variant]
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- {GENERATED} -->
<resources>
    <color name="launch_background">{v["bg"]}</color>
</resources>
"""


def colorset(light: str, dark: str) -> str:
    def comp(h: str) -> dict:
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
        return {"alpha": "1.000", "blue": f"{b:.3f}", "green": f"{g:.3f}", "red": f"{r:.3f}"}

    return json.dumps({
        "colors": [
            {"color": {"color-space": "srgb", "components": comp(light)}, "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "color": {"color-space": "srgb", "components": comp(dark)}, "idiom": "universal"},
        ],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n"


def imageset(name: str) -> str:
    return json.dumps({
        "images": [
            {"filename": f"{name}.svg", "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "filename": f"{name}-dark.svg", "idiom": "universal"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True},
    }, indent=2) + "\n"


def write_imageset(catalog: Path, name: str, light: str, dark: str) -> None:
    folder = catalog / f"{name}.imageset"
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    (folder / f"{name}.svg").write_text(light)
    (folder / f"{name}-dark.svg").write_text(dark)
    (folder / "Contents.json").write_text(imageset(name))


def write_colorset(catalog: Path, name: str) -> None:
    folder = catalog / f"{name}.colorset"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "Contents.json").write_text(colorset(VARIANTS["light"]["bg"], VARIANTS["dark"]["bg"]))


# ---------------------------------------------------------------- 位图


def chrome_shot(html: Path, png: Path, w: int, h: int) -> None:
    cmd = [
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        f"--window-size={w},{h}", "--default-background-color=00000000",
        f"--screenshot={png}", html.as_uri(),
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def raster_svg(svg_text: str, png: Path, size: int) -> Image.Image:
    html = OUT / f"_r{size}.html"
    html.write_text(f'<!DOCTYPE html><html><body style="margin:0">{svg_text}</body></html>')
    tmp = OUT / f"_r{size}.png"
    chrome_shot(html, tmp, 1024, 1024)
    im = Image.open(tmp).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    # 方形的 App / 商店图不要残留透明度。
    if im.getextrema()[3][0] >= 250:
        im = im.convert("RGB")
    im.save(png)
    return im if im.mode == "RGBA" else im.convert("RGBA")


def squircle(im: Image.Image, radius_ratio: float = 0.2237) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    r = int(w * radius_ratio)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=r, fill=255)
    im.putalpha(mask)
    return im


def brand_mark() -> str:
    return svg(scene("light", IOS), root_attrs='class="brand-mark" viewBox="0 0 1024 1024" aria-hidden="true"')


# ---------------------------------------------------------------- 安装


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    light_svg, dark_svg, tinted_svg = icon_svg("light"), icon_svg("dark"), icon_svg("tinted")
    (OUT / "app-icon.svg").write_text(light_svg)
    (OUT / "app-icon-dark.svg").write_text(dark_svg)
    (OUT / "app-icon-tinted.svg").write_text(tinted_svg)
    (OUT / "favicon.svg").write_text(icon_svg("light", clip=True))

    light = raster_svg(light_svg, OUT / "AppIcon.png", 1024)
    raster_svg(dark_svg, OUT / "AppIcon-dark.png", 1024)
    raster_svg(tinted_svg, OUT / "AppIcon-tinted.png", 1024)
    raster_svg(light_svg, OUT / "favicon-32.png", 32)
    raster_svg(light_svg, OUT / "apple-touch-icon.png", 180)
    raster_svg(light_svg, OUT / "icon-192.png", 192)
    raster_svg(light_svg, OUT / "icon-512.png", 512)

    # 分享卡左上角那颗。方图不带圆角——SwiftUI 用 continuous 圆角自己切，
    # 这里预先蒙一层 PIL 的普通圆角会和系统 squircle 差一圈。
    light.resize((512, 512), Image.Resampling.LANCZOS).convert("RGB").save(OUT / "BrandIcon.png")
    squircle(light.resize((512, 512), Image.Resampling.LANCZOS)).save(OUT / "icon-rounded.png")

    appicon = ROOT / "App/Resources/Assets.xcassets/AppIcon.appiconset"
    public = ROOT / "site/public"
    docs = ROOT / "docs/assets"
    shutil.copy2(OUT / "AppIcon.png", appicon / "AppIcon.png")
    shutil.copy2(OUT / "AppIcon-dark.png", appicon / "AppIcon-dark.png")
    shutil.copy2(OUT / "AppIcon-tinted.png", appicon / "AppIcon-tinted.png")
    # 手表同一张 1024：系统裁成圆，猫和圆牌都在圆里。手表只有这一个槽位。
    shutil.copy2(OUT / "AppIcon.png", ROOT / "Watch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    # Mac 槽位和 iOS 1024 同一张（asset catalog 里 idiom=mac 512@2x 指向它）。
    # 分享卡不自己画一只猫冒充图标：用同一张位图，改了图标这里跟着变。
    shutil.copy2(OUT / "BrandIcon.png", ROOT / "Packages/MeterKit/Sources/MeterDesign/Resources/BrandIcon.png")
    shutil.copy2(OUT / "favicon.svg", public / "favicon.svg")
    shutil.copy2(OUT / "favicon-32.png", public / "favicon-32.png")
    shutil.copy2(OUT / "apple-touch-icon.png", public / "apple-touch-icon.png")
    shutil.copy2(OUT / "icon-192.png", public / "icon-192.png")
    shutil.copy2(OUT / "icon-512.png", public / "icon-512.png")
    shutil.copy2(OUT / "icon-rounded.png", public / "icon.png")
    shutil.copy2(OUT / "app-icon.svg", public / "icon.svg")
    shutil.copy2(OUT / "app-icon.svg", docs / "app-icon.svg")
    shutil.copy2(OUT / "app-icon-dark.svg", docs / "app-icon-dark.svg")
    shutil.copy2(OUT / "app-icon-tinted.svg", docs / "app-icon-tinted.svg")
    (ROOT / "site/src/components/BrandMark.astro").write_text(brand_mark())
    # Windows 的磁贴、商店图和启动图都是同一张 512 方图。
    for name in ("Square150x150Logo", "Square44x44Logo", "StoreLogo", "Wide310x150Logo", "SplashScreen"):
        shutil.copy2(OUT / "icon-512.png", ROOT / f"Windows/app/Assets/{name}.png")

    # Android：launcher、系统启动图标、启动过渡的分层图。
    res = ROOT / "Android/app/src/main/res"
    drawable, night = res / "drawable", res / "drawable-night"
    night.mkdir(exist_ok=True)
    (drawable / "ic_launcher_foreground.xml").write_text(android_foreground())
    (drawable / "ic_launcher_monochrome.xml").write_text(android_monochrome())
    patch_android_background()
    for variant, folder in (("light", drawable), ("dark", night)):
        (folder / "splash_icon.xml").write_text(splash_icon(variant))
        (folder / "launch_pocket_cat.xml").write_text(launch_layer_vector(variant, ("cat",), "猫"))
        (folder / "launch_pocket_front.xml").write_text(launch_layer_vector(variant, ("pocket",), "口袋前片和爪子"))
        for tok in TOKENS:
            (folder / f"launch_token_{tok.kind}.xml").write_text(
                launch_layer_vector(variant, (f"token:{tok.kind}",), f"{tok.kind} 圆牌", token_bbox(tok)))
    (res / "values/launch_colors.xml").write_text(colors_xml("light"))
    (res / "values-night/launch_colors.xml").write_text(colors_xml("dark"))
    kotlin = ROOT / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/launch/LaunchPocketGeometry.kt"
    kotlin.parent.mkdir(exist_ok=True)
    kotlin.write_text(kotlin_geometry())

    # iOS 故事板：一张合好的全景图 + 底色。过渡覆盖层用 MeterFeatures 里的分层图。
    app_assets = ROOT / "App/Resources/Assets.xcassets"
    write_imageset(app_assets, "LaunchPocket",
                   launch_layer_svg("light", ("tokens", "cat", "pocket")),
                   launch_layer_svg("dark", ("tokens", "cat", "pocket")))
    write_colorset(app_assets, "LaunchBackground")
    overlay = ROOT / "Packages/MeterKit/Sources/MeterFeatures/Resources/LaunchPocket.xcassets"
    overlay.mkdir(parents=True, exist_ok=True)
    (overlay / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    write_colorset(overlay, "LaunchPocketBackground")
    write_imageset(overlay, "LaunchPocketCat", launch_layer_svg("light", ("cat",)), launch_layer_svg("dark", ("cat",)))
    write_imageset(overlay, "LaunchPocketFront", launch_layer_svg("light", ("pocket",)), launch_layer_svg("dark", ("pocket",)))
    for tok in TOKENS:
        box = token_bbox(tok)
        write_imageset(overlay, f"LaunchPocketToken-{tok.kind}",
                       launch_layer_svg("light", (f"token:{tok.kind}",), box),
                       launch_layer_svg("dark", (f"token:{tok.kind}",), box))
    swift = ROOT / "Packages/MeterKit/Sources/MeterFeatures/Launch/LaunchPocketGeometry.swift"
    swift.parent.mkdir(exist_ok=True)
    swift.write_text(swift_geometry())
    print("installed")


def patch_android_background() -> None:
    colors = ROOT / "Android/app/src/main/res/values/colors.xml"
    text = colors.read_text(encoding="utf-8")
    text = re.sub(
        r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]{6}(</color>)',
        rf"\g<1>{INDIGO}\g<2>",
        text,
    )
    colors.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
