#!/usr/bin/env python3
"""Apple 官方 Product Bezel：下载、缓存、量开孔、把截图嵌进去。

机壳来自 developer.apple.com/design/resources/ 的 Product Bezels，
只用于 TollCat 在 iPhone / iPad / Mac 上的界面 mock-up（Apple Design Resources 许可）。
原版 bezel（几百 MB 的 dmg）不进 git，缓存在 .cache/apple-bezels/。

落地页（composite-site-device-frames.py）、商店宣传图（render-appstore-devices.py）
和 README 横幅（render-readme-hero.mjs，走本文件末尾的命令行口子）共用这一份：
机壳清单和开孔只许有一处，各写一份的话，同一台设备在几处会歪得不一样。

开孔**量出来**，不写死：屏幕那块是透明的，从图边泛洪一遍把「外面」的透明像素
标掉，剩下的透明像素就是屏幕。量到的结果缓存在 holes.json——一张 3000×2300
的图纯 Python 泛洪要几秒。
"""
from __future__ import annotations

import json
import subprocess
import sys
from collections import deque
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow", "-q"])
    from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / ".cache" / "apple-bezels"
HOLES = CACHE / "holes.json"

DOWNLOAD = "https://devimages-cdn.apple.com/design/resources/download"
MBP_DMG = f"{DOWNLOAD}/Bezel-MacBook-Pro-M5.dmg"
IPAD_DMG = f"{DOWNLOAD}/Bezel-iPad-Pro-%28M5%29.dmg"
IPHONE_DMG = f"{DOWNLOAD}/Bezel-iPhone-17.dmg"

# 缓存名 → (dmg, 挂载后的 PNG 相对路径)。
#
# 配色跟落地页一条规矩：亮色用银，深色用深蓝 / 深空黑。
BEZELS = {
    "iphone-17-pro-silver": (
        IPHONE_DMG,
        "Bezel-iPhone-17/PNG/iPhone 17 Pro/iPhone 17 Pro - Silver - Portrait.png",
    ),
    "iphone-17-pro-deep-blue": (
        IPHONE_DMG,
        "Bezel-iPhone-17/PNG/iPhone 17 Pro/iPhone 17 Pro - Deep Blue - Portrait.png",
    ),
    # 6.9" 档（1320×2868）。开孔和截图 1:1，嵌进去一个像素都不用缩。
    "iphone-17-pro-max-silver": (
        IPHONE_DMG,
        "Bezel-iPhone-17/PNG/iPhone 17 Pro Max/iPhone 17 Pro Max - Silver - Portrait.png",
    ),
    "iphone-17-pro-max-deep-blue": (
        IPHONE_DMG,
        "Bezel-iPhone-17/PNG/iPhone 17 Pro Max/iPhone 17 Pro Max - Deep Blue - Portrait.png",
    ),
    # 11" 档（2420×1668 / 1668×2420）。ASC 的 iPad 档位叫「13-inch display」，
    # 那是**画布尺寸**的名字；画布里摆哪台机器是构图的事。
    "ipad-pro-11-silver-landscape": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 11" - Silver - Landscape.png',
    ),
    "ipad-pro-11-space-black-landscape": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 11" - Space Black - Landscape.png',
    ),
    "ipad-pro-11-silver-portrait": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 11" - Silver - Portrait.png',
    ),
    "ipad-pro-11-space-black-portrait": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 11" - Space Black - Portrait.png',
    ),
    "ipad-pro-13-silver-landscape": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Silver - Landscape.png',
    ),
    "ipad-pro-13-space-black-landscape": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Landscape.png',
    ),
    "ipad-pro-13-silver-portrait": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Silver - Portrait.png',
    ),
    "ipad-pro-13-space-black-portrait": (
        IPAD_DMG,
        'Bezel-iPad-Pro-(M5)/PNG/iPad Pro (M5) 13" - Space Black - Portrait.png',
    ),
    "macbook-pro-14-silver": (
        MBP_DMG,
        "Bezel-MacBook-Pro-M5/PNG/MacBook Pro M5 14-inch Silver.png",
    ),
    "macbook-pro-14-space-black": (
        MBP_DMG,
        "Bezel-MacBook-Pro-M5/PNG/MacBook Pro M5 14-inch Space Black.png",
    ),
}


