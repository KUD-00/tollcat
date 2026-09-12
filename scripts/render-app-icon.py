#!/usr/bin/env python3
"""Export the chosen TollCat icon (face crop, sparkle, O×0.75, sky $) to every slot.

猫的几何从 shared/cat.json 读（和 App 里的 CatArtwork 同一份），本脚本只持有
图标独有的东西：$ 字形、构图 transform、配色、各槽位尺寸。输出物包括
App / site / docs 的所有位图与 SVG、site 的 BrandMark.astro，以及 Android 的
adaptive icon 前景与单色层。
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = Path("/tmp/tollcat-icon-export")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

_CAT = json.loads((ROOT / "shared/cat.json").read_text(encoding="utf-8"))["paths"]
SIL = _CAT["silhouette"]
STAR_L, STAR_R = _CAT["eyeSparkle"]
MOUTH_O = _CAT["mouthO"]
# SFNSRounded `dollar`. Font y-up; placed with scale(s,-s).
DOLLAR = (
    "M618 -160Q593 -160 575.5 -143.5Q558 -127 558 -100V1543Q558 1570 575.5 1586.5Q593 1603 "
    "618 1603Q644 1603 661.0 1586.5Q678 1570 678 1543V-100Q678 -127 661.0 -143.5Q644 -160 "
    "618 -160ZM622 26Q507 26 404.5 61.0Q302 96 229.5 163.5Q157 231 131 328Q128 339 126.5 "
    "350.5Q125 362 125 373Q125 409 148.0 431.5Q171 454 207 454Q238 454 261.0 437.0Q284 420 "
    "296 383Q315 325 354.0 279.5Q393 234 459.0 208.0Q525 182 624 182Q737 182 805.5 211.5Q874 "
    "241 905.0 291.0Q936 341 936 404Q936 487 884.5 541.5Q833 596 684 632L535 668Q348 713 "
    "250.0 800.5Q152 888 152 1036Q152 1153 213.5 1238.5Q275 1324 381.0 1370.5Q487 1417 622 "
    "1417Q734 1417 829.5 1380.5Q925 1344 991.5 1276.5Q1058 1209 1083 1116Q1086 1105 1087.5 "
    "1093.5Q1089 1082 1089 1071Q1089 1035 1066.0 1012.5Q1043 990 1007 990Q972 990 950.5 "
    "1009.5Q929 1029 918 1061Q893 1128 852.5 1172.0Q812 1216 755.0 1238.5Q698 1261 622 "
    "1261Q525 1261 459.0 1230.5Q393 1200 359.5 1151.5Q326 1103 326 1048Q326 975 378.0 "
    "919.5Q430 864 560 832L709 796Q902 750 1006.0 663.0Q1110 576 1110 418Q1110 288 1042.0 "
    "201.0Q974 114 863.0 70.0Q752 26 622 26Z"
)
# Flattened and dropped so the $ has a real sky. scaleY/scaleX ≈ 0.82.
TF_SKY = "translate(512 652) scale(1.78 1.46) translate(-512 -500)"
# Larger, slight counterclockwise tilt. Center sits in the extra sky.
DOLLAR_TF = "translate(512 196) rotate(-12) scale(0.108 -0.108) translate(-617.5 -721.5)"
EYE_SCALE = 1.15

INDIGO = "#5856D6"
PALE = "#F4F4FF"
DARK_BG = "#0B0B12"
DARK_CAT = "#D8DAE8"


def cat_mark(cat: str, punch: str) -> str:
    return f'''<g transform="{DOLLAR_TF}" fill="{cat}">
    <path d="{DOLLAR}"/>
  </g>
  <g transform="{TF_SKY}">
    <path d="{SIL}" fill="{cat}"/>
    <g transform="translate(428 556) scale({EYE_SCALE}) translate(-436 -556)">
      <path d="{STAR_L}" fill="{punch}"/>
    </g>
    <g transform="translate(596 556) scale({EYE_SCALE}) translate(-588 -556)">
      <path d="{STAR_R}" fill="{punch}"/>
    </g>
    <g transform="translate(512 682) scale(0.72) translate(-512 -682)">
      <path d="{MOUTH_O}" fill="{punch}"/>
    </g>
  </g>'''


def icon_svg(bg: str, cat: str, punch: str, clip: bool = False) -> str:
    clip_defs = ""
    clip_open = clip_close = ""
    if clip:
        clip_defs = '<defs><clipPath id="r"><rect width="1024" height="1024" rx="229" ry="229"/></clipPath></defs>'
        clip_open = '<g clip-path="url(#r)">'
        clip_close = "</g>"
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  {clip_defs}
  {clip_open}
  <rect width="1024" height="1024" fill="{bg}"/>
  {cat_mark(cat, punch)}
  {clip_close}
</svg>
'''


LIGHT = icon_svg(INDIGO, PALE, INDIGO)
DARK = icon_svg(DARK_BG, DARK_CAT, DARK_BG)
TINTED = icon_svg("#000000", "#FFFFFF", "#000000")
FAVICON = icon_svg(INDIGO, PALE, INDIGO, clip=True)


def chrome_shot(html: Path, png: Path, w: int, h: int, scale: int = 1) -> None:
    cmd = [
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        f"--window-size={w},{h}", "--default-background-color=00000000",
        f"--screenshot={png}", html.as_uri(),
    ]
    if scale != 1:
        cmd.insert(-1, f"--force-device-scale-factor={scale}")
    subprocess.run(cmd, check=True, capture_output=True)


def raster_svg(svg: str, png: Path, size: int) -> Image.Image:
    html = OUT / f"_r{size}.html"
    html.write_text(f'<!DOCTYPE html><html><body style="margin:0">{svg}</body></html>')
    tmp = OUT / f"_r{size}.png"
    chrome_shot(html, tmp, 1024, 1024)
    im = Image.open(tmp).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    # Drop residual alpha on square app/store assets.
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


def _transform_path(d: str, ax: float, bx: float, ay: float, by: float, s: float) -> str:
    """对纯绝对坐标 path（M/C/L 对）做 p' = a + s*(p - b)。眼嘴都是 C 命令，没有弧。

    命令字母常和数字连写（`M512 630`），先拆再按 x/y 交替变换。
    """
    tokens = re.findall(r"[A-Za-z]|-?[\d.]+", d)
    out: list[str] = []
    index = 0
    for token in tokens:
        if token.isalpha():
            out.append(token)
            continue
        value = float(token)
        if index % 2 == 0:
            value = ax + s * (value - bx)
        else:
            value = ay + s * (value - by)
        out.append(f"{value:.1f}".rstrip("0").rstrip("."))
        index += 1
    return " ".join(out)


def _android_cat_path() -> str:
    """剪影 + 眼嘴挖空拼成一条 even-odd path（VectorDrawable 的组变换没法参与挖空）。"""
    eye_l = _transform_path(STAR_L, 428, 436, 556, 556, EYE_SCALE)
    eye_r = _transform_path(STAR_R, 596, 588, 556, 556, EYE_SCALE)
    mouth = _transform_path(MOUTH_O, 512, 512, 682, 682, 0.72)
    return " ".join([SIL, eye_l, eye_r, mouth])


def _android_vector(cat_color: str, dollar_color: str, comment: str) -> str:
    """adaptive icon 的一层。1024 视口缩到 72/108 安全区，构图 transform 与 SVG 逐项对应：

    - 外层：整幅 1024 居中缩到安全区（circle mask 直径约 66/108）。
    - $：SVG `translate(512 196) rotate(-12) scale(0.108 -0.108) translate(-617.5 -721.5)`
      换成 VectorDrawable 的 T(t+p)·R·S·T(-p)。
    - 天空组：SVG `TF_SKY` 同法换算。
    """
    safe = 72 / 108
    outer_t = f"{1024 * (1 - safe) / 2:.2f}"
    return f"""<!-- GENERATED — scripts/render-app-icon.py（几何来自 shared/cat.json）。{comment} -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="1024"
    android:viewportHeight="1024">
    <group
        android:scaleX="{safe:.6f}"
        android:scaleY="{safe:.6f}"
        android:translateX="{outer_t}"
        android:translateY="{outer_t}">
        <group
            android:pivotX="617.5"
            android:pivotY="721.5"
            android:rotation="-12"
            android:scaleX="0.108"
            android:scaleY="-0.108"
            android:translateX="-105.5"
            android:translateY="-525.5">
            <path
                android:fillColor="{dollar_color}"
                android:pathData="{DOLLAR}" />
        </group>
        <group
            android:pivotX="512"
            android:pivotY="500"
            android:scaleX="1.78"
            android:scaleY="1.46"
            android:translateX="0"
            android:translateY="152">
            <path
                android:fillColor="{cat_color}"
                android:fillType="evenOdd"
                android:pathData="{_android_cat_path()}" />
        </group>
    </group>
