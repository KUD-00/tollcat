#!/usr/bin/env python3
"""README 里那面服务图标墙。

落地页的图标墙是三行 marquee 滚动（site/src/marqueeSvg.ts）；README 不会动，
就把同一批格子重新排成一张静态网格图。格子不重画：先用
scripts/dump-marquee-svgs.cjs 把三行 SVG 求值出来，这里只是把每个
<g transform="translate(x 0)">…</g> 抠出来换个坐标。哪些家上墙、什么底色、
什么图形，全由落地页那份决定，这里没有第二份清单。

用法：render-readme-wall.py <marquee-svg-dir> <out.png> [--theme dark]
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 和 marqueeSvg.ts 一样的格子尺寸；变了这里也得跟着变，不然抠出来的格子会叠。
CELL = 50
GAP = 11
PAD = 36
PANEL_RADIUS = 28
# 每行 22 个：README 正文约 900 CSS px 宽，一格约 33 px，还认得出是哪家。
PER_ROW = 22
PANEL = {"dark": "#0d0f14", "light": "#f4f5f7"}


def tiles(svg: str) -> list[str]:
    """一行 marquee 里的所有格子，去掉原来的 translate。"""
    found = re.findall(r'<g transform="translate\([^)]*\)">(.*?)</g>', svg, re.S)
    if not found:
        raise SystemExit("marquee SVG 里没找到格子，格式变了？")
    return found


def wall_svg(cells: list[str], theme: str) -> str:
    rows = [cells[i : i + PER_ROW] for i in range(0, len(cells), PER_ROW)]
    width = PER_ROW * CELL + (PER_ROW - 1) * GAP + PAD * 2
    height = len(rows) * CELL + (len(rows) - 1) * GAP + PAD * 2
    body: list[str] = [
        f'<rect width="{width}" height="{height}" rx="{PANEL_RADIUS}" fill="{PANEL[theme]}"/>'
    ]
    for r, row in enumerate(rows):
        # 最后一行不满就居中，别左边一撮右边空着。
        row_width = len(row) * CELL + (len(row) - 1) * GAP
        x0 = PAD + (width - PAD * 2 - row_width) / 2
        y = PAD + r * (CELL + GAP)
        for c, cell in enumerate(row):
            x = x0 + c * (CELL + GAP)
            body.append(f'<g transform="translate({x:g} {y})">{cell}</g>')
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" fill="none">{"".join(body)}</svg>'
    )


def render(svg: str, out: Path) -> None:
    width = int(re.search(r'width="(\d+)"', svg).group(1))
    height = int(re.search(r'height="(\d+)"', svg).group(1))
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "wall.html"
        page.write_text(
            "<!doctype html><html><head><meta charset='utf-8'><style>"
            "html,body{margin:0;background:transparent}svg{display:block}"
            f"</style></head><body>{svg}</body></html>",
            encoding="utf-8",
        )
        subprocess.run(
            [
                CHROME,
                "--headless=new",
                "--disable-gpu",
                "--hide-scrollbars",
                "--default-background-color=00000000",
                "--force-device-scale-factor=2",
                f"--window-size={width},{height}",
                f"--screenshot={out}",
                page.as_uri(),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    if not out.exists():
        raise SystemExit(f"Chrome 没写出 {out}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("svg_dir", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--theme", choices=sorted(PANEL), default="dark")
    args = ap.parse_args()

    files = sorted(args.svg_dir.glob(f"marquee-{args.theme}-*.svg"))
    if not files:
        raise SystemExit(f"{args.svg_dir} 里没有 marquee-{args.theme}-*.svg，先跑 scripts/dump-marquee-svgs.cjs")
    # 三行是按 index % 3 分出去的，按原顺序拼回一列再重新切行。
    rows = [tiles(f.read_text(encoding="utf-8")) for f in files]
    cells: list[str] = []
    for i in range(max(len(r) for r in rows)):
        for r in rows:
            if i < len(r):
                cells.append(r[i])
    render(wall_svg(cells, args.theme), args.out)
    print(f"wrote {args.out} ({len(cells)} marks)", file=sys.stderr)


if __name__ == "__main__":
    main()