def bezel(name: str) -> Path:
    """缓存里的那张 PNG。没有就下 dmg、挂载、抠出来。"""
    dest = CACHE / f"{name}.png"
    if dest.exists():
        return dest
    url, volume_path = BEZELS[name]
    CACHE.mkdir(parents=True, exist_ok=True)
    src = Path("/Volumes") / volume_path
    if not src.exists():
        dmg = CACHE / Path(url.split("/")[-1].replace("%28", "(").replace("%29", ")"))
        if not dmg.exists():
            print(f"==> download {dmg.name}")
            subprocess.check_call(["curl", "-fsSL", "-o", str(dmg), url])
        print(f"==> attach {dmg.name}")
        # dmg 带许可协议，不喂 Y 会静默地挂不上。
        proc = subprocess.run(
            ["hdiutil", "attach", "-nobrowse", str(dmg)],
            input="Y\n" * 8,
            text=True,
            capture_output=True,
        )
        if proc.returncode != 0 and not src.exists():
            print(proc.stdout)
            print(proc.stderr, file=sys.stderr)
            raise SystemExit(f"failed to attach {dmg}")
    if not src.exists():
        raise SystemExit(f"missing {src}")
    Image.open(src).save(dest)
    print(f"    cached {dest.relative_to(ROOT)}")
    return dest


def screen_hole(path: Path) -> tuple[int, int, int, int]:
    """屏幕开孔，inclusive 的 (x0, y0, x1, y1)。量出来并缓存。

    刘海 / 灵动岛是**机壳的一部分**（不透明），所以它落在孔里不影响这个包围盒。
    """
    return _measure(path)["hole"]


def screen_corner_radius(path: Path) -> int:
    """屏幕四角的圆角有多大（px）。量不出来就是 0（方屏，比如某些外接显示器）。

    这个数**必须**用上：开孔的包围盒是方的，屏幕四角是圆的，直接把方的截图
    贴进去，机身外面会露出四个小方角——浅色截图配浅色底面时看不出来，
    深色底面上就是四个白疙瘩，而且只有一部分图会犯，最容易漏检。
    """
    return _measure(path)["radius"]


def _measure(path: Path) -> dict:
    cached = _load_holes()
    key = path.name
    entry = cached.get(key)
    if isinstance(entry, dict) and "hole" in entry and "radius" in entry:
        return {"hole": tuple(entry["hole"]), "radius": entry["radius"]}
    hole = _find_hole(path)
    radius = _find_corner_radius(path, hole)
    cached[key] = {"hole": list(hole), "radius": radius}
    _save_holes(cached)
    return {"hole": hole, "radius": radius}


def _find_hole(path: Path) -> tuple[int, int, int, int]:
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A").load()
    width, height = image.size
    outside = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        if 0 <= x < width and 0 <= y < height:
            index = y * width + x
            if not outside[index] and alpha[x, y] < 8:
                outside[index] = 1
                queue.append((x, y))

    for x in range(width):
        push(x, 0)
        push(x, height - 1)
    for y in range(height):
        push(0, y)
        push(width - 1, y)
    while queue:
        x, y = queue.popleft()
        push(x + 1, y)
        push(x - 1, y)
        push(x, y + 1)
        push(x, y - 1)

    x0, y0, x1, y1 = width, height, -1, -1
    for y in range(height):
        row = y * width
        for x in range(width):
            if alpha[x, y] < 8 and not outside[row + x]:
                x0 = min(x0, x)
                x1 = max(x1, x)
                y0 = min(y0, y)
                y1 = max(y1, y)
    if x1 < x0 or y1 < y0:
        raise SystemExit(f"{path.name}: 量不到屏幕开孔——这张机壳的屏幕不是透明的？")
    return (x0, y0, x1, y1)


