#!/usr/bin/env python3
"""打赏页截图 → App Store Connect 的内购审核截图（640×920）。

商店页那一档收 1320×2868（6.9"），**内购审核截图那个上传框不收**——它是另一套
老规格，只认 640×920，传别的尺寸会红「The dimensions of one or more screenshots
are wrong」。所以这一步单独存在：从 `iphone69-tip-*` 裁一块、缩到 640×920、
去掉 alpha（内购截图和商店截图一样不许带透明通道）。

裁法：从顶上按 640:920 的比例切一刀。打赏页的内容（标题、三档、那句
「不解锁」、记录）都在上半屏，切完一样不少，比整屏缩下去清楚得多。

    python3 scripts/render-iap-review-screenshot.py

产物在 docs/appstore/iap-review/（不进仓库，见 .gitignore 末尾）。三个内购传同一张。
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/appstore/screenshots"
DEST = ROOT / "docs/appstore/iap-review"

TARGET = (640, 920)
SOURCES = ("iphone69-tip-en-dark.png", "iphone69-tip-en-light.png")


def render(path: Path) -> Path:
    image = Image.open(path)
    width, _ = image.size
    crop_height = round(width * TARGET[1] / TARGET[0])
    if crop_height > image.size[1]:
        raise SystemExit(f"{path.name} 比 640:920 还窄，裁不出来")
    cropped = image.crop((0, 0, width, crop_height))
    resized = cropped.resize(TARGET, Image.LANCZOS)
    # 内购截图不许带 alpha。压在白底上而不是直接丢通道：dark 那张四角是圆的。
    flattened = Image.new("RGB", TARGET, (0, 0, 0))
    flattened.paste(resized, (0, 0), resized if resized.mode == "RGBA" else None)
    DEST.mkdir(parents=True, exist_ok=True)
    out = DEST / path.name.replace("iphone69-", "")
    flattened.save(out)
    return out


def main() -> int:
    for name in SOURCES:
        path = SRC / name
        if not path.exists():
            print(f"缺 {path.relative_to(ROOT)}，先跑 capture-appstore-screenshots.sh 的 tip 那一档")
            return 1
        out = render(path)
        print(f"  wrote {out.relative_to(ROOT)} {TARGET[0]}×{TARGET[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
