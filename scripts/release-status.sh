#!/usr/bin/env bash
# 该不该发版、发哪些端——一分钟给答案。节奏由事件触发，不由日历触发，这个脚本就是那个「事件」的读数。
#
#     bash scripts/release-status.sh            # 人看
#     bash scripts/release-status.sh --json     # 给 release-status.yml 用
#
# 约定：
#   vX.Y.Z          一班车。release.yml 从它构建；哪些端上了这班车由下面的记账 tag 说
#   ios-vX.Y.Z      iOS 上了这班（App Store）
#   mac-vX.Y.Z      Mac 直发上了这班（Sparkle 清单在 Publish 时切过去）
#   mac-appstore-vX.Y.Z  Mac 商店版上了这班（要在 dispatch 上单独勾，不随 tag 自动跟）
#   android-vX.Y.Z  Android 上了这班
#   windows-vX.Y.Z  Windows 上了这班
# 五条线各自独立判断，iOS 和 Mac 不是同一班车；Mac 的两个通道也不是。
# Mac 商店版和直发版**源码路径完全一样**（同一份 project-mac.yml 的两个 target），
# 所以「有没有可发内容」两边永远同一个答案；真正有用的读数是它比直发版落后几班——
# 商店要过审，落后是常态，落后太多才是问题。
# 判据：
#   某端「有可发内容」= 自它上次记账 tag 以来，main 上有提交碰过它关心的路径
#   iOS / Mac：有可发内容且距上次超过 MAX_DAYS 天 → 该发；没到天数 → 值得写更新日志就发
#   Android / Windows：落后（v* 比它多） ≥ WAVE_LAG 班，或共用核心改过 → 该跟
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MAX_DAYS="${MAX_DAYS:-30}"
WAVE_LAG="${WAVE_LAG:-2}"
JSON=0
[[ "${1:-}" == "--json" ]] && JSON=1

# 五端共用的核心：改了它，每个端都有可发内容。
CORE_PATHS=(
    Packages/MeterKit/Sources/MeterCore
    Packages/MeterKit/Sources/MeterProviders
    Packages/MeterKit/Sources/MeterFormat
    Packages/MeterKit/Sources/MeterPersistence/Catalog
    shared
)
# 苹果两端共用的壳代码（MeterFeatures / MeterDesign / MeterPersistence …）都在 Packages 下；
# 靠文件名和目录把「只属于另一端」的排掉。启发式，会漏也会多报，方向是宁可多提醒。
IOS_PATHS=(Packages App Widget project.yml TollCat.storekit shared
    ':(exclude)Mac' ':(exclude,glob)Packages/**/*Mac*' ':(exclude,glob)Packages/**/MenuBar*')
MAC_PATHS=(Packages Mac project.yml shared
    ':(exclude)App' ':(exclude)Widget' ':(exclude,glob)Packages/**/*Pad*' ':(exclude,glob)Packages/**/*Phone*' ':(exclude,glob)Packages/**/Onboarding*Widget*')

latest_tag() {
    # 按版本号排序取最大，不按时间：热修复的 tag 可能比后来的班车更晚打。
    git tag --list "$1*" | sed "s/^$1//" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1
}

commits_since() {
    local ref="$1"; shift
    if [[ -z "$ref" ]]; then
        git rev-list --count HEAD -- "$@"
    else
        git rev-list --count "$ref..HEAD" -- "$@"
    fi
}

days_since() {
    local ref="$1"
    [[ -z "$ref" ]] && { echo 9999; return; }
    echo $(( ( $(date +%s) - $(git log -1 --format=%ct "$ref") ) / 86400 ))
}

trains_after() {
    # 自某个记账 tag 之后 main 上又打了几个 v*（= 几班车）
    local ref="$1"
    if [[ -z "$ref" ]]; then
        git tag --list 'v*' | wc -l | tr -d ' '
        return
    fi
    git tag --list 'v*' --contains "$ref" | grep -vx "v${ref#*-v}" | wc -l | tr -d ' '
}

ref_of() { [[ -n "$2" ]] && echo "$1$2" || echo ""; }

version="$(python3 -c 'import json;print(json.load(open("shared/version.json"))["version"])')"
train="$(latest_tag 'v')"
ios="$(latest_tag 'ios-v')";         ios_ref="$(ref_of ios-v "$ios")"
mac="$(latest_tag 'mac-v')";         mac_ref="$(ref_of mac-v "$mac")"
# 注意 `git tag --list 'mac-v*'` 不会匹配 mac-appstore-v*，两者互不干扰。
mas="$(latest_tag 'mac-appstore-v')"; mas_ref="$(ref_of mac-appstore-v "$mas")"
android="$(latest_tag 'android-v')"; android_ref="$(ref_of android-v "$android")"
windows="$(latest_tag 'windows-v')"; windows_ref="$(ref_of windows-v "$windows")"