def _find_corner_radius(path: Path, hole: tuple[int, int, int, int]) -> int:
    """从左上角横着扫：机身外（透明）→ 机身（不透明）→ 屏幕（透明）三段。

    合格的半径要同时满足两头——切出来的画面边不能跑到机身外面（露方角），
    也不能缩进屏幕里面（露一条缝）。合格区间取中值。
    """
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A").load()
    x0, y0, x1, y1 = hole
    span = min(x1 - x0 + 1, y1 - y0 + 1) // 3
    outer: list[int] = []
    inner: list[int] = []
    for y in range(span):
        row_outer = None
        row_inner = None
        for x in range(span):
            opaque = alpha[x0 + x, y0 + y] > 128
            if opaque and row_outer is None:
                row_outer = x
            if row_outer is not None and not opaque:
                row_inner = x
                break
        if row_outer is None:
            # 这一行整行都是屏幕：圆角在这之上就走完了。
            break
        outer.append(row_outer)
        inner.append(row_inner if row_inner is not None else row_outer)
    limit = len(outer)
    if limit < 8:
        # 方屏，或者这张机壳不是三段结构。不切就是了。
        return 0

    def edge(radius: int, y: int) -> float:
        if y >= radius:
            return 0.0
        return radius - (radius * radius - (radius - y) ** 2) ** 0.5

    ok = [
        radius
        for radius in range(1, limit + 1)
        if all(outer[y] <= edge(radius, y) <= inner[y] for y in range(limit))
    ]
    return ok[len(ok) // 2] if ok else 0


def round_corners(picture: Image.Image, radius: int) -> Image.Image:
    """按屏幕圆角切一刀。四个角各画一张 4 倍超采样的小蒙版，省得为整张图开一张大的。"""
    if radius <= 0:
        return picture.convert("RGBA")
    width, height = picture.size
    radius = min(radius, width // 2, height // 2)
    scale = 4
    corner = Image.new("L", (radius * scale, radius * scale), 0)
    ImageDraw.Draw(corner).pieslice(
        (0, 0, radius * 2 * scale - 1, radius * 2 * scale - 1), 180, 270, fill=255
    )
    corner = corner.resize((radius, radius), Image.Resampling.LANCZOS)
    mask = Image.new("L", (width, height), 255)
    mask.paste(corner, (0, 0))
    mask.paste(corner.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (width - radius, 0))
    mask.paste(corner.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, height - radius))
    mask.paste(corner.transpose(Image.Transpose.ROTATE_180), (width - radius, height - radius))
    out = picture.convert("RGBA")
    out.putalpha(mask)
    return out


def _load_holes() -> dict[str, list[int]]:
    if HOLES.exists():
        return json.loads(HOLES.read_text(encoding="utf-8"))
    return {}


def _save_holes(data: dict[str, list[int]]) -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    HOLES.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def composite(
    bezel_name: str,
    shot: Path,
    out: Path,
    *,
    max_edge: int | None = None,
    trim: bool = True,
    exact: bool = False,
) -> Image.Image:
    """把截图嵌进机壳的开孔里，存成透明背景的 PNG。

    exact=True：要求截图和开孔像素级同尺寸（6.9" iPhone、13" iPad 都是这样），
    对不上就报错——缩放过的商店宣传图会糊，而且没人会盯着看出来。
    exact=False：按开孔 cover 裁切（落地页的 Mac 窗口截图尺寸随窗口变）。
    """
    bezel_path = bezel(bezel_name)
    chrome = Image.open(bezel_path).convert("RGBA")
    x0, y0, x1, y1 = screen_hole(bezel_path)
    radius = screen_corner_radius(bezel_path)
    target = (x1 - x0 + 1, y1 - y0 + 1)
    picture = Image.open(shot).convert("RGB")
    if exact:
        if picture.size != target:
            raise SystemExit(
                f"{shot.name} 是 {picture.size[0]}×{picture.size[1]}，"
                f"{bezel_name} 的开孔是 {target[0]}×{target[1]}——尺寸对不上"
            )
    else:
        picture = _cover(picture, target)
    canvas = Image.new("RGBA", chrome.size, (0, 0, 0, 0))
    # 圆角切在贴之前：机壳只盖得住机身那一圈，盖不住机身**外面**那四个方角。
    picture = round_corners(picture, radius)
    canvas.paste(picture, (x0, y0), picture)
    canvas = Image.alpha_composite(canvas, chrome)
    if trim:
        box = canvas.getchannel("A").getbbox()
        if box:
            canvas = canvas.crop(box)
    if max_edge and max(canvas.size) > max_edge:
        ratio = max_edge / max(canvas.size)
        canvas = canvas.resize(
            (int(canvas.size[0] * ratio), int(canvas.size[1] * ratio)),
            Image.Resampling.LANCZOS,
        )
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG", optimize=True)
    print(f"    {out.name} {canvas.size[0]}×{canvas.size[1]}")
    return canvas


def _cover(picture: Image.Image, target: tuple[int, int]) -> Image.Image:
    tw, th = target
    sw, sh = picture.size
    scale = max(tw / sw, th / sh)
    nw, nh = max(1, round(sw * scale)), max(1, round(sh * scale))
    picture = picture.resize((nw, nh), Image.Resampling.LANCZOS)
    left = max(0, (nw - tw) // 2)
    top = max(0, (nh - th) // 2)
    picture = picture.crop((left, top, left + tw, top + th))
    if picture.size != target:
        picture = picture.resize(target, Image.Resampling.LANCZOS)
    return picture


def overlay(name: str, out: Path, max_edge: int = 2000) -> None:
    """裁掉透明边、缩到 max_edge，给落地页当叠在活屏幕上的机壳。"""
    image = Image.open(bezel(name)).convert("RGBA")
    box = image.getchannel("A").getbbox()
    if box:
        image = image.crop(box)
    if max(image.size) > max_edge:
        ratio = max_edge / max(image.size)
        image = image.resize(
            (int(image.size[0] * ratio), int(image.size[1] * ratio)),
            Image.Resampling.LANCZOS,
        )
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "PNG", optimize=True)
    print(f"    {out.name} {image.size[0]}×{image.size[1]}")


def main(argv: list[str]) -> int:
    """给 Node 那边用的命令行口子。

    README 横幅是 Chrome headless 渲的（`render-readme-hero.mjs`），拿不到这里的
    Python 函数——但机壳和开孔只许有一处，所以走命令行调过来，而不是在 JS 里
    再画一个圆角黑框。

      python3 scripts/apple_bezels.py composite <bezel> <shot.png> <out.png> [--exact]
      python3 scripts/apple_bezels.py overlay <bezel> <out.png> [--max-edge N]
    """
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    one = sub.add_parser("composite", help="把截图嵌进机壳的开孔里")
    one.add_argument("bezel", choices=sorted(BEZELS))
    one.add_argument("shot", type=Path)
    one.add_argument("out", type=Path)
    one.add_argument("--exact", action="store_true", help="要求截图和开孔像素级同尺寸")
    one.add_argument("--max-edge", type=int, default=None)

    two = sub.add_parser("overlay", help="只导机壳本身，屏幕留空")
    two.add_argument("bezel", choices=sorted(BEZELS))
    two.add_argument("out", type=Path)
    two.add_argument("--max-edge", type=int, default=2000)

    args = parser.parse_args(argv[1:])
    if args.command == "composite":
        composite(args.bezel, args.shot, args.out, max_edge=args.max_edge, exact=args.exact)
    else:
        overlay(args.bezel, args.out, args.max_edge)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
