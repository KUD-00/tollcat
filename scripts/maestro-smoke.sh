#!/usr/bin/env bash
# UI 冒烟：maestro/ 里的流程跑在 iOS 模拟器 / Android 模拟器上。
#
#     bash scripts/maestro-smoke.sh            # iOS（默认）
#     bash scripts/maestro-smoke.sh android    # Android（要先有 android-run.sh 编出来的 jniLibs）
#     bash scripts/maestro-smoke.sh all
#
# 环境变量：
#     SKIP_BUILD=1        不重编，直接装 DerivedData / gradle 里现成的包
#     ADHOC_SIGN=1        不带开发者账号的 ad-hoc 签名（CI 用）。不能 CODE_SIGNING_ALLOWED=NO：
#                         完全不签名的包 Keychain 会给 -34018，演示种子静默失败，仪表盘就是空的。
#     IPHONE_NAME         默认 iPhone 17 Pro
#     DERIVED             默认 /tmp/dd-maestro
#     MAESTRO_OUTPUT      给了就把 junit 报告写到这个路径
#
# Maestro 只是开发工具，不进任何 target，不算「引入第三方库」；装在 ~/.maestro，不进仓库。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="com.zhechengqi.tollcat"
IPHONE_NAME="${IPHONE_NAME:-iPhone 17 Pro}"
DERIVED="${DERIVED:-/tmp/dd-maestro}"
SKIP_BUILD="${SKIP_BUILD:-0}"
ADHOC_SIGN="${ADHOC_SIGN:-0}"
TARGET="${1:-ios}"

export MAESTRO_CLI_NO_ANALYTICS=1
export PATH="$PATH:$HOME/.maestro/bin"

if ! command -v maestro >/dev/null; then
    echo "maestro not on PATH. Install: curl -fsSL https://get.maestro.mobile.dev | bash" >&2
    exit 1
fi
if ! command -v java >/dev/null && [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" ]]; then
    # Maestro 是 JVM 程序；本机没装系统 Java 时借 Android Studio 的 JBR。
    export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

maestro_test() {
    local device="$1"
    local -a args=(--device "$device" test)
    if [[ -n "${MAESTRO_OUTPUT:-}" ]]; then
        args+=(--format junit --output "$MAESTRO_OUTPUT")
    fi
    maestro "${args[@]}" "$ROOT/maestro"
}

udid_for_device() {
    xcrun simctl list devices available \
        | awk -v name="$1" '
            index($0, name " (") {
                if (match($0, /\(([0-9A-F-]{36})\)/)) {
                    print substr($0, RSTART+1, RLENGTH-2)
                    exit
                }
            }'
}

run_ios() {
    local udid
    udid="$(udid_for_device "$IPHONE_NAME")"
    if [[ -z "$udid" ]]; then
        echo "simulator not found: $IPHONE_NAME" >&2
        xcrun simctl list devices available >&2
        exit 1
    fi

    if [[ "$SKIP_BUILD" != "1" ]]; then
        local -a signing=()
        if [[ "$ADHOC_SIGN" == "1" ]]; then
            signing=(DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual PROVISIONING_PROFILE_SPECIFIER=)
        fi
        echo "==> build Debug ($IPHONE_NAME)"
        xcodebuild \
            -project "$ROOT/TollCat.xcodeproj" \
            -scheme TollCat \
            -configuration Debug \
            -destination "platform=iOS Simulator,name=$IPHONE_NAME" \
            -derivedDataPath "$DERIVED" \
            "${signing[@]}" \
            build
    fi

    local app="$DERIVED/Build/Products/Debug-iphonesimulator/TollCat.app"
    if [[ ! -d "$app" ]]; then
        echo "TollCat.app not found under $DERIVED" >&2
        exit 1
    fi

    echo "==> boot $IPHONE_NAME ($udid)"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b
    echo "==> install"
    xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
    xcrun simctl install "$udid" "$app"

    echo "==> maestro (iOS)"
    maestro_test "$udid"
}

run_android() {
    export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
    export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
    export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

    local serial
    serial="$(adb devices | awk '/^emulator-.*\tdevice$/ { print $1; exit }')"
    if [[ -z "$serial" ]]; then
        echo "no Android emulator in device state; start one first" >&2
        adb devices -l >&2 || true
        exit 1
    fi

    if [[ "$SKIP_BUILD" != "1" ]]; then
        if [[ ! -f "$ROOT/Android/app/src/main/jniLibs/arm64-v8a/libMeterCoreJNI.so" ]]; then
            echo "jniLibs missing; run scripts/android-run.sh once to build MeterCore for Android" >&2
            exit 1
        fi
        echo "==> gradle installDebug"
        (builtin cd "$ROOT/Android" && ./gradlew --no-daemon -q :app:installDebug)
    fi

    echo "==> maestro (Android, $serial)"
    maestro_test "$serial"
}

case "$TARGET" in
    ios) run_ios ;;
    android) run_android ;;
    all) run_ios; run_android ;;
    *)
        echo "usage: $0 [ios|android|all]" >&2
        exit 2
        ;;
esac
