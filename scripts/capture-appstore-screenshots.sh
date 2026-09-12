#!/usr/bin/env bash
# App Store 提交用素材：iPhone 6.9"（1320×2868）、iPad 11" 横屏（2420×1668）与竖屏（1668×2420），
# 外加主屏小组件那几格（渲成 PNG，不是截图——主屏上的 widget 截不到）。
# 3 语 × 2 外观。产物进 docs/appstore/screenshots/——那个目录**不进仓库**
# （见 .gitignore 末尾）：原图只在本机，重来一趟就是重跑这个脚本。
# App Store Connect 传 6.9" 档后 6.5" 不再必填。iPad 那一档 ASC 叫「13-inch display」
# （2752×2064），那是**画布**尺寸——画布里摆的是 11" 机身，构图见 render-appstore-marketing.mjs。
# 必须签名构建（不要 CODE_SIGNING_ALLOWED=NO），否则演示种子因 Keychain -34018 静默失败。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/docs/appstore/screenshots"
BUNDLE="com.zhechengqi.tollcat"
IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro Max}"
IPAD_NAME="${IPAD_NAME:-iPad Pro 11-inch (M5)}"
DERIVED="${DERIVED:-/tmp/dd-appstore-screenshots}"
WAIT_SECS="${WAIT_SECS:-6}"
SKIP_BUILD="${SKIP_BUILD:-0}"

# 每一维都能单独收窄，改一张就只重出那一张——一轮全量二十分钟起，
# 为了一处版式微调把三语明暗全跑一遍是纯浪费。
#
#   LOCALES=zh APPEARANCES=light IPAD_SCREENS=services IPHONE_SCREENS="" \
#   SKIP_WIDGETS=1 SKIP_BUILD=1 bash scripts/capture-appstore-screenshots.sh
#
# 用 `${VAR-默认}` 不是 `${VAR:-默认}`——后者把空串也当没设，于是
# `IPAD_SCREENS=""` 这种「这一档整个跳过」的写法会静默地跑成全量。
read -r -a LOCALES <<< "${LOCALES-zh en ja}"
read -r -a APPEARANCES <<< "${APPEARANCES-light dark}"
read -r -a IPHONE_SCREENS <<< "${IPHONE_SCREENS-dashboard services detail wizard}"
read -r -a IPAD_SCREENS <<< "${IPAD_SCREENS-dashboard services detail}"
read -r -a IPAD_PORTRAIT_SCREENS <<< "${IPAD_PORTRAIT_SCREENS-dashboard wizard}"
# 小组件素材两套（手机的一格和 iPad 的不一样大）。只补一套就写 WIDGET_DEVICES=pad。
read -r -a WIDGET_DEVICES <<< "${WIDGET_DEVICES-phone pad}"

# 「我的服务」和「预算线」两块的内容来自版式里的钉选和预算，演示种子两样都没有。
# 小组件那一页要它们有东西，所以那一趟单独给。预算取值让本月合计落在 72%。
WIDGET_EXTRA="${WIDGET_EXTRA:--pin-accounts=6 -monthly-budget=60}"

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

# 中国大陆不许在元数据里出现 OpenAI / ChatGPT（App Review Guideline 5，深度合成需
# 持牌），而 App Store Connect 的截图是按语言上传的——所以 zh 那一趟换一套演示数据，
# en / ja 照旧。覆盖在 `Fixtures/cn/`，接法见 `FixtureOverlay`。
# 金额和曲线两套是对齐的，所以换了数据版式不会变形，两套图能共用一次构建。
locale_fixtures() {
    case "$1" in
        zh) echo "-demo-fixtures=cn" ;;
        *) echo "" ;;
    esac
}

