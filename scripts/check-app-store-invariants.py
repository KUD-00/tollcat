#!/usr/bin/env python3
"""App Store 送审能在源码里卡住的那几条。

对照送审 skill（JustinPerea / safaiyeh / dpearson 那套）里**可以静态判定**的项：
权限 API 对用途说明、用途说明没有多申请、隐私清单 Required Reason API、
出口合规、ATS、UIWebView、App 图标不透明、Launch Screen、App Group 一致。

不在这里管的：截图、审核备注、商店文案、0.x 版本号、演示账号——那些要人看
App Store Connect。漏了权限键会在审核员点「存到相册」时直接崩，必须机器盯。

运行时行为仍只在 xcodebuild test 里。
"""

from __future__ import annotations

import plistlib
import re
import struct
import sys
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

# 代码模式 → Info.plist 用途说明。模式要具体，避免 `import Photos` 误伤。
PERMISSION_RULES = (
    (
        "相册写入",
        (
            r"requestAuthorization\(for:\s*\.addOnly",
            r"UIImageWriteToSavedPhotosAlbum",
            r"PHAssetCreationRequest",
        ),
        ("NSPhotoLibraryAddUsageDescription",),
    ),
    (
        "相册读取",
        (
            r"requestAuthorization\(for:\s*\.readWrite",
            r"PHPhotoLibrary\.requestAuthorization\s*\(\s*\)",
            r"PHPhotoLibrary\.requestAuthorization\s*\{",
            r"\bPhotosPicker\b",
            r"\bPHPickerViewController\b",
            r"\bUIImagePickerController\b",
        ),
        ("NSPhotoLibraryUsageDescription",),
    ),
    (
        "相机",
        (
            r"\bAVCaptureDevice\b",
            r"\bAVCaptureSession\b",
            r"\bVNDocumentCameraViewController\b",
        ),
        ("NSCameraUsageDescription",),
    ),
    (
        "麦克风",
        (
            r"\bAVAudioRecorder\b",
            r"requestRecordPermission",
            r"AVAudioApplication\.requestRecordPermission",
        ),
        ("NSMicrophoneUsageDescription",),
    ),
    (
        "定位使用中",
        (r"requestWhenInUseAuthorization", r"showsUserLocation\s*="),
        ("NSLocationWhenInUseUsageDescription",),
    ),
    (
        "定位始终",
        (r"requestAlwaysAuthorization",),
        ("NSLocationAlwaysAndWhenInUseUsageDescription",),
    ),
    (
        "通讯录",
        (r"\bCNContactStore\b",),
        ("NSContactsUsageDescription",),
    ),
    (
        "日历写入",
        (r"requestWriteOnlyAccessToEvents",),
        ("NSCalendarsWriteOnlyAccessUsageDescription",),
    ),
    (
        "日历全部",
        (r"requestFullAccessToEvents",),
        ("NSCalendarsFullAccessUsageDescription",),
    ),
    (
        "蓝牙",
        (r"\bCBCentralManager\b", r"\bCBPeripheralManager\b"),
        ("NSBluetoothAlwaysUsageDescription",),
    ),
    (
        "运动与健身",
        (r"\bCMMotionManager\b", r"\bCMPedometer\b"),
        ("NSMotionUsageDescription",),
    ),
    (
        "语音识别",
        (r"\bSFSpeechRecognizer\b",),
        ("NSSpeechRecognitionUsageDescription",),
    ),
    (
        "Face ID",
        (r"deviceOwnerAuthenticationWithBiometrics",),
        ("NSFaceIDUsageDescription",),
    ),
    (
        "本地网络",
        (r"\bNWBrowser\b", r"\bNWListener\b"),
        ("NSLocalNetworkUsageDescription",),
    ),
    (
        "跟踪",
        (r"\bATTrackingManager\b", r"requestTrackingAuthorization"),
        ("NSUserTrackingUsageDescription",),
    ),
    (
        "NFC",
        (r"\bNFCTagReaderSession\b", r"\bNFCNDEFReaderSession\b"),
        ("NFCReaderUsageDescription",),
    ),
)