</vector>
"""


def android_foreground() -> str:
    return _android_vector(PALE, PALE, "前景层：猫脸 crop + 天上的 $，挖空处透出 background 的靛蓝。")


def android_monochrome() -> str:
    return _android_vector("#FFFFFF", "#FFFFFF", "主题图标（Android 13+ 单色层），系统自己上色。")


def patch_android_background() -> None:
    colors = ROOT / "Android/app/src/main/res/values/colors.xml"
    text = colors.read_text(encoding="utf-8")
    text = re.sub(
        r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]{6}(</color>)',
        rf"\g<1>{INDIGO}\g<2>",
        text,
    )
    colors.write_text(text, encoding="utf-8")


def brand_mark() -> str:
    body = icon_svg(INDIGO, PALE, INDIGO)
    # Drop xml wrapper width; BrandMark supplies class + aria.
    inner = body.replace(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">',
        '<svg class="brand-mark" viewBox="0 0 1024 1024" aria-hidden="true">',
    )
    return inner


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    (OUT / "app-icon.svg").write_text(LIGHT)
    (OUT / "app-icon-dark.svg").write_text(DARK)
    (OUT / "app-icon-tinted.svg").write_text(TINTED)
    (OUT / "favicon.svg").write_text(FAVICON)
    (OUT / "brand-mark.svg").write_text(brand_mark())

    light = raster_svg(LIGHT, OUT / "AppIcon.png", 1024)
    raster_svg(DARK, OUT / "AppIcon-dark.png", 1024)
    raster_svg(TINTED, OUT / "AppIcon-tinted.png", 1024)
    raster_svg(LIGHT, OUT / "favicon-32.png", 32)
    raster_svg(LIGHT, OUT / "apple-touch-icon.png", 180)
    raster_svg(LIGHT, OUT / "icon-192.png", 192)
    raster_svg(LIGHT, OUT / "icon-512.png", 512)

    # 分享卡左上角那颗。方图不带圆角——SwiftUI 用 continuous 圆角自己切，
    # 这里预先蒙一层 PIL 的普通圆角会和系统 squircle 差一圈。
    light.resize((512, 512), Image.Resampling.LANCZOS).convert("RGB").save(
        OUT / "BrandIcon.png"
    )

    rounded = squircle(light.resize((512, 512), Image.Resampling.LANCZOS))
    rounded.save(OUT / "icon-rounded.png")
    paper = Image.new("RGBA", (512, 512), (244, 245, 248, 255))
    paper.alpha_composite(rounded)
    paper.convert("RGB").save(OUT / "icon-preview.png")

    # Install
    appicon = ROOT / "App/Resources/Assets.xcassets/AppIcon.appiconset"
    public = ROOT / "site/public"
    docs = ROOT / "docs/assets"
    shutil.copy2(OUT / "AppIcon.png", appicon / "AppIcon.png")
    shutil.copy2(OUT / "AppIcon-dark.png", appicon / "AppIcon-dark.png")
    shutil.copy2(OUT / "AppIcon-tinted.png", appicon / "AppIcon-tinted.png")
    # Mac 槽位和 iOS 1024 同一张。asset catalog 里 idiom=mac 512@2x 指向它。
    # 分享卡不自己画一只猫冒充图标：用同一张位图，改了图标这里跟着变。
    shutil.copy2(
        OUT / "BrandIcon.png",
        ROOT / "Packages/MeterKit/Sources/MeterDesign/Resources/BrandIcon.png",
    )
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
    (ROOT / "site/src/components/BrandMark.astro").write_text(
        (OUT / "brand-mark.svg").read_text()
    )
    drawable = ROOT / "Android/app/src/main/res/drawable"
    (drawable / "ic_launcher_foreground.xml").write_text(android_foreground())
    (drawable / "ic_launcher_monochrome.xml").write_text(android_monochrome())
    patch_android_background()
    print("installed")


if __name__ == "__main__":
    main()
