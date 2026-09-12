#!/usr/bin/env python3
"""商店宣传图的机身素材：把 App Store 截图嵌进 Apple 官方 Product Bezel。

落地页早就用真机机壳了，商店图以前是 CSS 画的一个圆角黑框——同一个 App 在两处
长着两台不同的机器。这一步把两边并到一处：机壳、开孔、合成全在
`scripts/apple_bezels.py` 里。

开孔和截图**像素级 1:1**（6.9" iPhone 1320×2868、13" iPad 2752×2064），
所以嵌进去一个像素都不用缩。产物是透明背景的 PNG，投影交给宣传图那一层的 CSS。

输入 docs/appstore/screenshots/，输出 .tmp-task-marketing/devices/（不进 git）。

  python3 scripts/render-appstore-devices.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

from apple_bezels import ROOT, bezel, composite, screen_corner_radius, screen_hole

SHOTS = ROOT / "docs" / "appstore" / "screenshots"
DEST = ROOT / ".tmp-task-marketing" / "devices"

LOCALES = ("zh", "en", "ja")
THEMES = ("light", "dark")

# 截图前缀 → (亮色机壳, 深色机壳)。前缀就是截图文件名的第一段。
CHASSIS = {
    "iphone69": ("iphone-17-pro-max-silver", "iphone-17-pro-max-deep-blue"),
    "ipad11": ("ipad-pro-11-silver-landscape", "ipad-pro-11-space-black-landscape"),
    "ipad11p": ("ipad-pro-11-silver-portrait", "ipad-pro-11-space-black-portrait"),
}


def export_chrome() -> None:
    """机壳本身 + 屏幕开孔的位置，给「主屏 mock-up」那一帧用。

    小组件那一页屏幕上摆的不是截图，是壁纸 + 状态栏 + 一格格小组件——
    主屏上的 widget 截不到（`simctl` 不认识它），所以那一屏是在 HTML 里搭的，
    机壳当叠层盖上去。落地页 hero 那台 iPhone 用的是同一套做法。
    """
    manifest = {}
    for name in (
        "iphone-17-pro-max-silver",
        "iphone-17-pro-max-deep-blue",
        "ipad-pro-11-silver-portrait",
        "ipad-pro-11-space-black-portrait",
    ):
        source = bezel(name)
        x0, y0, x1, y1 = screen_hole(source)
        image = Image.open(source).convert("RGBA")
        box = image.getchannel("A").getbbox()
        if box:
            image = image.crop(box)
            x0 -= box[0]
            y0 -= box[1]
            x1 -= box[0]
            y1 -= box[1]
        DEST.mkdir(parents=True, exist_ok=True)
        out = DEST / f"chrome-{name}.png"
        image.save(out, "PNG", optimize=True)
        hole = (x0, y0, x1 - x0 + 1, y1 - y0 + 1)
        manifest[name] = {
            "size": [image.size[0], image.size[1]],
            "hole": list(hole),
            "cornerRadius": screen_corner_radius(source),
        }
        print(
            f"    {out.name} {image.size[0]}×{image.size[1]} "
            f"hole {manifest[name]['hole']} r{manifest[name]['cornerRadius']}"
        )
    (DEST / "chrome.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def main(argv: list[str]) -> int:
    # 参数是要嵌的 <prefix>-<screen> 组合，缺省照 screenshots/ 里现有的全嵌。
    wanted = set(argv[1:])
    missing = 0
    made = 0
    export_chrome()
    for shot in sorted(SHOTS.glob("*.png")):
        parts = shot.stem.split("-")
        if len(parts) != 4:
            continue
        prefix, screen, locale, theme = parts
        if prefix not in CHASSIS or locale not in LOCALES or theme not in THEMES:
            continue
        if wanted and f"{prefix}-{screen}" not in wanted:
            continue
        light, dark = CHASSIS[prefix]
        composite(
            light if theme == "light" else dark,
            shot,
            DEST / shot.name,
            exact=True,
        )
        made += 1
    if made == 0:
        print("没有可嵌的截图——先跑 scripts/capture-appstore-screenshots.sh", file=sys.stderr)
        missing = 1
    return missing


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
