#!/usr/bin/env bash
# 落地页「更多平台」截图：iPad 11" 横屏 / 竖屏、Mac 主窗口 + 菜单栏面板、Android 仪表。
# iPad 默认同 docs/appstore/screenshots 那批（同一套种子）；要重截就 IPAD_RECAPTURE=1。
# Mac / Android 写入 site/src/assets/screenshots/{mac,android}-*.png。
# 末尾把 iPad / Mac 嵌进 Apple 官方 Product Bezel（SKIP_COMPOSITE=1 可跳过）。
#
#   bash scripts/capture-site-platform-screenshots.sh
#   SKIP_MAC=1 SKIP_ANDROID=1 bash scripts/capture-site-platform-screenshots.sh   # 只同步 iPad
#   SKIP_BUILD=1 bash scripts/capture-site-platform-screenshots.sh               # 复用上次 Mac 构建
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/site/src/assets/screenshots"
APPSTORE_SHOTS="$ROOT/docs/appstore/screenshots"
MAC_DERIVED="${MAC_DERIVED:-/tmp/dd-site-mac-screenshots}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="${ADB:-$ANDROID_HOME/platform-tools/adb}"
BUNDLE="com.zhechengqi.tollcat"
LOCALES=(zh en ja)
APPEARANCES=(light dark)

mkdir -p "$DEST"
cd "$ROOT"

locale_languages() {
    case "$1" in
        zh) echo "(zh-Hans)" ;;
        en) echo "(en)" ;;
        ja) echo "(ja)" ;;
    esac
}

locale_locale() {
    case "$1" in
        zh) echo "zh_CN" ;;
        en) echo "en_US" ;;
        ja) echo "ja_JP" ;;
    esac
}

locale_android() {
    case "$1" in
        zh) echo "zh-Hans" ;;
        en) echo "en" ;;
        ja) echo "ja" ;;
    esac
}

# 落地页 iPad 弹窗两页：横屏仪表盘（ipad11）+ 竖屏仪表盘（ipad11p）。
copy_ipad() {
    echo "==> iPad from App Store captures"
    local loc app src dest
    for loc in "${LOCALES[@]}"; do
        for app in "${APPEARANCES[@]}"; do
            src="$APPSTORE_SHOTS/ipad11-dashboard-${loc}-${app}.png"
            dest="$DEST/ipad-dashboard-${loc}-${app}.png"
            if [[ ! -f "$src" ]]; then
                echo "missing $src" >&2
                exit 1
            fi
            cp "$src" "$dest"

            src="$APPSTORE_SHOTS/ipad11p-dashboard-${loc}-${app}.png"
            dest="$DEST/ipad-portrait-${loc}-${app}.png"
            if [[ ! -f "$src" ]]; then
                echo "missing $src" >&2
                exit 1
            fi
            cp "$src" "$dest"
        done
    done
}

recapture_ipad() {
    echo "==> recapture iPad (App Store script)"
    SKIP_IPHONE=1 IPAD_SCREENS="dashboard" IPAD_PORTRAIT_SCREENS="dashboard" \
        bash "$ROOT/scripts/capture-appstore-screenshots.sh"
    copy_ipad
}

# ── Mac ──────────────────────────────────────────────────────────

mac_app_path() {
    local app
    app="$(find "$MAC_DERIVED/Build/Products/Debug" -maxdepth 1 -name 'TollCat.app' -print -quit)"
    if [[ -z "$app" || ! -d "$app" ]]; then
        echo "TollCat.app not found under $MAC_DERIVED" >&2
        exit 1
    fi
    echo "$app"
}

build_mac() {
    echo "==> build TollCatMac Debug"
    xcodebuild \
        -project "$ROOT/TollCatMac.xcodeproj" \
        -scheme TollCatMac \
        -configuration Debug \
        -derivedDataPath "$MAC_DERIVED" \
        build
}

mac_window_id() {
    local kind="$1"
    local pid="${2:-}"
    /usr/bin/swift "$ROOT/scripts/mac-windows.swift" "$kind" $pid 2>/dev/null || true
}

wait_mac_window() {
    local kind="$1"
    local pid="${2:-}"
    local tries="${3:-40}"
    local id=""
    local i
    for i in $(seq 1 "$tries"); do
        id="$(mac_window_id "$kind" "$pid")"
        if [[ -n "$id" ]]; then
            echo "$id"
            return 0
        fi
        sleep 0.4
    done
    return 1
}