REQUIRED_REASON_RULES = (
    (
        "UserDefaults",
        (r"\bUserDefaults\b", r"@AppStorage"),
        "NSPrivacyAccessedAPICategoryUserDefaults",
    ),
    (
        "文件时间戳",
        (
            r"attributesOfItem\(atPath",
            r"URLResourceKey\.creationDateKey",
            r"URLResourceKey\.contentModificationDateKey",
            r"contentModificationDateKey",
        ),
        "NSPrivacyAccessedAPICategoryFileTimestamp",
    ),
    (
        "系统启动时间",
        (r"systemUptime", r"\bmach_absolute_time\b"),
        "NSPrivacyAccessedAPICategorySystemBootTime",
    ),
    (
        "磁盘空间",
        (
            r"volumeAvailableCapacity",
            r"attributesOfFileSystem",
            r"\bstatfs\s*\(",
        ),
        "NSPrivacyAccessedAPICategoryDiskSpace",
    ),
    (
        "活跃键盘",
        (r"activeInputModes",),
        "NSPrivacyAccessedAPICategoryActiveKeyboards",
    ),
)

INFOPLIST_USAGE_RE = re.compile(
    r"^\s*INFOPLIST_KEY_((?:NS\w+UsageDescription)|NFCReaderUsageDescription)\s*:\s*(.+?)\s*$",
    re.MULTILINE,
)
PLIST_USAGE_RE = re.compile(
    r"<key>((?:NS\w+UsageDescription)|NFCReaderUsageDescription)</key>\s*<string>([^<]*)</string>",
    re.DOTALL,
)
ENCRYPTION_RE = re.compile(
    r"INFOPLIST_KEY_ITSAppUsesNonExemptEncryption\s*:\s*(YES|NO)",
)
ARBITRARY_LOADS_RE = re.compile(
    r"NSAllowsArbitraryLoads\s*[:=]\s*(true|YES)",
    re.IGNORECASE,
)
UIWEBVIEW_RE = re.compile(r"\bUIWebView\b")


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def rel(root: Path, path: Path) -> str:
    return str(path.relative_to(root))


def swift_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.rglob("*.swift") if path.is_file())


def production_swift(root: Path, *folders: str) -> list[Path]:
    files: list[Path] = []
    for folder in folders:
        files.extend(swift_files(root / folder))
    return files


DEBUG_BLOCK_RE = re.compile(
    r"#if\s+DEBUG\b.*?(?:#else(.*?))?#endif",
    re.DOTALL,
)


def strip_debug_blocks(text: str) -> str:
    """`#if DEBUG` 进不了 App Store 包。有 `#else` 的留下 else 支。"""

    def replace(match: re.Match[str]) -> str:
        return match.group(1) or ""

    return DEBUG_BLOCK_RE.sub(replace, text)


def concatenated(files: list[Path]) -> str:
    return "\n".join(strip_debug_blocks(path.read_text(encoding="utf-8")) for path in files)


def load_plist(path: Path) -> dict:
    with path.open("rb") as handle:
        return plistlib.load(handle)


def discover_usage_keys(root: Path) -> dict[str, str]:
    found: dict[str, str] = {}
    yml = root / "project.yml"
    if yml.is_file():
        for match in INFOPLIST_USAGE_RE.finditer(yml.read_text(encoding="utf-8")):
            found[match.group(1)] = "project.yml"
    for relative in ("App/Supporting-Info.plist", "Widget/Info.plist"):
        path = root / relative
        if not path.is_file():
            continue
        for match in PLIST_USAGE_RE.finditer(path.read_text(encoding="utf-8")):
            found[match.group(1)] = relative
    return found


