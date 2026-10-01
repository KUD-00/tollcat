#!/usr/bin/env python3
"""Android 机壳：取 Android Studio 自带的 device art，导出落地页叠层。

和 `apple_bezels.py` 一个用法：机壳是叠在**活屏幕**上的透明 PNG，画面在下面一层。
原图在 Android Studio 安装目录里（模拟器的 device frame 就是它），不进 git；
导出的叠层进 `site/src/assets/screenshots/`。

机型是 Pixel 10 Pro：Android Studio 只给了一种浅色机身（Porcelain）。深色那台照着
iPhone「亮银 / 深蓝」的规矩要换色，这里把金属边压暗成 Obsidian——只动亮度，
屏幕黑边和摄像头本来就是黑的，不受影响。

开孔不量，直接读 device art 自带的 layout（`display` 尺寸 + `part2` 偏移）。
"""
from __future__ import annotations

import os
import re
from pathlib import Path

from PIL import Image

STUDIO = Path(
    os.environ.get(
        "ANDROID_DEVICE_ART",
        "/Applications/Android Studio.app/Contents/plugins/android/resources/device-art-resources",
    )
)

DEVICE = "pixel_10_pro"

# 叠层文件名 → 调色。名字跟着 Pixel 的官方配色走。
TONES = {
    "pixel-10-pro-porcelain": "light",
    "pixel-10-pro-obsidian": "dark",
}


def _layout(device: str) -> dict[str, int]:
    text = (STUDIO / device / "layout").read_text()

    def grab(block: str, key: str) -> int:
        match = re.search(block + r"\s*\{[^}]*?\b" + key + r"\s+(\d+)", text, re.S)
        if not match:
            raise SystemExit(f"{device}/layout: no {key} in {block}")
        return int(match.group(1))

    return {
        "display_w": grab("display", "width"),
        "display_h": grab("display", "height"),
        "corner": grab("display", "corner_radius"),
        "frame_w": grab(r"layouts\s*\{\s*portrait", "width"),
        "frame_h": grab(r"layouts\s*\{\s*portrait", "height"),
        "x": grab("part2", "x"),
        "y": grab("part2", "y"),
    }


def hole(device: str = DEVICE) -> dict[str, float]:
    """屏幕开孔占机壳的百分比，直接抄进 CSS 的 --phone-hole-*。"""
    lay = _layout(device)
    return {
        "x": lay["x"] / lay["frame_w"] * 100,
        "y": lay["y"] / lay["frame_h"] * 100,
        "w": lay["display_w"] / lay["frame_w"] * 100,
        "h": lay["display_h"] / lay["frame_h"] * 100,
        "rx": lay["corner"] / lay["display_w"] * 100,
        "ry": lay["corner"] / lay["display_h"] * 100,
        "ratio_w": lay["frame_w"],
        "ratio_h": lay["frame_h"],
    }


def _obsidian(image: Image.Image) -> Image.Image:
    # 亮度过一道 gamma 再压到一半出头：高光留着，金属的立体感不丢。
    r, g, b, a = image.split()
    curve = [round(255 * (v / 255) ** 2.1 * 0.5) for v in range(256)]
    return Image.merge("RGBA", (r.point(curve), g.point(curve), b.point(curve), a))


def overlay(name: str, out: Path, max_edge: int = 2000, device: str = DEVICE) -> None:
    lay = _layout(device)
    back = Image.open(STUDIO / device / "back.webp").convert("RGBA")
    # back.webp 比 layout 多出几像素的投影余量；按 layout 的画框裁，开孔百分比才对得上。
    back = back.crop((0, 0, lay["frame_w"], lay["frame_h"]))
    if TONES.get(name) == "dark":
        back = _obsidian(back)
    scale = min(1.0, max_edge / max(back.size))
    if scale < 1:
        back = back.resize((round(back.width * scale), round(back.height * scale)), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    back.save(out, optimize=True)
    print(f"    wrote {out.name}")


if __name__ == "__main__":
    print(hole())