# 第二个参数是朝向。横屏 iPad 走分栏壳（`UsesPadChrome`：regular 且宽 > 高），
# 竖屏和 iPhone 走列表壳——同一屏在两种壳下要给的启动参数不一样。
screen_args() {
    local screen="$1"
    local orientation="${2:-portrait-native}"
    local split=0
    [[ "$orientation" == landscape* ]] && split=1
    case "$screen" in
        dashboard)
            # 商店图不带猫（和设置里「关闭猫猫」同一开关）。
            echo "-seed-demo -skip-onboarding -hide-cat"
            ;;
        services)
            if [[ "$split" == 1 ]]; then
                # 分栏的右半边不选一家就是空态，商店图上摆一张空态没有意义。
                # 挑 AWS：金额最大、走势最好看，也不和 detail 那页的 Cloudflare 撞。
                echo "-seed-demo -skip-onboarding -start-on-services -open-provider-detail=aws"
            else
                # 竖屏点开是全屏推进，先给列表就好。
                echo "-seed-demo -skip-onboarding -start-on-services"
            fi
            ;;
        detail)
            echo "-seed-demo -skip-onboarding -open-provider-detail=cloudflare"
            ;;
        wizard)
            echo "-skip-demo-seed -skip-onboarding -start-on-services -open-setup=cloudflare"
            ;;
        tip)
            # App Store Connect 的 IAP 审核截图：三档并排。
            # `-stub-tips` 是必需的——simctl 装的 App 没有 scheme 上那份 StoreKit 配置，
            # 真去问 App Store 只会拿到空数组，截出来是「暂时无法连接」的空态。
            # 不铺演示数据：这一页只显示档位和留言记录，账单一条都用不上。
            echo "-skip-demo-seed -skip-onboarding -open-tip -stub-tips"
            ;;
    esac
}

# 向导必须空库（已接入的家会从添加列表消失），所以放最后并重装。
needs_fresh_store() {
    [[ "$1" == "wizard" ]]
}

udid_for_device() {
    xcrun simctl list devices available \
        | awk -v name="$1" '
            index($0, name) {
                if (match($0, /\(([0-9A-F-]{36})\)/)) {
                    print substr($0, RSTART+1, RLENGTH-2)
                    exit
                }
            }'
}

build_app() {
    echo "==> build Debug ($IPHONE_NAME)"
    xcodebuild \
        -project "$ROOT/TollCat.xcodeproj" \
        -scheme TollCat \
        -configuration Debug \
        -destination "platform=iOS Simulator,name=$IPHONE_NAME" \
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

set_device_orientation() {
    local udid="$1"
    local orientation="$2"
    local menu
    # 真机走 devicectl；模拟器它看不见，点 Simulator 的 Device → Orientation。
    if xcrun devicectl device orientation set --device "$udid" "$orientation" 2>/dev/null; then
        return
    fi
    case "$orientation" in
        landscapeLeft) menu="Landscape Left" ;;
        landscapeRight) menu="Landscape Right" ;;
        portrait) menu="Portrait" ;;
        portraitUpsideDown) menu="Portrait Upside Down" ;;
        *)
            echo "unknown orientation: $orientation" >&2
            exit 1
            ;;
    esac
    open -a Simulator --args -CurrentDeviceUDID "$udid"
    osascript -e 'tell application "Simulator" to activate' \
        -e 'delay 0.3' \
        -e "tell application \"System Events\" to click menu item \"$menu\" of menu 1 of menu item \"Orientation\" of menu 1 of menu bar item \"Device\" of menu bar 1 of process \"Simulator\""
}

# 一档一个尺寸。截完按这个核对——转屏没生效时出来的是竖图，尺寸一眼看得出来。
expected_size() {
    case "$1" in
        iphone69) echo "1320 2868" ;;
        ipad11) echo "2420 1668" ;;
        ipad11p) echo "1668 2420" ;;
        *)
            echo "unknown prefix: $1" >&2
            exit 1
            ;;
    esac
}

png_size() {
    sips -g pixelWidth -g pixelHeight "$1" \
        | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w, h}'
}

# 设备到底转没转，看 **Simulator 窗口的长宽比**，不看截图尺寸。
#
# `simctl io screenshot` 有时按竖屏帧缓冲出图：那张竖图里装的是躺着的横屏画面。
# 光看截图尺寸的话，「设备压根没转」和「帧缓冲是竖的」长得一模一样——
# 以前这里不分青红皂白 `sips -r 270` 转一下，于是一张画面躺着的图被当好图交上去。
# 窗口长宽比没有这个歧义。
simulator_window_is_landscape() {
    local size w h
    size="$(osascript -e 'tell application "System Events" to tell process "Simulator" to get size of window 1' 2>/dev/null)" || return 1
    w="${size%%,*}"
    h="${size##*,}"
    w="${w// /}"
    h="${h// /}"
    [[ -n "$w" && -n "$h" && "$w" -gt "$h" ]]
}

ensure_orientation() {
    local udid="$1"
    local orientation="$2"
    local attempt want is
    [[ "$orientation" == "portrait-native" ]] && return 0
    if [[ "$orientation" == landscape* ]]; then want=1; else want=0; fi
    for attempt in 1 2 3 4; do
        if simulator_window_is_landscape; then is=1; else is=0; fi
        if [[ "$is" == "$want" ]]; then
            return 0
        fi
        set_device_orientation "$udid" "$orientation"
        sleep 2.5
    done
    echo "转屏没生效（$orientation）。Simulator 窗口被挡住 / 没给辅助功能权限时，那条 osascript 会静默失败。" >&2
    exit 1
}