screenshot_mac_pids() {
    ps -axo pid=,args= | awk -v needle="$MAC_DERIVED/Build/Products/Debug/TollCat.app/Contents/MacOS/TollCat" '
        index($0, needle) && $0 !~ /awk/ { print $1 }
    '
}

screenshot_mac_pid() {
    screenshot_mac_pids | tail -n 1
}

kill_screenshot_mac() {
    local p
    for p in $(screenshot_mac_pids); do
        kill "$p" 2>/dev/null || true
    done
}

set_mac_appearance() {
    local appearance="$1"
    case "$appearance" in
        dark) osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' ;;
        *) osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' ;;
    esac
}

# SwiftData 在 App Group 容器里。整份 Containers 没有 FDA 时 mv 会被拒，
# 只把 store 文件挪开，截完还原。
MAC_DARK_WAS=""
MAC_STORE_DIR=""
MAC_STORE_BACKUP=""

mac_store_dir() {
    ls -d "$HOME/Library/Group Containers/"*.com.zhechengqi.tollcat/Library/Application\ Support 2>/dev/null | head -n 1
}

backup_mac_state() {
    MAC_DARK_WAS="$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' 2>/dev/null || true)"
    # 没跑过 TollCat 的机器上 glob 落空、ls 退 1，pipefail 会把整个脚本无声杀掉。
    MAC_STORE_DIR="$(mac_store_dir || true)"
    if [[ -n "$MAC_STORE_DIR" && -f "$MAC_STORE_DIR/TollCat.store" ]]; then
        MAC_STORE_BACKUP="$(mktemp -d /tmp/tollcat-mac-store.XXXXXX)"
        mv "$MAC_STORE_DIR"/TollCat.store* "$MAC_STORE_BACKUP/"
        echo "==> parked SwiftData store at $MAC_STORE_BACKUP"
    fi
}

restore_mac_state() {
    kill_screenshot_mac
    sleep 0.4
    if [[ -n "$MAC_STORE_BACKUP" && -n "$MAC_STORE_DIR" ]]; then
        rm -f "$MAC_STORE_DIR"/TollCat.store*
        mv "$MAC_STORE_BACKUP"/TollCat.store* "$MAC_STORE_DIR/" 2>/dev/null || true
        rm -rf "$MAC_STORE_BACKUP"
        echo "==> restored SwiftData store"
        MAC_STORE_BACKUP=""
    fi
    if [[ "$MAC_DARK_WAS" == "true" ]]; then
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true
    elif [[ "$MAC_DARK_WAS" == "false" ]]; then
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null || true
    fi
}

launch_mac() {
    local app="$1"
    local locale="$2"
    local appearance="$3"
    local extra="${4:-}"
    local languages locale_id
    languages="$(locale_languages "$locale")"
    locale_id="$(locale_locale "$locale")"
    # 只杀截图用的那份，不要动 Xcode / 本机正在跑的 TollCat。
    kill_screenshot_mac
    sleep 0.6
    # 每次空库，-seed-demo 才能灌进设计稿数字。
    if [[ -n "$MAC_STORE_DIR" ]]; then
        rm -f "$MAC_STORE_DIR"/TollCat.store*
    fi
    set_mac_appearance "$appearance" 2>/dev/null || true
    # shellcheck disable=SC2086
    open -n "$app" --args \
        -seed-demo \
        -skip-onboarding \
        -clock-preset=design \
        -stub-catalog \
        -stub-inbox \
        -stub-usage-analytics \
        -stub-feedback \
        -appearance="$appearance" \
        -menu-bar-style=cat \
        -AppleLanguages "$languages" \
        -AppleLocale "$locale_id" \
        $extra
}

