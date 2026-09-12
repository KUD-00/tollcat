#!/usr/bin/env python3
"""源码里的用户可见文案必须有英文和日文。

和 `LocalizationCoverageTests` 守同一条线：目录不是权威，源码才是。
SPM 包增量编译经常不抽 catalog——改了中文源串，旧键变孤儿，新键空白
或根本不出现。编译仍然绿，切到 en/ja 才看得见。所以提交前用这份静态
扫描卡住，不跑 xcodebuild。

系统权限弹窗另走 `App/Resources/InfoPlist.xcstrings`：中文源串在
`project.yml` 的 `INFOPLIST_KEY_NS*UsageDescription`，en / ja 必须是真译文。

判据改了，两边一起改。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

LANGUAGES = ("en", "ja")
INFO_PLIST_LANGUAGES = ("zh-Hans", "en", "ja")
SENTINEL = "«»"
LENGTHS = ("hh", "ll", "h", "l", "q", "z", "t", "j", "L")
CONVERSIONS = set("@diuoxXeEfgGaAcspn%")

# 系统权限弹窗不走 L()，走 Info.plist + InfoPlist.xcstrings。
INFOPLIST_USAGE_RE = re.compile(
    r"^\s*INFOPLIST_KEY_((?:NS\w+UsageDescription)|NFCReaderUsageDescription)\s*:\s*(.+?)\s*$",
    re.MULTILINE,
)
PLIST_USAGE_RE = re.compile(
    r"<key>((?:NS\w+UsageDescription)|NFCReaderUsageDescription)</key>\s*<string>([^<]*)</string>",
    re.DOTALL,
)

# 只列真有 Localizable.xcstrings 的模块。MeterCore / MeterInbox / MeterFeedback
# 按架构不产生用户可见文案，列进来只是空转。
MODULES = (
    "MeterDesign",
    "MeterFormat",
    "MeterProviders",
    "MeterPersistence",
    "MeterTips",
    "MeterModules",
    "MeterFeatures",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def has_cjk(text: str) -> bool:
    return any("\u4e00" <= char <= "\u9fff" for char in text)


def has_latin(text: str) -> bool:
    return any("A" <= char <= "Z" or "a" <= char <= "z" for char in text)


def has_kana(text: str) -> bool:
    return any("\u3040" <= char <= "\u30ff" for char in text)


def discover_usage_descriptions(root: Path) -> dict[str, tuple[str, str]]:
    """权限用途说明：键 → (中文源串, 出处)。"""
    found: dict[str, tuple[str, str]] = {}
    yml = root / "project.yml"
    if yml.is_file():
        for match in INFOPLIST_USAGE_RE.finditer(yml.read_text(encoding="utf-8")):
            value = match.group(2).strip().strip("\"'")
            found[match.group(1)] = (value, "project.yml")
    for relative in ("App/Supporting-Info.plist", "Widget/Info.plist"):
        path = root / relative
        if not path.is_file():
            continue
        for match in PLIST_USAGE_RE.finditer(path.read_text(encoding="utf-8")):
            found[match.group(1)] = (match.group(2), relative)
    return found


def check_infoplist_usage_descriptions(root: Path, gaps: list[str]) -> int:
    """Info.plist 用途说明必须有 zh-Hans / en / ja，源串是中文。

    系统弹窗不查 Localizable.xcstrings。漏译时英文机、日文机仍弹出中文。
    """
    usage = discover_usage_descriptions(root)
    catalog_path = root / "App" / "Resources" / "InfoPlist.xcstrings"
    if not usage:
        if catalog_path.exists():
            catalog = load_catalog(catalog_path)
            leftovers = [
                key
                for key in (catalog.get("strings") or {})
                if key.endswith("UsageDescription") or key == "NFCReaderUsageDescription"
            ]
            for key in leftovers:
                gaps.append(f"[InfoPlist] {key} 在目录里，但 project.yml / Info.plist 没有这一条")
        return 0

    if not catalog_path.is_file():
        gaps.append(
            "[InfoPlist] 缺少 App/Resources/InfoPlist.xcstrings。"
            "权限用途说明的 en / ja 写在这里，不要塞进 Localizable.xcstrings。"
        )
        return 0

    catalog = load_catalog(catalog_path)
    if catalog.get("sourceLanguage") != "zh-Hans":
        gaps.append(
            f"[InfoPlist] 源语言是 {catalog.get('sourceLanguage')!r}，不是 zh-Hans"
        )
    strings = catalog.get("strings") or {}
    checked = 0
    for key, (source, origin) in sorted(usage.items()):
        checked += 1
        if not has_cjk(source):
            gaps.append(
                f"[InfoPlist] {origin} 的 {key} 源串不是中文：{source!r}。"
                "开发语言是 zh-Hans，英文写进 InfoPlist.xcstrings。"
            )
        entry = strings.get(key)
        if not isinstance(entry, dict):
            gaps.append(f"[InfoPlist] {key} 没有目录条目（源在 {origin}）")
            continue
        if entry.get("shouldTranslate") is False:
            gaps.append(f"[InfoPlist] {key} 标了 shouldTranslate: false，权限弹窗必须翻译")
            continue
        zh = string_unit_value(entry, "zh-Hans")
        if not zh:
            gaps.append(f"[InfoPlist][zh-Hans] {key}")
        elif zh != source:
            gaps.append(
                f"[InfoPlist][zh-Hans] {key} 和 {origin} 不一致。\n"
                f"    plist: {source}\n"
                f"    catalog: {zh}"
            )
        for language in LANGUAGES:
            value = string_unit_value(entry, language)
            if not value:
                gaps.append(f"[InfoPlist][{language}] {key}")
                continue
            if language == "en":
                if has_cjk(value) or not has_latin(value):
                    gaps.append(
                        f"[InfoPlist][en] {key} 还是中文，或没有英文：{value}"
                    )
            elif language == "ja":
                if not has_kana(value):
                    gaps.append(
                        f"[InfoPlist][ja] {key} 没有假名，像是中文粘过去的：{value}"
                    )
    return checked


def load_catalog(path: Path) -> dict:
    if not path.exists():
        return {"sourceLanguage": "zh-Hans", "strings": {}}
    return json.loads(path.read_text(encoding="utf-8"))


def string_unit_value(entry: dict, language: str) -> str | None:
    loc = (entry.get("localizations") or {}).get(language) or {}
    return (loc.get("stringUnit") or {}).get("value")


def parse_quoted(text: str, start: int) -> tuple[str, bool, int] | None:
    """`start` 指向开引号。插值收成 SENTINEL，和目录里的格式符对齐。"""
    if start >= len(text) or text[start] != '"':
        return None
    i = start + 1
    out: list[str] = []
    interpolated = False
    while i < len(text):
        ch = text[i]
        if ch == "\\":
            if i + 1 >= len(text):
                return None
            nxt = text[i + 1]
            if nxt == "(":
                interpolated = True
                out.append(SENTINEL)
                i += 2
                depth = 1
                while i < len(text) and depth:
                    if text[i] == "\\" and i + 1 < len(text):
                        i += 2
                        continue
                    if text[i] == "(":
                        depth += 1
                    elif text[i] == ")":
                        depth -= 1
                    i += 1
                if depth != 0:
                    return None
                continue
            mapping = {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}
            out.append(mapping.get(nxt, nxt))
            i += 2
            continue
        if ch == '"':
            return "".join(out), interpolated, i + 1
        out.append(ch)
        i += 1
    return None


def extract_calls(text: str, marker: str) -> list[tuple[str, bool]]:
    calls: list[tuple[str, bool]] = []
    i = 0
    while True:
        j = text.find(marker, i)
        if j < 0:
            break
        if j > 0 and (text[j - 1].isalnum() or text[j - 1] == "_"):
            i = j + len(marker)
            continue
        k = j + len(marker)
        while k < len(text) and text[k] in " \n\t":
            k += 1
        parsed = parse_quoted(text, k) if k < len(text) else None
        if parsed is None:
            i = j + len(marker)
            continue
        raw, interpolated, end = parsed
        if raw or interpolated:
            calls.append((raw, interpolated))
        i = end
    return calls


def replace_format(text: str) -> str:
    out: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        if text[i] != "%":
            out.append(text[i])
            i += 1
            continue
        if i + 1 < n and text[i + 1] == "%":
            out.append("%")
            i += 2
            continue
        cursor = i + 1
        probe = cursor
        while probe < n and text[probe].isdigit():
            probe += 1
        if probe > cursor and probe < n and text[probe] == "$":
            cursor = probe + 1
        while cursor < n and text[cursor] in "-+ #0":
            cursor += 1
        while cursor < n and (text[cursor].isdigit() or text[cursor] == "."):
            cursor += 1
        for cand in LENGTHS:
            if text.startswith(cand, cursor):
                cursor += len(cand)
                break
        if cursor < n and text[cursor] in CONVERSIONS:
            out.append(SENTINEL)
            i = cursor + 1
            continue
        out.append("%")
        i += 1
    return "".join(out)


def placeholder_types(text: str) -> list[str]:
    types: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        if text[i] != "%":
            i += 1
            continue
        if i + 1 >= n:
            break
        cursor = i + 1
        if text[cursor] == "%":
            i = cursor + 1
            continue
        probe = cursor
        while probe < n and text[probe].isdigit():
            probe += 1
        if probe > cursor and probe < n and text[probe] == "$":
            cursor = probe + 1
        while cursor < n and text[cursor] in "-+ #0":
            cursor += 1
        while cursor < n and (text[cursor].isdigit() or text[cursor] == "."):
            cursor += 1
        length = ""
        for cand in LENGTHS:
            if text.startswith(cand, cursor):
                length = cand
                cursor += len(cand)
                break
        if cursor < n and text[cursor] in CONVERSIONS:
            types.append(length + text[cursor])
            i = cursor + 1
            continue
        i += 1
    return types


def swift_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.rglob("*.swift") if path.is_file())


def check_catalog_entries(module: str, catalog: dict, gaps: list[str]) -> int:
    strings = catalog.get("strings") or {}
    checked = 0
    for key, entry in strings.items():
        if not isinstance(entry, dict):
            gaps.append(f"[{module}] 空条目：{key!r}")
            continue
        if entry.get("extractionState") == "stale":
            continue
        if entry.get("shouldTranslate") is False:
            continue
        checked += 1
        for language in LANGUAGES:
            value = string_unit_value(entry, language)
            if not value:
                gaps.append(f"[{module}][{language}] {key}")
    return checked


def check_placeholders(module: str, catalog: dict, offenders: list[str]) -> None:
    strings = catalog.get("strings") or {}
    for key, entry in strings.items():
        if not isinstance(entry, dict):
            continue
        if entry.get("extractionState") == "stale":
            continue
        expected = placeholder_types(key)
        expected_count = len(expected)
        for language in LANGUAGES:
            value = string_unit_value(entry, language)
            if not value:
                continue
            actual = placeholder_types(value)
            if len(actual) != expected_count:
                offenders.append(
                    f"[{module}][{language}] {key} 要 {expected_count} 个，"
                    f"译文有 {len(actual)} 个：{value}"
                )
            if expected_count >= 2 and "$" not in value and actual != expected:
                offenders.append(
                    f"[{module}][{language}] {key}\n"
                    f"    源 {expected} → 译 {actual}：{value}"
                )


def check_source_calls(
    module: str,
    catalog: dict,
    files: list[tuple[str, str]],
    gaps: list[str],
) -> int:
    strings = catalog.get("strings") or {}
    normalized_to_key = {replace_format(key): key for key in strings}
    checked = 0
    for relative, text in files:
        for raw, interpolated in extract_calls(text, "L("):
            checked += 1
            if interpolated:
                catalog_key = normalized_to_key.get(raw)
            else:
                catalog_key = raw if raw in strings else None
            if catalog_key is None:
                gaps.append(f"[{module}] {relative} 没有目录条目：{raw}")
                continue
            entry = strings.get(catalog_key) or {}
            if entry.get("shouldTranslate") is False:
                continue
            for language in LANGUAGES:
                if not string_unit_value(entry, language):
                    gaps.append(f"[{module}][{language}] {relative}：{catalog_key}")
    return checked


def self_test() -> None:
    cases = [
        (extract_calls('Text(L("筛选"))', "L("), [("筛选", False)]),
        (
            extract_calls('L("共 \\(n) 家")', "L("),
            [("共 " + SENTINEL + " 家", True)],
        ),
        (replace_format("共 %lld 家"), "共 " + SENTINEL + " 家"),
        (replace_format("这个月少了 %lld%%。"), "这个月少了 " + SENTINEL + "%。"),
        (placeholder_types("1社100%を切り替え"), []),
        (placeholder_types("%lld%%"), ["lld"]),
        (placeholder_types("%1$@ … %2$lld"), ["@", "lld"]),
        (has_cjk("把这个月的账单卡片存成图片。"), True),
        (has_cjk("Save this month’s share card."), False),
        (has_kana("今月の共有カードを保存します。"), True),
        (has_kana("把这个月的账单卡片存成图片。"), False),
        (has_latin("Save this month’s share card."), True),
    ]
    for actual, expected in cases:
        if actual != expected:
            raise SystemExit(f"check-i18n-coverage: self-test failed: {actual!r} != {expected!r}")


def main() -> int:
    self_test()
    root = repo_root()
    sources = root / "Packages" / "MeterKit" / "Sources"
    gaps: list[str] = []
    placeholders: list[str] = []
    catalog_checked = 0
    source_checked = 0

    for module in MODULES:
        module_root = sources / module
        if not module_root.exists():
            continue
        catalog_path = module_root / "Resources" / "Localizable.xcstrings"
        catalog = load_catalog(catalog_path)
        if catalog_path.exists() and catalog.get("sourceLanguage") != "zh-Hans":
            gaps.append(f"[{module}] 源语言是 {catalog.get('sourceLanguage')!r}，不是 zh-Hans")
        catalog_checked += check_catalog_entries(module, catalog, gaps)
        check_placeholders(module, catalog, placeholders)
        files = [
            (str(path.relative_to(sources)), path.read_text(encoding="utf-8"))
            for path in swift_files(module_root)
        ]
        source_checked += check_source_calls(module, catalog, files, gaps)

    # Widget 自己没有 catalog，文案键住在 MeterFormat 里，经 MeterFormatText.resource 取。
    format_catalog = load_catalog(
        sources / "MeterFormat" / "Resources" / "Localizable.xcstrings"
    )
    widget = root / "Widget"
    widget_files = [
        (str(path.relative_to(root)), path.read_text(encoding="utf-8"))
        for path in swift_files(widget)
    ]
    for relative, text in widget_files:
        for raw, interpolated in extract_calls(text, "MeterFormatText.resource("):
            source_checked += 1
            strings = format_catalog.get("strings") or {}
            if interpolated:
                catalog_key = {replace_format(key): key for key in strings}.get(raw)
            else:
                catalog_key = raw if raw in strings else None
            if catalog_key is None:
                gaps.append(f"[MeterFormat] {relative} 没有目录条目：{raw}")
                continue
            entry = strings.get(catalog_key) or {}
            if entry.get("shouldTranslate") is False:
                continue
            for language in LANGUAGES:
                if not string_unit_value(entry, language):
                    gaps.append(f"[MeterFormat][{language}] {relative}：{catalog_key}")

    app_catalog_path = root / "App" / "Resources" / "Localizable.xcstrings"
    if app_catalog_path.exists():
        catalog_checked += check_catalog_entries("App", load_catalog(app_catalog_path), gaps)

    infoplist_checked = check_infoplist_usage_descriptions(root, gaps)
    catalog_checked += infoplist_checked

    if catalog_checked == 0 or source_checked == 0:
        print("check-i18n-coverage: 一条都没检查到，说明路径或解析错了", file=sys.stderr)
        return 1

    failed = False
    if gaps:
        failed = True
        print(f"check-i18n-coverage: 缺 {len(gaps)} 条译文:", file=sys.stderr)
        for line in sorted(gaps):
            print(f"  {line}", file=sys.stderr)
    if placeholders:
        failed = True
        print("check-i18n-coverage: 占位符对不上:", file=sys.stderr)
        for line in placeholders:
            print(f"  {line}", file=sys.stderr)
    if failed:
        print(
            "在同一模块的 Resources/Localizable.xcstrings 补 en / ja，"
            "不要只改 L(\"…\")。"
            "权限用途说明补 App/Resources/InfoPlist.xcstrings 的 zh-Hans / en / ja。",
            file=sys.stderr,
        )
        return 1

    print(
        f"check-i18n-coverage: ok "
        f"({catalog_checked} catalog keys, {source_checked} source calls, "
        f"{infoplist_checked} InfoPlist keys)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