screenshot_settled() {
    local udid="$1"
    local out="$2"
    local orientation="$3"
    local want_w="$4"
    local want_h="$5"
    local size w h

    ensure_orientation "$udid" "$orientation"
    pin_status_bar "$udid"
    sleep 0.4
    xcrun simctl io "$udid" screenshot "$out"
    size="$(png_size "$out")"
    w="${size%% *}"
    h="${size##* }"
    if [[ "$w" != "$want_w" || "$h" != "$want_h" ]]; then
        # 朝向刚核对过，所以这只可能是帧缓冲按竖屏出的图。
        # landscapeLeft 的画面在竖图里顺时针歪了 90°，转 270° 才是正的横屏。
        if [[ "$want_w" -gt "$want_h" && "$w" -lt "$h" ]]; then
            sips -r 270 "$out" >/dev/null
            size="$(png_size "$out")"
            w="${size%% *}"
            h="${size##* }"
        fi
    fi
    if [[ "$w" != "$want_w" || "$h" != "$want_h" ]]; then
        echo "expected ${want_w}×${want_h}, got ${w}×${h}: $out" >&2
        exit 1
    fi
}

# iPad 的状态栏上除了时间还有**日期**，而那一行是系统画的，跟 App 的
# `-AppleLanguages` 无关——不改设备语言的话，中文和英文那两套截图上会挂着一行
# 日文日期。`simctl status_bar override` 管得了时间，管不了日期，所以只能改设备语言。
# 改完要重启 SpringBoard 才会重画那一行。
set_device_language() {
    local udid="$1"
    local locale="$2"
    local language region
    case "$locale" in
        zh) language="zh-Hans"; region="zh_CN" ;;
        en) language="en"; region="en_US" ;;
        ja) language="ja"; region="ja_JP" ;;
    esac
    xcrun simctl spawn "$udid" defaults write "Apple Global Domain" AppleLanguages -array "$language" >/dev/null 2>&1 || true
    xcrun simctl spawn "$udid" defaults write "Apple Global Domain" AppleLocale -string "$region" >/dev/null 2>&1 || true
    xcrun simctl spawn "$udid" launchctl stop com.apple.SpringBoard >/dev/null 2>&1 || true
    sleep 8
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

launch_app() {
    local udid="$1"
    local locale="$2"
    local appearance="$3"
    local extra="$4"
    local languages locale_id fixtures
    languages="$(locale_languages "$locale")"
    locale_id="$(locale_locale "$locale")"
    fixtures="$(locale_fixtures "$locale")"

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
        $fixtures \
        $extra
}

launch_and_capture() {
    local udid="$1"
    local locale="$2"
    local appearance="$3"
    local screen="$4"
    local out="$5"
    local orientation="$6"
    local prefix="$7"
    local size want_w want_h

    # 先把朝向摆好再启动：App 一起来就是目标朝向，不用等它转一次。
    ensure_orientation "$udid" "$orientation"
    launch_app "$udid" "$locale" "$appearance" "$(screen_args "$screen" "$orientation")"

    sleep "$WAIT_SECS"
    if [[ "$screen" == "wizard" ]]; then
        # 连接参考抽屉要等 sheet 撑开。
        sleep 2
    fi
    size="$(expected_size "$prefix")"
    want_w="${size%% *}"
    want_h="${size##* }"
    screenshot_settled "$udid" "$out" "$orientation" "$want_w" "$want_h"
    echo "    wrote $out"
}