capture_mac() {
    local app locale appearance dest id
    app="$(mac_app_path)"
    echo "==> Mac $app"

    backup_mac_state
    trap restore_mac_state EXIT

    for locale in "${LOCALES[@]}"; do
        for appearance in "${APPEARANCES[@]}"; do
            echo "==> mac $locale $appearance"

            launch_mac "$app" "$locale" "$appearance" "-open-menu-bar-panel"
            sleep 4
            local pid=""
            pid="$(screenshot_mac_pid)"
            if [[ -z "$pid" ]]; then
                echo "screenshot TollCat pid not found" >&2
                exit 1
            fi
            id="$(wait_mac_window main "$pid" 40)" || {
                echo "main window not found (pid $pid)" >&2
                /usr/bin/swift "$ROOT/scripts/mac-windows.swift" list "$pid" || true
                exit 1
            }
            dest="$DEST/mac-window-${locale}-${appearance}.png"
            screencapture -x -o -l "$id" "$dest"
            echo "    wrote $dest"

            id="$(wait_mac_window panel "$pid" 20)" || {
                echo "menu bar panel window not found (pid $pid)" >&2
                /usr/bin/swift "$ROOT/scripts/mac-windows.swift" list "$pid" || true
                exit 1
            }
            dest="$DEST/mac-menubar-${locale}-${appearance}.png"
            screencapture -x -o -l "$id" "$dest"
            echo "    wrote $dest"

            kill_screenshot_mac
            sleep 0.6
        done
    done

    restore_mac_state
    trap - EXIT
}

# ── Android ──────────────────────────────────────────────────────

android_ready() {
    "$ADB" devices 2>/dev/null | grep -q $'device$'
}

wait_android_boot() {
    local i
    for i in $(seq 1 60); do
        if "$ADB" shell getprop sys.boot_completed 2>/dev/null | grep -q 1; then
            return 0
        fi
        sleep 2
    done
    return 1
}

launch_android() {
    local locale="$1"
    local appearance="$2"
    local night
    "$ADB" shell pm clear "$BUNDLE" >/dev/null
    "$ADB" shell cmd locale set-app-locales "$BUNDLE" --locales "$(locale_android "$locale")" >/dev/null || true
    if [[ "$appearance" == "dark" ]]; then night=yes; else night=no; fi
    "$ADB" shell cmd uimode night "$night" >/dev/null || true
    "$ADB" logcat -c >/dev/null || true
    "$ADB" shell am start -W -n "$BUNDLE/.MainActivity" \
        --ez seed_demo true \
        --ez skip_onboarding true \
        --ez hide_cat true \
        --es appearance "$appearance" \
        --es clock_preset design >/dev/null
}

wait_android_dashboard() {
    local i log
    for i in $(seq 1 40); do
        log="$("$ADB" logcat -d -s TollCat:* 2>/dev/null || true)"
        if echo "$log" | grep -F -q 'dashboard empty=false'; then
            return 0
        fi
        if echo "$log" | grep -F -q 'jniSchema='; then
            # 解码器脱节时仪表是空的，截了也是空态。
            if echo "$log" | grep -F -q 'empty=true'; then
                sleep 0.5
            fi
        fi
        sleep 1
    done
    return 1
}

capture_android() {
    if ! android_ready; then
        echo "==> no Android emulator; skip (start Pixel_10a and re-run with SKIP_MAC=1 SKIP_IPAD=1)" >&2
        return 0
    fi
    echo "==> Android"
    wait_android_boot || {
        echo "emulator did not boot" >&2
        return 1
    }
    local locale appearance dest
    for locale in "${LOCALES[@]}"; do
        for appearance in "${APPEARANCES[@]}"; do
            echo "==> android $locale $appearance"
            launch_android "$locale" "$appearance"
            if ! wait_android_dashboard; then
                echo "    skip $locale $appearance (dashboard stayed empty; rebuild JNI with scripts/android-run.sh)" >&2
                continue
            fi
            dest="$DEST/android-dashboard-${locale}-${appearance}.png"
            "$ADB" exec-out screencap -p > "$dest"
            echo "    wrote $dest"
        done
    done
    "$ADB" shell cmd uimode night auto >/dev/null || true
}

# ── main ─────────────────────────────────────────────────────────

if [[ "${SKIP_IPAD:-0}" != "1" ]]; then
    if [[ "${IPAD_RECAPTURE:-0}" == "1" ]]; then
        recapture_ipad
    else
        copy_ipad
    fi
fi

if [[ "${SKIP_MAC:-0}" != "1" ]]; then
    if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
        build_mac
    fi
    capture_mac
fi

if [[ "${SKIP_ANDROID:-0}" != "1" ]]; then
    capture_android
fi

if [[ "${SKIP_COMPOSITE:-0}" != "1" ]]; then
    echo "==> Apple Product Bezel mock-ups"
    python3 "$ROOT/scripts/composite-site-device-frames.py"
fi

echo "==> done"
ls -1 "$DEST"/{ipad,ipad-bezel,mac,macbook,android}-*.png 2>/dev/null || true