def privacy_categories(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    payload = load_plist(path)
    categories: set[str] = set()
    for entry in payload.get("NSPrivacyAccessedAPITypes") or []:
        if isinstance(entry, dict):
            category = entry.get("NSPrivacyAccessedAPIType")
            if isinstance(category, str):
                categories.add(category)
    return categories


def png_ihdr(path: Path) -> tuple[int, int, int] | None:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        return None
    if len(data) < 29:
        return None
    length = struct.unpack(">I", data[8:12])[0]
    chunk = data[12:16]
    if chunk != b"IHDR" or length < 13:
        return None
    width, height, _bit_depth, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, color_type


def png_has_alpha(path: Path) -> bool:
    header = png_ihdr(path)
    if header is None:
        return True
    _width, _height, color_type = header
    if color_type in (4, 6):
        return True
    data = path.read_bytes()
    offset = 8
    while offset + 8 <= len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk = data[offset + 4 : offset + 8]
        if chunk == b"tRNS":
            return True
        offset += 12 + length
    return False


def check_permission_keys(root: Path, errors: list[str]) -> None:
    sources = production_swift(
        root, "App", "Mac", "Widget", "Packages/MeterKit/Sources"
    )
    blob = concatenated(sources)
    declared = discover_usage_keys(root)
    needed: set[str] = set()
    for label, patterns, keys in PERMISSION_RULES:
        if any(re.search(pattern, blob) for pattern in patterns):
            needed.update(keys)
            for key in keys:
                if key not in declared:
                    errors.append(
                        f"用了{label} API，但没有 {key}。"
                        f"写到 project.yml 的 INFOPLIST_KEY_{key}，"
                        "并在 App/Resources/InfoPlist.xcstrings 补 zh-Hans / en / ja。"
                    )
    for key, origin in sorted(declared.items()):
        if key not in needed:
            errors.append(
                f"{origin} 声明了 {key}，源码里没有对应 API。"
                "多申请的权限审核会问，删掉键，或补上真正用到的调用。"
            )


def check_privacy_manifests(root: Path, errors: list[str]) -> None:
    app_manifest = root / "App" / "Resources" / "PrivacyInfo.xcprivacy"
    widget_manifest = root / "Widget" / "PrivacyInfo.xcprivacy"
    if not app_manifest.is_file():
        errors.append("缺少 App/Resources/PrivacyInfo.xcprivacy")
    if not widget_manifest.is_file():
        errors.append("缺少 Widget/PrivacyInfo.xcprivacy")

    app_code = concatenated(production_swift(root, "App", "Mac", "Packages/MeterKit/Sources"))
    widget_code = concatenated(production_swift(root, "Widget"))
    app_categories = privacy_categories(app_manifest)
    widget_categories = privacy_categories(widget_manifest)

    for label, patterns, category in REQUIRED_REASON_RULES:
        app_hit = any(re.search(pattern, app_code) for pattern in patterns)
        widget_hit = any(re.search(pattern, widget_code) for pattern in patterns)
        if app_hit and category not in app_categories:
            errors.append(
                f"App / MeterKit 用了{label}，"
                f"App/Resources/PrivacyInfo.xcprivacy 要声明 {category}"
            )
        if widget_hit and category not in widget_categories:
            errors.append(
                f"Widget 用了{label}，Widget/PrivacyInfo.xcprivacy 要声明 {category}"
            )


def check_export_compliance(root: Path, errors: list[str]) -> None:
    yml = (root / "project.yml").read_text(encoding="utf-8")
    match = ENCRYPTION_RE.search(yml)
    if match is None:
        errors.append(
            "project.yml 缺少 INFOPLIST_KEY_ITSAppUsesNonExemptEncryption。"
            "只用 HTTPS / Keychain / CryptoKit 时写 NO，否则每次上传都卡出口合规。"
        )


def check_ats_and_webviews(root: Path, errors: list[str]) -> None:
    for relative in (
        "project.yml",
        "App/Supporting-Info.plist",
        "Widget/Info.plist",
    ):
        path = root / relative
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        if ARBITRARY_LOADS_RE.search(text):
            errors.append(f"{relative} 开了 NSAllowsArbitraryLoads")
    for path in production_swift(root, "App", "Widget", "Packages/MeterKit/Sources"):
        text = path.read_text(encoding="utf-8")
        for index, line in enumerate(text.splitlines(), 1):
            if UIWEBVIEW_RE.search(line):
                errors.append(f"{rel(root, path)}:{index} 用了 UIWebView（ITMS-90809）")


def check_app_icon(root: Path, errors: list[str]) -> None:
    iconset = root / "App" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
    contents_path = iconset / "Contents.json"
    if not contents_path.is_file():
        errors.append("缺少 AppIcon.appiconset/Contents.json")
        return
    import json

    contents = json.loads(contents_path.read_text(encoding="utf-8"))
    default = None
    for image in contents.get("images") or []:
        if image.get("appearances"):
            continue
        if image.get("size") == "1024x1024":
            default = image.get("filename")
            break
    if not default:
        errors.append("AppIcon 缺 1024×1024 默认图（商店页抽这一张）")
        return
    path = iconset / default
    if not path.is_file():
        errors.append(f"AppIcon 引用了 {default}，文件不在")
        return
    header = png_ihdr(path)
    if header is None:
        errors.append(f"{default} 不是 PNG")
        return
    width, height, _color_type = header
    if width != 1024 or height != 1024:
        errors.append(f"{default} 是 {width}×{height}，商店要 1024×1024")
    if png_has_alpha(path):
        errors.append(f"{default} 带透明通道。默认 App Store 图标必须不透明。")


def check_launch_screen(root: Path, errors: list[str]) -> None:
    yml = (root / "project.yml").read_text(encoding="utf-8")
    if "INFOPLIST_KEY_UILaunchStoryboardName" not in yml:
        errors.append("project.yml 缺少 UILaunchStoryboardName")
    storyboard = root / "App" / "LaunchScreen.storyboard"
    if not storyboard.is_file():
        errors.append("缺少 App/LaunchScreen.storyboard")


def check_app_groups(root: Path, errors: list[str]) -> None:
    pairs = (
        (
            root / "App" / "TollCat.entitlements",
            root / "Widget" / "TollCatWidget.entitlements",
            "iOS",
        ),
        (
            root / "Mac" / "TollCatMac.entitlements",
            root / "Mac" / "TollCatWidgetMac.entitlements",
            "Mac",
        ),
    )
    for app, widget, label in pairs:
        if not app.is_file() or not widget.is_file():
            errors.append(f"{label} App 或 Widget 的 entitlements 不在原位")
            continue
        app_groups = set(load_plist(app).get("com.apple.security.application-groups") or [])
        widget_groups = set(
            load_plist(widget).get("com.apple.security.application-groups") or []
        )
        if not app_groups:
            errors.append(f"{label} App entitlements 没有 application-groups")
        if not widget_groups:
            errors.append(f"{label} Widget entitlements 没有 application-groups")
        if app_groups and widget_groups and app_groups != widget_groups:
            errors.append(
                f"{label} App Group 不一致：App {sorted(app_groups)} / Widget {sorted(widget_groups)}"
            )


# 一档商店尺寸对应的像素。ASC 只收这几个数，差一个像素就整批退回来。
MARKETING_SIZES = {
    "iphone65": (1284, 2778),
    "iphone69": (1320, 2868),
    "ipad13": (2752, 2064),
}
MARKETING_LOCALES = ("zh", "en", "ja")
MARKETING_THEMES = ("light", "dark")
# ASC 每档最多 10 张。
MARKETING_MAX_SCREENS = 10


def check_marketing_screenshots(root: Path, errors: list[str]) -> None:
    """要上传的宣传图：尺寸、成套、不带透明通道。

    这三样都是「审核员点一下就退回来」那一类，不是风格偏好：尺寸差一个像素
    ASC 直接拒收，带 alpha 的 PNG 同理。成套是另一回事——渲图脚本中途死掉时
    产物目录里会留下上一轮的旧图，缺的那几张不会有人发现，直到某一种语言的
    商店页少了一屏。

    宣传图本身不进仓库（见 .gitignore 末尾那段），所以 CI 的检出里没有这个目录，
    这一条只在本机跑得到——渲完图、贴进 ASC 之前跑一次闸，是这批图唯一的检查点。
    目录不在就直接跳过：报错的话 CI 上这一条会恒红，而 CI 无论如何也看不到图。
    """
    directory = root / "docs/appstore/marketing"
    if not directory.is_dir():
        return
    groups: dict[tuple[str, str], set[tuple[str, str]]] = {}
    for path in sorted(directory.glob("*.png")):
        parts = path.stem.split("-")
        if len(parts) != 4:
            errors.append(f"marketing/{path.name} 的文件名不是 <档>-<屏>-<语言>-<明暗>")
            continue
        prefix, screen, locale, theme = parts
        if prefix not in MARKETING_SIZES:
            errors.append(f"marketing/{path.name} 的尺寸档 {prefix} 不认识")
            continue
        if locale not in MARKETING_LOCALES or theme not in MARKETING_THEMES:
            errors.append(f"marketing/{path.name} 的语言 / 明暗不认识")
            continue
        groups.setdefault((prefix, screen), set()).add((locale, theme))
        header = png_ihdr(path)
        if header is None:
            errors.append(f"marketing/{path.name} 不是 PNG")
            continue
        width, height, _color_type = header
        if (width, height) != MARKETING_SIZES[prefix]:
            want = MARKETING_SIZES[prefix]
            errors.append(
                f"marketing/{path.name} 是 {width}×{height}，{prefix} 档要 {want[0]}×{want[1]}"
            )
        if png_has_alpha(path):
            errors.append(f"marketing/{path.name} 带透明通道，ASC 不收")
    if not groups:
        errors.append("docs/appstore/marketing 里一张图都没有")
        return
    want = {(locale, theme) for locale in MARKETING_LOCALES for theme in MARKETING_THEMES}
    for (prefix, screen), have in sorted(groups.items()):
        missing = want - have
        if missing:
            listed = "、".join(f"{locale}-{theme}" for locale, theme in sorted(missing))
            errors.append(f"marketing/{prefix}-{screen} 少了：{listed}")
    for prefix in MARKETING_SIZES:
        screens = [screen for (candidate, screen) in groups if candidate == prefix]
        if not screens:
            errors.append(f"marketing/ 里没有 {prefix} 档")
        elif len(screens) > MARKETING_MAX_SCREENS:
            errors.append(
                f"marketing/{prefix} 有 {len(screens)} 屏，ASC 每档最多 {MARKETING_MAX_SCREENS}"
            )


def self_test() -> None:
    cases = [
        (bool(re.search(PERMISSION_RULES[0][1][0], "requestAuthorization(for: .addOnly)")), True),
        (bool(re.search(PERMISSION_RULES[1][1][0], "requestAuthorization(for: .addOnly)")), False),
        (bool(re.search(r"\bUserDefaults\b", "UserDefaultsVisitMarker")), False),
        (bool(re.search(r"\bUserDefaults\b", "UserDefaults.standard")), True),
        (
            "contentModificationDateKey" in strip_debug_blocks(
                "#if DEBUG\n.contentModificationDateKey\n#endif\nUserDefaults.standard\n"
            ),
            False,
        ),
        (
            "UserDefaults.standard" in strip_debug_blocks(
                "#if DEBUG\n.contentModificationDateKey\n#endif\nUserDefaults.standard\n"
            ),
            True,
        ),
    ]
    for actual, expected in cases:
        if actual != expected:
            raise SystemExit(
                f"check-app-store-invariants: self-test failed: {actual!r} != {expected!r}"
            )


def main() -> int:
    self_test()
    root = repo_root()
    errors: list[str] = []
    check_permission_keys(root, errors)
    check_privacy_manifests(root, errors)
    check_export_compliance(root, errors)
    check_ats_and_webviews(root, errors)
    check_app_icon(root, errors)
    check_launch_screen(root, errors)
    check_app_groups(root, errors)
    check_marketing_screenshots(root, errors)

    if errors:
        print(f"check-app-store-invariants: {len(errors)} 处送审风险:", file=sys.stderr)
        for line in errors:
            print(f"  {line}", file=sys.stderr)
        print(
            "这些是审核员点一下就会拒或崩的配置，不是风格偏好。",
            file=sys.stderr,
        )
        return 1

    print("check-app-store-invariants: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
