#!/usr/bin/env python3
"""Windows 的 en / ja 文案由 iOS 的 Localizable.xcstrings 生成。

分工：
- `Windows/app/Strings/zh-Hans/Resources.resw`（中文）仍然手写——它决定
  Windows 用哪些句子、资源名叫什么。占位符用 {0}/{1}。
- 每条中文在 iOS 的 String Catalog 里找同文（占位符归一后精确匹配），
  en / ja 取 catalog 的译文，写出 `en-US` / `ja-JP`（生成物，提交进仓库）。
- Windows 独有的句子（凭据管理器、托盘、MSIX……）不在 catalog 里，
  它们的 en / ja 手工维护在 `Windows/app/strings-windows-only.json`。
- 中文既不在 catalog、也不在 windows-only 清单里 → 报错。

    python3 scripts/generate-windows-strings.py            # 写出 en-US / ja-JP
    python3 scripts/generate-windows-strings.py --check    # 只比对（提交闸）
"""

from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STRINGS = ROOT / "Windows/app/Strings"
ALLOWLIST = ROOT / "Windows/app/strings-windows-only.json"
LANGUAGES = ("en", "ja")
LANG_FOLDER = {"en": "en-US", "ja": "ja-JP"}

XCSTRINGS = (
    "Packages/MeterKit/Sources/MeterFeatures/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterDesign/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterFormat/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterPersistence/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterProviders/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterTips/Resources/Localizable.xcstrings",
    "App/Resources/Localizable.xcstrings",
)

RESW_HEADER = """<?xml version="1.0" encoding="utf-8"?>
<root>
  <!-- GENERATED — 由 scripts/generate-windows-strings.py 生成，不要手改。
       和 iOS 同文的句子：改对应模块的 Localizable.xcstrings；
       Windows 独有的句子：改 Windows/app/strings-windows-only.json。 -->
"""


def canon_ios(text: str) -> str:
    text = re.sub(r"%(\d+)\$@", "%@", text)
    text = re.sub(r"%(\d+)\$lld", "%lld", text)
    text = re.sub(r"%(\d+)\$(\.\d+f)", r"%\2", text)
    return text


def canon_windows(text: str) -> str:
    """{0}/{1} 折成 %@，数字型仍当字符串——对不上就走 windows-only。"""
    return re.sub(r"\{\d+\}", "%@", text)


_IOS_SPEC = re.compile(r"%(?:(?P<pos>\d+)\$)?(?P<typ>@|lld|ld|d|\.\d+f)|(?P<pct>%%)")


def ios_value_to_windows(value: str) -> str:
    counter = 0

    def repl(match: re.Match) -> str:
        nonlocal counter
        if match.group("pct"):
            return "%"
        pos = match.group("pos")
        if pos is None:
            idx = counter
            counter += 1
        else:
            idx = int(pos) - 1
            counter = max(counter, idx + 1)
        return "{" + str(idx) + "}"

    return _IOS_SPEC.sub(repl, value)


def escape_xml(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def load_catalog() -> tuple[dict[str, dict[str, str]], list[str]]:
    table: dict[str, dict[str, str]] = {}
    problems: list[str] = []
    for relative in XCSTRINGS:
        path = ROOT / relative
        if not path.exists():
            problems.append(f"找不到 {relative}")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        for key, entry in data.get("strings", {}).items():
            locs = entry.get("localizations") or {}
            values: dict[str, str] = {}
            for lang in LANGUAGES:
                unit = (locs.get(lang) or {}).get("stringUnit") or {}
                value = unit.get("value")
                if value:
                    values[lang] = value
            if len(values) != len(LANGUAGES):
                continue
            table.setdefault(canon_ios(key), values)
    return table, problems


def load_allowlist() -> dict:
    if ALLOWLIST.exists():
        return json.loads(ALLOWLIST.read_text(encoding="utf-8"))
    return {}


def iter_resw(path: Path):
    tree = ET.parse(path)
    for node in tree.getroot():
        if node.tag != "data":
            continue
        name = node.get("name")
        if not name:
            continue
        value_node = node.find("value")
        text = value_node.text if value_node is not None else ""
        yield name, text or ""


def translate(
    zh: str,
    res_key: str,
    lang: str,
    catalog: dict[str, dict[str, str]],
    allow: dict,
    errors: list[str],
) -> str | None:
    hit = catalog.get(canon_windows(zh))
    if hit:
        return ios_value_to_windows(hit[lang])
    # 无占位符时再试原文（resw 里可能和 iOS 源串逐字相同）
    hit = catalog.get(canon_ios(zh))
    if hit:
        return ios_value_to_windows(hit[lang])
    entry = allow.get(res_key)
    if entry and lang in entry:
        return entry[lang]
    errors.append(
        f"{res_key}: 中文「{zh[:24]}…」不在任何 xcstrings，也不在 {ALLOWLIST.name}"
        if len(zh) > 24
        else f"{res_key}: 中文「{zh}」不在任何 xcstrings，也不在 {ALLOWLIST.name}"
    )
    return None


def generated_file(source: Path, lang: str, catalog, allow, errors: list[str]) -> str:
    lines = [RESW_HEADER]
    for name, zh in iter_resw(source):
        value = translate(zh, name, lang, catalog, allow, errors) or zh
        lines.append(f'  <data name="{name}" xml:space="preserve">')
        lines.append(f"    <value>{escape_xml(value)}</value>")
        lines.append("  </data>")
    lines.append("</root>\n")
    return "\n".join(lines)


def source_resw() -> Path:
    return STRINGS / "zh-Hans" / "Resources.resw"


def outputs() -> tuple[dict[Path, str], list[str]]:
    catalog, problems = load_catalog()
    allow = load_allowlist()
    errors = list(problems)
    result: dict[Path, str] = {}
    source = source_resw()
    if not source.is_file():
        errors.append(f"找不到 {source.relative_to(ROOT)}")
        return result, errors
    for lang in LANGUAGES:
        target = STRINGS / LANG_FOLDER[lang] / "Resources.resw"
        result[target] = generated_file(source, lang, catalog, allow, errors)
    return result, errors


def main() -> int:
    check = "--check" in sys.argv[1:]
    result, errors = outputs()
    if errors:
        print("generate-windows-strings 出错：", file=sys.stderr)
        for line in errors:
            print(f"  {line}", file=sys.stderr)
        return 1
    stale: list[str] = []
    for path, content in result.items():
        rel = path.relative_to(ROOT)
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                stale.append(str(rel))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            print(f"生成 {rel}")
    if check and stale:
        print("Windows 译文和 xcstrings 不一致，跑 python3 scripts/generate-windows-strings.py：")
        for rel in stale:
            print(f"  {rel}")
        return 1
    if check:
        print("generate-windows-strings --check 通过")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
