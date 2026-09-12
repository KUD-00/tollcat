#!/usr/bin/env bash
# 把仓库里的 MeterCore + MeterProviders 编到 arm64 Android，装进模拟器。
# 验收 JNI 对账，以及产品壳：仪表 / 服务 / 设置。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_HOME/ndk/27.3.13750724}"
export PATH="$HOME/.swiftly/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

if [[ -f "$HOME/.swiftly/env.sh" ]]; then
    # shellcheck disable=SC1090
    . "$HOME/.swiftly/env.sh"
fi

if ! command -v swift >/dev/null; then
    echo "swift not on PATH; install swiftly + Swift 6.3.3" >&2
    exit 1
fi
if [[ ! -x "$JAVA_HOME/bin/java" ]]; then
    echo "JAVA_HOME is not a JDK: $JAVA_HOME" >&2
    exit 1
fi
if [[ ! -d "$ANDROID_NDK_HOME" ]]; then
    echo "ANDROID_NDK_HOME missing: $ANDROID_NDK_HOME" >&2
    exit 1
fi

# macOS 上 swift sdk install 放在 ~/Library/org.swift.swiftpm；Linux（CI）在 ~/.swiftpm，由调用方传进来。
SDK_BUNDLE="${SDK_BUNDLE:-$HOME/Library/org.swift.swiftpm/swift-sdks/swift-6.3.3-RELEASE_android.artifactbundle/swift-android}"
if [[ ! -d "$SDK_BUNDLE/ndk-sysroot" ]]; then
    ANDROID_NDK_HOME="$ANDROID_NDK_HOME" "$SDK_BUNDLE/scripts/setup-android-sdk.sh"
fi

TRIPLE="aarch64-unknown-linux-android28"

echo "==> MeterCore (Packages/MeterKit)"
builtin cd "$ROOT/Packages/MeterKit"
swift build --swift-sdk "$TRIPLE" --target MeterCore

echo "==> MeterProviders (Packages/MeterKit)"
swift build --swift-sdk "$TRIPLE" --target MeterProviders

echo "==> JNI (Android/native, symlink into Packages/)"
builtin cd "$ROOT/Android/native"
swift build --swift-sdk "$TRIPLE" -c release

JNI_DIR="$ROOT/Android/app/src/main/jniLibs/arm64-v8a"
rm -rf "$JNI_DIR"
mkdir -p "$JNI_DIR"

SWIFT_LIBS="$SDK_BUNDLE/swift-resources/usr/lib/swift-aarch64/android"
for so in "$SWIFT_LIBS"/*.so; do
    base="$(basename "$so")"
    case "$base" in
        libTesting.so|libXCTest.so|lib_Testing*.so|libFoundationXML.so) continue ;;
    esac
    cp "$so" "$JNI_DIR/"
done

NDK_SYSROOT="$(echo "$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*/sysroot)"
cp "$NDK_SYSROOT/usr/lib/aarch64-linux-android/libc++_shared.so" "$JNI_DIR/" 2>/dev/null \
    || cp "$NDK_SYSROOT/usr/lib/aarch64-linux-android/28/libc++_shared.so" "$JNI_DIR/"
# NDK libz.so is 4 KiB-aligned. Pixel 16 KB page images (API 35+ Play Store
# 16k AVD, Pixel 10) refuse to load it. FoundationNetworking links libz;
# the system /system/lib64/libz.so is 16 KB-safe.
cp "$ROOT/Android/native/.build/$TRIPLE/release/libMeterCoreJNI.so" "$JNI_DIR/"