capture_device() {
    local device_name="$1"
    local prefix="$2"
    local orientation="$3"
    shift 3
    local screens=("$@")
    local udid app locale appearance screen dest

    if [[ ${#screens[@]} -eq 0 ]]; then
        echo "==> $prefix: 没有要截的屏，跳过"
        return
    fi
    udid="$(udid_for_device "$device_name")"
    if [[ -z "$udid" ]]; then
        echo "No available simulator named $device_name" >&2
        exit 1
    fi
    echo "==> simulator $device_name ($udid) $orientation"
    app="$(find_app)"
    boot_simulator "$udid"
    ensure_orientation "$udid" "$orientation"
    pin_status_bar "$udid"

    for locale in "${LOCALES[@]}"; do
        set_device_language "$udid" "$locale"
        # 重启 SpringBoard 会把朝向打回竖屏。
        ensure_orientation "$udid" "$orientation"
        for appearance in "${APPEARANCES[@]}"; do
            echo "==> $prefix $locale $appearance"
            reinstall "$udid" "$app"
            for screen in "${screens[@]}"; do
                dest="$DEST/${prefix}-${screen}-${locale}-${appearance}.png"
                if needs_fresh_store "$screen"; then
                    reinstall "$udid" "$app"
                fi
                launch_and_capture "$udid" "$locale" "$appearance" "$screen" "$dest" "$orientation" "$prefix"
            done
        done
    done

    xcrun simctl shutdown "$udid" 2>/dev/null || true
}

# 主屏上那一格截不到：simctl 不认识 widget，往模拟器主屏上加一格只能靠人手点。
# 所以 App 自己把每一格渲成 PNG 落到沙盒（`-dump-widget-tiles`，见
# DeveloperWidgetTileDump），渲的是 widget 扩展用的同一份视图、同一份仪表内容——
# 于是图上的数字和同一批截图里的仪表盘对得上。
capture_widget_tiles() {
    local device_name="$1"
    local udid app locale appearance data src file stem
    udid="$(udid_for_device "$device_name")"
    if [[ -z "$udid" ]]; then
        echo "No available simulator named $device_name" >&2
        exit 1
    fi
    echo "==> widget tiles ($device_name)"
    app="$(find_app)"
    boot_simulator "$udid"

    for locale in "${LOCALES[@]}"; do
        for appearance in "${APPEARANCES[@]}"; do
            echo "==> widget $locale $appearance"
            reinstall "$udid" "$app"
            launch_app "$udid" "$locale" "$appearance" \
                "-seed-demo -skip-onboarding -dump-widget-tiles $WIDGET_EXTRA"
            sleep "$((WAIT_SECS + 6))"
            data="$(xcrun simctl get_app_container "$udid" "$BUNDLE" data)"
            src="$data/Documents/widget-tiles"
            if [[ ! -d "$src" ]]; then
                echo "no widget tiles under $src" >&2
                exit 1
            fi
            # 文件名里带 idiom（phone / pad）：两种机器的一格不一样大，是两套素材。
            for file in "$src"/*.png; do
                stem="$(basename "$file" .png)"
                cp "$file" "$DEST/widget-${stem}-${locale}-${appearance}.png"
            done
            echo "    wrote $(ls -1 "$src" | wc -l | tr -d ' ') tiles"
        done
    done

    xcrun simctl shutdown "$udid" 2>/dev/null || true
}

main() {
    mkdir -p "$DEST"
    cd "$ROOT"
    if [[ "$SKIP_BUILD" != "1" ]]; then
        build_app
    fi
    if [[ "${SKIP_IPHONE:-0}" != "1" ]]; then
        capture_device "$IPHONE_NAME" "iphone69" "portrait-native" ${IPHONE_SCREENS[@]+"${IPHONE_SCREENS[@]}"}
    fi
    if [[ "${SKIP_WIDGETS:-0}" != "1" ]]; then
        local device
        for device in ${WIDGET_DEVICES[@]+"${WIDGET_DEVICES[@]}"}; do
            case "$device" in
                phone) capture_widget_tiles "$IPHONE_NAME" ;;
                pad) capture_widget_tiles "$IPAD_NAME" ;;
                *)
                    echo "unknown WIDGET_DEVICES entry: $device（只认 phone / pad）" >&2
                    exit 1
                    ;;
            esac
        done
    fi
    if [[ "${SKIP_IPAD:-0}" != "1" ]]; then
        # `${arr[@]+"${arr[@]}"}`：set -u 下空数组直接展开会被当成未绑定变量。
        capture_device "$IPAD_NAME" "ipad11" "landscapeLeft" ${IPAD_SCREENS[@]+"${IPAD_SCREENS[@]}"}
        capture_device "$IPAD_NAME" "ipad11p" "portrait" ${IPAD_PORTRAIT_SCREENS[@]+"${IPAD_PORTRAIT_SCREENS[@]}"}
    fi

    echo "==> sizes"
    local f
    for f in "$DEST"/*.png; do
        sips -g pixelWidth -g pixelHeight "$f" | awk -v f="$(basename "$f")" '
            /pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {printf "    %s %s×%s\n", f, w, h}'
    done
    echo "==> done"
}

main "$@"
