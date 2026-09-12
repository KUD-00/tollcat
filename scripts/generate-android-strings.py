#!/usr/bin/env python3
"""Android 的 en / ja 文案由 iOS 的 Localizable.xcstrings 生成，不再人肉翻第二遍。

分工：
- `Android/app/src/main/res/values/strings*.xml`（中文）仍然手写——它决定
  Android 用哪些句子、资源名叫什么。
- 每条中文在 iOS 的 String Catalog 里找同文（占位符归一后精确匹配），
  en / ja 取 catalog 的译文，写出 `values-en` / `values-ja`（生成物，提交进仓库）。
- Android 独有的句子（Keystore、平台差异说明……）不在 catalog 里，
  它们的 en / ja 手工维护在 `Android/app/strings-android-only.json`。
- 中文既不在 catalog、也不在 android-only 清单里 → 报错。想新增文案，
  先决定它是"和 iOS 同一句"还是"Android 独有"。

    python3 scripts/generate-android-strings.py            # 写出 values-en / values-ja
    python3 scripts/generate-android-strings.py --check    # 只比对（提交闸）
    python3 scripts/generate-android-strings.py --seed     # 把未匹配项按现有译文补进 android-only 清单
"""

from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "Android/app/src/main/res"
ALLOWLIST = ROOT / "Android/app/strings-android-only.json"
LANGUAGES = ("en", "ja")

XCSTRINGS = (
    "Packages/MeterKit/Sources/MeterFeatures/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterDesign/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterFormat/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterModules/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterPersistence/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterProviders/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterTips/Resources/Localizable.xcstrings",
    "App/Resources/Localizable.xcstrings",
)


# ---------------------------------------------------------------------------
# 占位符归一：两侧都折成 %@ / %lld / %.Nf 再比对


def canon_ios(text: str) -> str:
    text = re.sub(r"%(\d+)\$@", "%@", text)
    text = re.sub(r"%(\d+)\$lld", "%lld", text)
    text = re.sub(r"%(\d+)\$(\.\d+f)", r"%\2", text)
    return text


def canon_android(text: str) -> str:
    text = re.sub(r"%(\d+)\$s", "%@", text)
    text = re.sub(r"%(\d+)\$d", "%lld", text)
    text = re.sub(r"%(\d+)\$(\.\d+f)", r"%\2", text)
    return text


