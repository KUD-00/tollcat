#!/usr/bin/env bash
# 落地页 Android 截图：3 屏 × 3 语 × 2 外观，和 iPhone 那套一一对应。
# 机壳（Pixel 10 Pro）由 scripts/composite-site-device-frames.py 导出，PhoneFrame 叠在画面上。
#
# 先起模拟器（Pixel_10a，1080×2424）并装好 debug 包：scripts/android-run.sh。
#   bash scripts/capture-site-android-screenshots.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/site/src/assets/screenshots"
BUNDLE="com.zhechengqi.tollcat"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="${ADB:-$ANDROID_HOME/platform-tools/adb}"
# 向导那一屏等抽屉撑开的时长。
WAIT_SECS="${WAIT_SECS:-5}"
# 只重截其中几张：ONLY="zh-light-services ja-dark-dashboard"。
ONLY="${ONLY:-}"

LOCALES=(zh en ja)
APPEARANCES=(light dark)
SCREENS=(dashboard services wizard)

locale_android() {
    case "$1" in
        zh) echo "zh-CN" ;;
        en) echo "en-US" ;;
        ja) echo "ja-JP" ;;
    esac
}

screen_extras() {
    case "$1" in
        dashboard) echo "--ez seed_demo true --ez skip_onboarding true --ez hide_cat true --ez hide_demo_banner true" ;;
        services) echo "--ez seed_demo true --ez skip_onboarding true --ez start_on_services true --ez hide_demo_banner true" ;;
        # 向导要空库：不灌种子，直接打开 Cloudflare 的接入向导。
        wizard) echo "--ez skip_onboarding true --es open_setup cloudflare" ;;
    esac
}

demo() {
    "$ADB" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null
}

# 状态栏钉成 9:41、Wi-Fi 满格、满电，和 iPhone 那套一个口径。
# 系统自己的通知（模拟器没设锁屏，安全中心会挂一枚盾牌）先推迟一天，demo 模式藏不掉它。
pin_status_bar() {
    "$ADB" shell settings put global sysui_demo_allowed 1
    local key
    for key in $("$ADB" shell cmd notification list 2>/dev/null | tr -d '\r'); do
        "$ADB" shell "cmd notification snooze --for 86400000 '$key'" >/dev/null 2>&1 || true
    done
    demo enter
    demo clock -e hhmm 0941
    demo battery -e level 100 -e plugged false
    demo network -e mobile hide
    demo network -e wifi show -e level 4 -e fully true
    demo status -e volume hide -e bluetooth hide -e location hide -e alarm hide -e sync hide \
        -e mute hide -e speakerphone hide -e managed_profile hide -e zen hide
    demo notifications -e visible false
}

release_status_bar() {
    demo exit || true
    "$ADB" shell cmd uimode night auto >/dev/null || true
}

wait_dashboard() {
    local i
    for i in $(seq 1 60); do
        if "$ADB" logcat -d -s TollCat:I 2>/dev/null | grep -F -q 'dashboard empty=false'; then
            return 0
        fi
        sleep 0.5
    done
    return 1
}

launch() {
    # shellcheck disable=SC2086
    "$ADB" shell am start -W -n "$BUNDLE/.MainActivity" \
        --ez skip_launch_reveal true \
        --es appearance "$1" \
        --es clock_preset design \
        $2 >/dev/null
}

capture() {
    local locale="$1" appearance="$2" screen="$3" out="$4" night extras wait
    if [[ "$appearance" == "dark" ]]; then night=yes; else night=no; fi
    extras="$(screen_extras "$screen")"
    wait="$WAIT_SECS"
    "$ADB" shell am force-stop "$BUNDLE"
    "$ADB" shell pm clear "$BUNDLE" >/dev/null
    "$ADB" shell cmd locale set-app-locales "$BUNDLE" --locales "$(locale_android "$locale")" >/dev/null
    "$ADB" shell cmd uimode night "$night" >/dev/null
    "$ADB" logcat -c
    launch "$appearance" "$extras"
    if [[ "$screen" != "wizard" ]]; then
        # 种子排在 JniGate 队列里异步写，第一次启动截到的常是空态或「暂无读数」，
        # 写到一半被杀还会留下半个库。等它写完、仪表算出非空，再冷启动一次
        # （库不空，种子跳过），第二次开出来是满的。
        wait_dashboard || echo "    warn: seed never finished" >&2
        sleep 1.5
        "$ADB" shell am force-stop "$BUNDLE"
        "$ADB" logcat -c
        launch "$appearance" "$extras"
        wait_dashboard || echo "    warn: dashboard never reported non-empty" >&2
        # 骨架屏换成内容、列表和图表的进场动画走完。
        wait=3.5
    fi
    sleep "$wait"
    pin_status_bar
    sleep 0.6
    "$ADB" exec-out screencap -p > "$out"
    echo "    wrote ${out#"$ROOT"/}"
}

main() {
    if ! "$ADB" devices | grep -q $'device$'; then
        echo "no Android emulator attached (start Pixel_10a first)" >&2
        exit 1
    fi
    trap release_status_bar EXIT
    mkdir -p "$DEST"
    local locale appearance screen
    for locale in "${LOCALES[@]}"; do
        for appearance in "${APPEARANCES[@]}"; do
            echo "==> $locale $appearance"
            for screen in "${SCREENS[@]}"; do
                if [[ -n "$ONLY" && " $ONLY " != *" $locale-$appearance-$screen "* ]]; then
                    continue
                fi
                capture "$locale" "$appearance" "$screen" "$DEST/android-${screen}-${locale}-${appearance}.png"
            done
        done
    done
}

main "$@"