ASSET_DIR="$ROOT/Android/app/src/main/assets/swiftpm"
rm -rf "$ASSET_DIR"
mkdir -p "$ASSET_DIR"
shopt -s nullglob
for bundle in "$ROOT/Android/native/.build/$TRIPLE/release"/*.bundle \
              "$ROOT/Android/native/.build/$TRIPLE/release"/*.resources; do
    cp -R "$bundle" "$ASSET_DIR/"
done
shopt -u nullglob
# 资源里有 symlink（catalog.json 链接到 MeterPersistence 那份）。SwiftPM 把链接原样拷进
# .build，相对路径在那儿是断的，所以不能对 .build 里的副本 -L；按同名文件回源码树解析，
# 拷成真文件。留着链接的话 aapt 会静默丢掉它，APK 里就没有目录。
while IFS= read -r link; do
    name="$(basename "$link")"
    source_link="$(find "$ROOT/Android/native/Sources" -type l -name "$name" | head -n 1)"
    if [[ -z "$source_link" ]]; then
        echo "dangling resource symlink with no source counterpart: $link" >&2
        exit 1
    fi
    target="$(cd "$(dirname "$source_link")" && readlink -f "$name")"
    rm "$link"
    cp "$target" "$link"
done < <(find "$ASSET_DIR" -type l)
if ! find "$ASSET_DIR" -name 'aws.json' | grep -q .; then
    echo "SPM resource bundle missing aws.json under $ASSET_DIR" >&2
    ls -la "$ASSET_DIR" >&2 || true
    exit 1
fi

printf 'sdk.dir=%s\n' "$ANDROID_HOME" > "$ROOT/Android/local.properties"

# CI 只要产物：jniLibs + assets 就位后交给 gradle 打 AAB，不装模拟器。
if [[ "${1:-}" == "--build-only" ]]; then
    echo "==> --build-only: jniLibs and assets staged"
    exit 0
fi

if [[ ! -x "$ROOT/Android/gradlew" ]]; then
    echo "Android/gradlew missing; generate the wrapper first" >&2
    exit 1
fi

ADB="$ANDROID_HOME/platform-tools/adb"
if ! "$ADB" devices | grep -q $'emulator-.*\tdevice'; then
    echo "no Android emulator in device state; start one first" >&2
    "$ADB" devices -l >&2 || true
    exit 1
fi

echo "==> Gradle installDebug"
builtin cd "$ROOT/Android"
./gradlew --no-daemon :app:installDebug

"$ADB" shell am force-stop com.zhechengqi.tollcat >/dev/null 2>&1 || true
"$ADB" logcat -c || true
"$ADB" shell am start -W -n com.zhechengqi.tollcat/.MainActivity

prove() {
    "$ADB" logcat -d -b main -s TollCat:* 2>/dev/null || "$ADB" logcat -d | grep TollCat || true
}

LOG=""
for _ in $(seq 1 30); do
    LOG="$(prove)"
    # ui=product 是最后一条：等它出现，前面四条自检必然已经打完
    if echo "$LOG" | grep -F -q 'ui=product'; then
        break
    fi
    sleep 1
done

echo "----- logcat TollCat -----"
echo "$LOG"

fail() {
    echo "PROVE_FAIL: $1" >&2
    exit 1
}

echo "$LOG" | grep -F -q 'formatted=$47.20' || fail "formatted"
echo "$LOG" | grep -F -q 'matches=true' || fail "matches"
echo "$LOG" | grep -F -q 'confidence=estimated' || fail "confidence"
echo "$LOG" | grep -F -q 'estimated=neon' || fail "estimated"
echo "$LOG" | grep -F -q 'source=FixtureLoader.designSnapshots' || fail "FixtureLoader"
echo "$LOG" | grep -F -q 'stubFetch=ok' || fail "stubFetch"
echo "$LOG" | grep -F -q 'keystore=ok' || fail "keystore"
echo "$LOG" | grep -F -q 'persistence=ok' || fail "persistence"
echo "$LOG" | grep -F -q 'ui=product' || fail "ui=product"

dump_ui() {
    "$ADB" shell uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1 || true
    "$ADB" exec-out cat /sdcard/window_dump.xml 2>/dev/null || true
}

tap_text() {
    local xml="$1"
    local needle="$2"
    local bounds
    bounds="$(printf '%s' "$xml" | tr '>' '\n' | grep -F "text=\"$needle\"" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p' | head -n 1)"
    if [[ -z "$bounds" ]]; then
        bounds="$(printf '%s' "$xml" | tr '>' '\n' | grep -F "content-desc=\"$needle\"" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p' | head -n 1)"
    fi
    [[ -n "$bounds" ]] || return 1
    local x1 y1 x2 y2
    read -r x1 y1 x2 y2 <<<"$bounds"
    local x=$(( (x1 + x2) / 2 ))
    local y=$(( (y1 + y2) / 2 ))
    "$ADB" shell input tap "$x" "$y"
}

has_any() {
    local haystack="$1"
    shift
    local needle
    for needle in "$@"; do
        if printf '%s' "$haystack" | grep -F -q "$needle"; then
            return 0
        fi
    done
    return 1
}

tap_first() {
    local xml="$1"
    shift
    local needle
    for needle in "$@"; do
        if tap_text "$xml" "$needle"; then
            return 0
        fi
    done
    return 1
}

# 干净安装先出引导页（三屏）。跳过它——这一段脚本要验的是产品壳，不是引导。
# 以前没有这一步，于是脚本只在「已经过完引导」的机器上能过，而干净安装恰恰是
# 它最该覆盖的那一种。
UI=""
for _ in $(seq 1 10); do
    UI="$(dump_ui)"
    if has_any "$UI" "跳过" "Skip" "スキップ"; then
        tap_first "$UI" "跳过" "Skip" "スキップ" || true
        sleep 2
        UI="$(dump_ui)"
    fi
    if has_any "$UI" "仪表" "Dashboard"; then
        break
    fi
    sleep 1
done
has_any "$UI" "仪表" "Dashboard" || fail "ui-dashboard-tab"
has_any "$UI" "服务" "Services" || fail "ui-services-tab"
has_any "$UI" "设置" "Settings" || fail "ui-settings-tab"
# tab 条比正文先渲染，正文单独等
for _ in $(seq 1 8); do
    if has_any "$UI" "还没有账单" "No Bills Yet" "本月合计" "Month to Date" "八月" "August" "添加第一个服务" "Add First Service"; then
        break
    fi
    sleep 1
    UI="$(dump_ui)"
done
has_any "$UI" "还没有账单" "No Bills Yet" "本月合计" "Month to Date" "八月" "August" "添加第一个服务" "Add First Service" || fail "ui-dashboard-body"

tap_first "$UI" "服务" "Services" || fail "tap-services"
for _ in $(seq 1 8); do
    sleep 1
    UI="$(dump_ui)"
    if has_any "$UI" "添加服务" "Add Service" "还没有接入服务" "No Services Connected" "Cloudflare"; then
        break
    fi
done
has_any "$UI" "添加服务" "Add Service" "还没有接入服务" "No Services Connected" "Cloudflare" || fail "ui-services"

if ! has_any "$UI" "Cloudflare"; then
    tap_first "$UI" "添加服务" "Add Service" "添加第一个服务" "Add First Service" || fail "tap-add"
    # 目录按类别分组，五百多家里 Cloudflare 在「网络与边缘」那一段，首屏看不见。
    # 滚下去找，别指望它恰好在视口里——这条以前是靠目录还小才碰巧过的。
    #
    # 不走搜索框：`input text` 往 Compose 的输入框里打字会丢字（实测
    # "Cloudflare" 变成 "Cllo"），补 keyevent 也一样，那是 IME 的时序，不是产品问题。
    # 滚动不碰输入法。
    for _ in $(seq 1 8); do
        sleep 1
        UI="$(dump_ui)"
        if has_any "$UI" "Cloudflare" "Anthropic" "AI inference" "AI 推理"; then
            break
        fi
    done
    # 慢滑（400ms）而不是快甩：快甩带惯性，会一路冲过「网络与边缘」那一段，
    # 而且滑完立刻 dump 抓到的是还在滚的中间态。滑一屏、等它停稳、再看。
    for _ in $(seq 1 25); do
        if has_any "$UI" "Cloudflare"; then
            break
        fi
        "$ADB" shell input swipe 540 1700 540 700 400
        sleep 1
        UI="$(dump_ui)"
    done
    has_any "$UI" "Cloudflare" || fail "ui-add-cloudflare"
    tap_first "$UI" "添加Cloudflare" "Add Cloudflare" || fail "tap-cloudflare"
    # 行点开的是确认抽屉，再点一次主按钮才真正加进服务。
    # **要重试**：抽屉是滑上来的，一秒后 dump 到的可能是动画中间态，
    # 那一帧的坐标点下去是空的，然后就一直等一个永远不来的详情页。
    for _ in $(seq 1 6); do
        sleep 1
        UI="$(dump_ui)"
        has_any "$UI" "添加Cloudflare" "Add Cloudflare" || break
        tap_first "$UI" "添加Cloudflare" "Add Cloudflare" || true
    done
else
    tap_first "$UI" "Cloudflare" || fail "tap-cloudflare-row"
fi
for _ in $(seq 1 8); do
    sleep 1
    UI="$(dump_ui)"
    if has_any "$UI" "连接Cloudflare" "Connect Cloudflare" "重新填写凭据" "Re-enter Credentials"; then
        break
    fi
done
has_any "$UI" "连接Cloudflare" "Connect Cloudflare" "重新填写凭据" "Re-enter Credentials" || fail "ui-detail"

tap_first "$UI" "连接Cloudflare" "Connect Cloudflare" "重新填写凭据" "Re-enter Credentials" || fail "tap-setup"
# 向导三步：简介 → 教程 → 凭据。一路点主按钮走到凭据页。
for _ in $(seq 1 6); do
    sleep 1
    UI="$(dump_ui)"
    if has_any "$UI" "测试连接" "Test Connection" "API Token"; then
        break
    fi
    tap_first "$UI" "下一步" "Next" "我拿到凭据了，下一步" "I have the credentials" "I Have the Credentials" || true
done
has_any "$UI" "测试连接" "Test Connection" "API Token" || fail "ui-setup"

# TODO(向导自动化)：向导页的 HierarchicalContent 切换动画期间，输入焦点/命中区
# 偏移会让 adb 的坐标输入间歇性落空（field2 经常聚焦不上）。在修好之前，
# 自动验收到「catalog 驱动的凭据字段渲染出来」为止；测试连接→保存→仪表出数
# 这一段用真机手工过（步骤：填两个字段 → 测试连接 → 保存到 Keystore → 回仪表看 $11.05）。

tap_first "$UI" "设置" "Settings" || fail "tap-settings"
for _ in $(seq 1 8); do
    sleep 1
    UI="$(dump_ui)"
    if has_any "$UI" "显示货币" "Display currency" "清空本机数据" "Clear local data"; then
        break
    fi
done
has_any "$UI" "显示货币" "Display currency" "清空本机数据" "Clear local data" || fail "ui-settings"

echo "PROVE_OK"