def unescape_android(text: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "\\" and i + 1 < len(text):
            nxt = text[i + 1]
            out.append({"n": "\n", "t": "\t", "'": "'", '"': '"', "\\": "\\"}.get(nxt, nxt))
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def escape_android(text: str) -> str:
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = text.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')
    text = text.replace("\n", "\\n")
    return text


_IOS_SPEC = re.compile(r"%(?:(?P<pos>\d+)\$)?(?P<typ>@|lld|ld|d|\.\d+f)|(?P<pct>%%)")


def ios_value_to_android(value: str) -> str:
    """iOS 译文里的占位符换成 Android 的 java.util.Formatter 位置写法。"""
    counter = 0

    def repl(match: re.Match) -> str:
        nonlocal counter
        if match.group("pct"):
            return "%%"
        pos = match.group("pos")
        if pos is None:
            counter += 1
            pos = str(counter)
        else:
            counter = max(counter, int(pos))
        typ = match.group("typ")
        if typ == "@":
            return f"%{pos}$s"
        if typ in ("lld", "ld", "d"):
            return f"%{pos}$d"
        return f"%{pos}${typ}"

    return _IOS_SPEC.sub(repl, value)


# ---------------------------------------------------------------------------


def load_catalog() -> tuple[dict[str, dict[str, str]], list[str]]:
    """canon(中文源串) → {en, ja}。先出现的模块优先（顺序 = XCSTRINGS）。"""
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


def string_files() -> list[Path]:
    return sorted((RES / "values").glob("strings*.xml"))


def load_allowlist() -> dict:
    if ALLOWLIST.exists():
        return json.loads(ALLOWLIST.read_text(encoding="utf-8"))
    return {}


def iter_entries(path: Path):
    """(kind, name, translatable, zh 文本或 item 列表)。"""
    tree = ET.parse(path)
    for node in tree.getroot():
        translatable = node.get("translatable", "true") != "false"
        if node.tag == "string":
            yield "string", node.get("name"), translatable, unescape_android(node.text or "")
        elif node.tag == "string-array":
            items = [unescape_android(item.text or "") for item in node.findall("item")]
            yield "array", node.get("name"), translatable, items


def translate(
    zh: str,
    res_key: str,
    lang: str,
    catalog: dict[str, dict[str, str]],
    allow: dict,
    errors: list[str],
) -> str | None:
    hit = catalog.get(canon_android(zh))
    if hit:
        return ios_value_to_android(hit[lang])
    entry = allow.get(res_key)
    if entry and lang in entry:
        return entry[lang]
    errors.append(
        f"{res_key}: 中文「{zh[:24]}…」不在任何 xcstrings，也不在 {ALLOWLIST.name}"
        if len(zh) > 24
        else f"{res_key}: 中文「{zh}」不在任何 xcstrings，也不在 {ALLOWLIST.name}"
    )
    return None


def generated_file(path: Path, lang: str, catalog, allow, errors: list[str]) -> str:
    lines = [
        "<!-- GENERATED — 由 scripts/generate-android-strings.py 生成，不要手改。",
        "     和 iOS 同文的句子：改对应模块的 Localizable.xcstrings；",
        "     Android 独有的句子：改 Android/app/strings-android-only.json。 -->",
        "<resources>",
    ]
    for kind, name, translatable, payload in iter_entries(path):
        if not translatable:
            # 不可翻译的资源留在 values/ 兜底，locale 目录不用重复。
            continue
        if kind == "string":
            value = translate(payload, name, lang, catalog, allow, errors) or payload
            lines.append(f'    <string name="{name}">{escape_android(value)}</string>')
        else:
            lines.append(f'    <string-array name="{name}">')
            for index, zh in enumerate(payload):
                value = translate(zh, f"{name}[{index}]", lang, catalog, allow, errors) or zh
                lines.append(f"        <item>{escape_android(value)}</item>")
            lines.append("    </string-array>")
    lines.append("</resources>")
    return "\n".join(lines) + "\n"


def outputs() -> tuple[dict[Path, str], list[str]]:
    catalog, problems = load_catalog()
    allow = load_allowlist()
    errors = list(problems)
    result: dict[Path, str] = {}
    for path in string_files():
        for lang in LANGUAGES:
            target = RES / f"values-{lang}" / path.name
            result[target] = generated_file(path, lang, catalog, allow, errors)
    return result, errors


def seed_allowlist() -> None:
    """把当前未匹配的资源按现有 values-en/ja 译文补进 android-only 清单。"""
    catalog, _ = load_catalog()
    allow = load_allowlist()

    existing: dict[str, dict[str, dict[str, str]]] = {}
    for lang in LANGUAGES:
        for path in sorted((RES / f"values-{lang}").glob("strings*.xml")):
            for kind, name, _, payload in iter_entries(path):
                if kind == "string":
                    existing.setdefault(name, {})[lang] = payload
                else:
                    for index, item in enumerate(payload):
                        existing.setdefault(f"{name}[{index}]", {})[lang] = item

    added = 0
    for path in string_files():
        for kind, name, translatable, payload in iter_entries(path):
            if not translatable:
                continue
            entries = [(name, payload)] if kind == "string" else [
                (f"{name}[{i}]", item) for i, item in enumerate(payload)
            ]
            for res_key, zh in entries:
                if canon_android(zh) in catalog or res_key in allow:
                    continue
                translations = existing.get(res_key)
                if not translations or len(translations) != len(LANGUAGES):
                    print(f"  跳过 {res_key}：现有译文不全，需要手补")
                    continue
                allow[res_key] = {
                    "zh": zh,
                    "en": translations["en"],
                    "ja": translations["ja"],
                }
                added += 1
    ALLOWLIST.write_text(
        json.dumps(allow, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"android-only 清单：+{added} 条 → {ALLOWLIST.relative_to(ROOT)}")


def main() -> int:
    if "--seed" in sys.argv[1:]:
        seed_allowlist()
        return 0
    check = "--check" in sys.argv[1:]
    result, errors = outputs()
    if errors:
        print("generate-android-strings 出错：", file=sys.stderr)
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
        print("Android 译文和 xcstrings 不一致，跑 python3 scripts/generate-android-strings.py：")
        for rel in stale:
            print(f"  {rel}")
        return 1
    if check:
        print("generate-android-strings --check 通过")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
