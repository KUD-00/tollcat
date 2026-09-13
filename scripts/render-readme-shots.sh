#!/usr/bin/env bash
# README 横幅底下那一行截图：三台 iPhone（仪表盘、服务列表、接入向导）加一台 MacBook，
# 三语各一套，全部暗色。横幅是亮的，这一行是暗的，两者一亮一暗对比着看。
#
# 截图不另截：iPhone 用商店那批原图（docs/appstore/screenshots/iphone69-*-<语言>-dark.png，
# 由 scripts/capture-appstore-screenshots.sh 出），机壳走 scripts/apple_bezels.py，
# 和横幅、落地页、商店宣传图同一份机壳清单。MacBook 直接拿落地页已经嵌好机壳的那张
# （site/src/assets/screenshots/macbook-window-<语言>-dark.png）。
#
# 输出：.github/readme/shot-{dashboard,services,wizard,mac}-<语言>.png
# 用法：bash scripts/render-readme-shots.sh          # 三语十二张
#       ONLY=en bash scripts/render-readme-shots.sh  # 只出一种语言
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHOTS="$ROOT/docs/appstore/screenshots"
SITE_SHOTS="$ROOT/site/src/assets/screenshots"
OUT="$ROOT/.github/readme"

# 暗色截图配深色机壳；横幅那张是亮色截图配银色机壳，同一条规矩反过来。
BEZEL="iphone-17-pro-max-deep-blue"
# README 里三张并排，每张显示宽度不到 300 CSS px，长边 1400 已经够 2x 屏幕。
MAX_EDGE=1400

LOCALES=(zh en ja)
if [[ -n "${ONLY:-}" ]]; then LOCALES=("$ONLY"); fi

for locale in "${LOCALES[@]}"; do
  for screen in dashboard services wizard; do
    shot="$SHOTS/iphone69-$screen-$locale-dark.png"
    if [[ ! -f "$shot" ]]; then
      echo "缺 ${shot#$ROOT/}——先跑 scripts/capture-appstore-screenshots.sh" >&2
      exit 1
    fi
    python3 "$ROOT/scripts/apple_bezels.py" composite "$BEZEL" "$shot" \
      "$OUT/shot-$screen-$locale.png" --exact --max-edge "$MAX_EDGE"
  done
  mac="$SITE_SHOTS/macbook-window-$locale-dark.png"
  if [[ ! -f "$mac" ]]; then
    echo "缺 ${mac#$ROOT/}——先跑 scripts/capture-site-platform-screenshots.sh" >&2
    exit 1
  fi
  cp "$mac" "$OUT/shot-mac-$locale.png"
  echo "wrote shot-{dashboard,services,wizard,mac}-$locale.png"
done
