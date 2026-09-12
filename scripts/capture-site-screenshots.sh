#!/usr/bin/env bash
# 落地页 iPhone 截图：3 屏 × 3 语 × 2 外观。
# 步骤说明见 site/README.md「落地页截图」。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/site/src/assets/screenshots"
BUNDLE="com.zhechengqi.tollcat"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"
DERIVED="${DERIVED:-/tmp/dd-site-screenshots}"
WAIT_SECS="${WAIT_SECS:-6}"
SKIP_BUILD="${SKIP_BUILD:-0}"

LOCALES=(zh en ja)
APPEARANCES=(light dark)
# 向导必须空库（已接入的家会从添加列表消失），所以放最后并重装。
SCREENS=(dashboard services wizard)

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

screen_args() {
    case "$1" in
        dashboard)
            echo "-seed-demo -skip-onboarding -hide-cat"
            ;;
        services)
            echo "-seed-demo -skip-onboarding -start-on-services"
            ;;
        wizard)
            echo "-skip-demo-seed -skip-onboarding -start-on-services -open-setup=cloudflare"
            ;;
    esac
}

needs_fresh_store() {
    [[ "$1" == "wizard" ]]
}

udid_for_device() {
    xcrun simctl list devices available \
        | awk -v name="$DEVICE_NAME" '
            $0 ~ name {
                if (match($0, /\(([0-9A-F-]{36})\)/)) {
                    print substr($0, RSTART+1, RLENGTH-2)
                    exit
                }
            }'
}

build_app() {
    echo "==> build Debug ($DEVICE_NAME)"
    xcodebuild \
        -project "$ROOT/TollCat.xcodeproj" \
        -scheme TollCat \
        -configuration Debug \
        -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
        -derivedDataPath "$DERIVED" \
        build
}

find_app() {
    local app
    app="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name 'TollCat.app' -print -quit)"
    if [[ -z "$app" || ! -d "$app" ]]; then
        echo "TollCat.app not found under $DERIVED" >&2
        exit 1
    fi
    echo "$app"
}

boot_simulator() {
    local udid="$1"
    xcrun simctl boot "$udid" 2>/dev/null || true
    open -a Simulator --args -CurrentDeviceUDID "$udid"
    xcrun simctl bootstatus "$udid" -b
}

pin_status_bar() {
    local udid="$1"
    # 启动 App 会清掉覆盖，必须在画面出来之后、截图之前再钉一次。
    xcrun simctl status_bar "$udid" override \
        --time "9:41" \
        --batteryState charging \
        --batteryLevel 100 \
        --cellularMode active \
        --cellularBars 4 \
        --wifiMode active \
        --wifiBars 3 \
        --dataNetwork wifi \
        --operatorName ""
}

reinstall() {
    local udid="$1"
    local app="$2"
    xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
    xcrun simctl uninstall "$udid" "$BUNDLE" 2>/dev/null || true
    xcrun simctl install "$udid" "$app"
}

launch_and_capture() {
    local udid="$1"
    local locale="$2"
    local appearance="$3"
    local screen="$4"
    local out="$5"
    local languages locale_id extra
    languages="$(locale_languages "$locale")"
    locale_id="$(locale_locale "$locale")"
    extra="$(screen_args "$screen")"

    xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
    xcrun simctl ui "$udid" appearance "$appearance"

    # shellcheck disable=SC2086
    xcrun simctl launch "$udid" "$BUNDLE" \
        -AppleLanguages "$languages" \
        -AppleLocale "$locale_id" \
        -clock-preset=design \
        -appearance="$appearance" \
        -stub-catalog \
        -stub-inbox \
        -stub-usage-analytics \
        -stub-feedback \
        $extra

    sleep "$WAIT_SECS"
    if [[ "$screen" == "wizard" ]]; then
        # 连接参考抽屉要等 sheet 撑开。
        sleep 2
    fi
    pin_status_bar "$udid"
    sleep 0.4
    xcrun simctl io "$udid" screenshot "$out"
    echo "    wrote $out"
}

main() {
    mkdir -p "$DEST"
    cd "$ROOT"
    if [[ "$SKIP_BUILD" != "1" ]]; then
        build_app
    fi
    local app udid
    app="$(find_app)"
    udid="$(udid_for_device)"
    if [[ -z "$udid" ]]; then
        echo "No available simulator named $DEVICE_NAME" >&2
        exit 1
    fi
    echo "==> simulator $DEVICE_NAME ($udid)"
    boot_simulator "$udid"
    pin_status_bar "$udid"

    local locale appearance screen dest
    for locale in "${LOCALES[@]}"; do
        for appearance in "${APPEARANCES[@]}"; do
            echo "==> $locale $appearance"
            reinstall "$udid" "$app"
            for screen in "${SCREENS[@]}"; do
                dest="$DEST/iphone-${screen}-${locale}-${appearance}.png"
                if needs_fresh_store "$screen"; then
                    reinstall "$udid" "$app"
                fi
                launch_and_capture "$udid" "$locale" "$appearance" "$screen" "$dest"
            done
        done
    done

    echo "==> done"
    ls -1 "$DEST"/iphone-*-{zh,en,ja}-{light,dark}.png
}

main "$@"
