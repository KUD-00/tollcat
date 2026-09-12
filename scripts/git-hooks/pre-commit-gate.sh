#!/usr/bin/env bash
# 提交前的便宜闸。只跑静态、秒级的检查。
# 漏译、模块越界、未申报出站都是「编译绿，切语言 / 读依赖 / 扫域名才爆」。
#
# 不在这里跑 xcodebuild / 整包测试：太慢，属于 CI。
# 失败就修闸，不要 --no-verify。
#
# 结构抄 RelayOS 的 pre-commit-gate：每道闸失败打 Why:，规则不是黑盒。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

run_gate() {
  local label="$1"
  local why="$2"
  shift 2

  printf '\n▶ %s  (%s)\n' "$label" "$*"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  (dry-run) skipped execution\n'
    return 0
  fi

  if ! "$@"; then
    printf '\n✖ %s failed.\n' "$label" >&2
    printf '  Why: %s\n' "$why" >&2
    return 1
  fi
}

run_gate \
  "i18n coverage" \
  "改了 L(\"…\") / MeterDesignText.resource 却没补同一模块 catalog 的 en/ja。编译仍然绿，把设备切到英文或日文才看得见中文源串。修法：在对应 Resources/Localizable.xcstrings 补译文。权限用途说明补 App/Resources/InfoPlist.xcstrings。Windows 独有句补 strings-windows-only.json。判据与 LocalizationCoverageTests 相同。" \
  python3 scripts/check-i18n-coverage.py

run_gate \
  "app store invariants" \
  "权限 API 没有用途说明、多申请了没用到的权限、隐私清单漏了 Required Reason API、默认 App 图标带透明、App Group 对不上。审核员点一下就会拒或崩。修法：按 check-app-store-invariants.py 打出的位置改。" \
  python3 scripts/check-app-store-invariants.py

run_gate \
  "source invariants" \
  "叶子模块认了账单、URLSession.shared、重定向没再过白名单、Widget 链了 Providers、App 链了 StoreKitTest、MeterCore 出现 Date()、Keychain 档位变松、迁移码短于 10 位、目录带了 URL、运行时 stub、JNI schema 漂移。编译照样过。" \
  python3 scripts/check-source-invariants.py

run_gate \
  "copy terms" \
  "对外文案里出现了 BRAND.md 词表废弃的词：日文漏进中文词或旧术语（資格情報/読数/受信箱/送信キー…），中文黑话外泄（取数/落盘/利用指南），或英文散文用了直引号。修法：按 check-copy-terms.py 打出的位置改词，词表本身要变先改 BRAND.md。" \
  python3 scripts/check-copy-terms.py

run_gate \
  "copy freshness" \
  "站点 i18n / catalog / android-only 里有单元的中文改了，同单元的 en 或 ja 一字没动——三语会从此漂移。修法：同一次改动里把该单元的 en/ja 一起更新；译文核对过确实不用变的，用 check-copy-freshness.py --allow <单元id> 放行并在提交说明里写明。" \
  python3 scripts/check-copy-freshness.py

run_gate \
  "outbound hosts" \
  "源码里出现了 OutboundHosts.swift 没登记的 https://。设置→关于和这份清单必须是同一份，漏登就是漏披露。" \
  bash scripts/check-outbound-hosts.sh

run_gate \
  "follow-up map" \
  "scripts/follow-up.json 坏了：watch 路径 404、stamp 指向不存在的 id、缺跟随端。过期戳不在这道闸——那是 due 的读数，见 docs/FOLLOW-UP.md。" \
  python3 scripts/check-follow-up.py check

printf '\n✓ pre-commit gates passed.\n'
