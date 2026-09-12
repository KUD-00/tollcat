#!/usr/bin/env python3
"""把落地页截图嵌进 Apple 官方 Product Bezel。

机壳、开孔、合成都在 `scripts/apple_bezels.py` 里——商店宣传图
（`render-appstore-devices.py`）用的是同一份，两处不许各写一遍。

iPhone 竖屏是叠在**活屏幕**上的透明机壳（锁屏动画还在孔里），所以只导出机壳本身。
iPad / Mac 是合成好的 mock-up PNG。

  python3 scripts/composite-site-device-frames.py
"""
from __future__ import annotations

from pathlib import Path

from apple_bezels import ROOT, composite, overlay

SHOTS = ROOT / "site" / "src" / "assets" / "screenshots"
DEST = SHOTS

LOCALES = ("zh", "en", "ja")
APPEARANCES = ("light", "dark")
MAX_EDGE = 2000


def main() -> None:
    # 落地页 hero 那台：机壳本身，屏幕留空给活内容。
    overlay("iphone-17-pro-silver", DEST / "iphone-17-pro-silver.png", MAX_EDGE)
    overlay("iphone-17-pro-deep-blue", DEST / "iphone-17-pro-deep-blue.png", MAX_EDGE)

    for locale in LOCALES:
        for appearance in APPEARANCES:
            light = appearance == "light"
            mbp = "macbook-pro-14-silver" if light else "macbook-pro-14-space-black"
            color = "silver" if light else "space-black"

            mac_src = SHOTS / f"mac-window-{locale}-{appearance}.png"
            if mac_src.exists():
                # Mac 窗口截图尺寸跟着窗口走，按开孔 cover 裁。
                composite(
                    mbp,
                    mac_src,
                    DEST / f"macbook-window-{locale}-{appearance}.png",
                    max_edge=MAX_EDGE,
                )
            # 弹窗两页：横屏进横机壳，竖屏进竖机壳。机壳配色仍按亮/深走。
            for screen, orientation in (("dashboard", "landscape"), ("portrait", "portrait")):
                src = SHOTS / f"ipad-{screen}-{locale}-{appearance}.png"
                if src.exists():
                    composite(
                        f"ipad-pro-11-{color}-{orientation}",
                        src,
                        DEST / f"ipad-bezel-{screen}-{locale}-{appearance}.png",
                        max_edge=MAX_EDGE,
                        exact=True,
                    )


if __name__ == "__main__":
    main()