# iOS / Mac
apple_status() {
    local ref="$1"; shift
    local own days due=0
    own="$(commits_since "$ref" "$@")"
    days="$(days_since "$ref")"
    if (( own > 0 )) && (( days >= MAX_DAYS )); then due=1; fi
    echo "$own $days $due"
}
read -r ios_own ios_days ios_due <<<"$(apple_status "$ios_ref" "${IOS_PATHS[@]}")"
read -r mac_own mac_days mac_due <<<"$(apple_status "$mac_ref" "${MAC_PATHS[@]}")"
read -r mas_own mas_days mas_due <<<"$(apple_status "$mas_ref" "${MAC_PATHS[@]}")"

# Android / Windows
wave_status() {
    local ref="$1"
    local lag core due=0
    lag="$(trains_after "$ref")"
    core="$(commits_since "$ref" "${CORE_PATHS[@]}")"
    if (( lag >= WAVE_LAG )) || (( core > 0 )); then due=1; fi
    echo "$lag $core $due"
}
read -r android_lag android_core android_due <<<"$(wave_status "$android_ref")"
read -r windows_lag windows_core windows_due <<<"$(wave_status "$windows_ref")"

# 跟进点头：未点头 ≠ 班车 due。失败就让脚本停（set -e），不要静默少一行。
FOLLOW_UP="$(python3 scripts/check-follow-up.py due --json)"
android_unacked="$(python3 -c 'import json,sys; d=json.load(sys.stdin)["android"]["unacked"]; print(", ".join(d))' <<<"$FOLLOW_UP")"
windows_unacked="$(python3 -c 'import json,sys; d=json.load(sys.stdin)["windows"]["unacked"]; print(", ".join(d))' <<<"$FOLLOW_UP")"

if (( JSON )); then
    cat <<JSON
{
  "version": "$version",
  "lastTrain": "${train:-null}",
  "ios":     {"last": "${ios:-null}",     "relevantCommits": $ios_own, "daysSince": $ios_days, "due": $ios_due},
  "mac":     {"last": "${mac:-null}",     "relevantCommits": $mac_own, "daysSince": $mac_days, "due": $mac_due},
  "macAppStore": {"last": "${mas:-null}", "relevantCommits": $mas_own, "daysSince": $mas_days, "due": $mas_due},
  "android": {"last": "${android:-null}", "trainsBehind": $android_lag, "coreCommitsSince": $android_core, "due": $android_due},
  "windows": {"last": "${windows:-null}", "trainsBehind": $windows_lag, "coreCommitsSince": $windows_core, "due": $windows_due},
  "followUp": $FOLLOW_UP
}
JSON
    exit 0
fi

flag() { (( $1 )) && echo "← 该发了" || echo ""; }
printf '版本号（shared/version.json）%s    最近一班车 v%s\n' "$version" "${train:-—}"
printf 'iOS        上次 %-8s  之后 %3d 个相关提交，%4d 天  %s\n' "${ios:-—}" "$ios_own" "$ios_days" "$(flag "$ios_due")"
printf 'Mac 直发   上次 %-8s  之后 %3d 个相关提交，%4d 天  %s\n' "${mac:-—}" "$mac_own" "$mac_days" "$(flag "$mac_due")"
printf 'Mac 商店   上次 %-8s  之后 %3d 个相关提交，%4d 天  %s\n' "${mas:-—}" "$mas_own" "$mas_days" "$(flag "$mas_due")"
printf 'Android    上次 %-8s  落后 %d 班，核心改了 %d 个提交  %s\n' "${android:-—}" "$android_lag" "$android_core" "$(flag "$android_due")"
printf 'Windows    上次 %-8s  落后 %d 班，核心改了 %d 个提交  %s\n' "${windows:-—}" "$windows_lag" "$windows_core" "$(flag "$windows_due")"
echo
for pair in "iOS:$ios_own:$ios_due" "Mac:$mac_own:$mac_due"; do
    IFS=: read -r name own due <<<"$pair"
    if (( own > 0 )) && (( ! due )); then
        echo "$name 有 $own 个相关提交但没到 $MAX_DAYS 天上限：值得写进更新日志就发，不值得就等。"
    fi
done
if (( android_due || windows_due )); then
    echo "下次打 tag 时把该跟的端一起带上（release.yml 的 android / windows 输入）。"
fi
echo
printf '跟进未点头  Android  %s\n' "${android_unacked:-—}"
printf '            Windows  %s\n' "${windows_unacked:-—}"
echo "（未点头 ≠ 该发。点头见 docs/FOLLOW-UP.md；该发仍只看上面的班车启发式。）"
