#!/usr/bin/env python3
"""对外文案的词表闸。判据来自 BRAND.md 术语表：
- 日文里不许出现中文漏词和已废弃术语（資格情報→認証情報、読数/受信箱→検針ポスト、
  送信キー/投稿キー→投函キー、留言→メッセージ、文案→文言、数ヶ月→数か月）。
- 中文用户可见文案不许出现仓库黑话（取数/落盘/利用指南/API 钥匙），
  也不许出现 AI 腔「合成一个数（字）」「聚合成一个数（字）」（BRAND.md 第三节反例）。
  只扫 catalog.json 和站点 i18n——xcstrings 里有开发构建豁免区，机器分不出来，
  那边靠 review；catalog 和站点没有豁免区。
- 英文散文不许用直引号 '（弯引号 ’ 是标准），catalog 的 copyable 代码除外。
- 更新说明（shared/changelog.json）同样是对外文案，按 en / ja 键分语言扫。
  站点那份 changelog.ts 是它的生成物，不重复扫。

改词表：先改 BRAND.md，再改这里。绕过闸等于让三种语言重新漂移。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

JA_BANNED = ["資格情報", "読数", "受信箱", "留言", "文案", "送信キー", "投稿キー", "数ヶ月", "投递"]
ZH_BANNED = ["取数", "落盘", "利用指南", "API 钥匙", "合成一个数", "聚合成一个数"]
EN_BANNED = ["delivery key", "Delivery key"]
APOS = re.compile(r"\w'\w")

violations: list[str] = []


def flag(where: str, rule: str, text: str) -> None:
    violations.append(f"{where}: [{rule}] {text[:80]}")


# ---- catalog.json：全部字段都是用户可见 ----------------------------------

def check_catalog() -> None:
    path = ROOT / "Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json"
    data = json.loads(path.read_text(encoding="utf-8"))

    def walk(node, path_parts, in_en, in_ja, in_copyable):
        if isinstance(node, dict):
            for k, v in node.items():
                walk(v, path_parts + [k], in_en or k == "en", in_ja or k == "ja", in_copyable or k == "copyable")
        elif isinstance(node, list):
            for i, v in enumerate(node):
                walk(v, path_parts + [str(i)], in_en, in_ja, in_copyable)
        elif isinstance(node, str):
            where = "catalog.json:" + ".".join(path_parts[:5])
            if in_ja:
                for w in JA_BANNED:
                    if w in node:
                        flag(where, f"ja禁词 {w}", node)
            elif in_en:
                if not in_copyable and APOS.search(node):
                    flag(where, "en直引号", node)
                for w in EN_BANNED:
                    if w in node:
                        flag(where, f"en禁词 {w}", node)
            else:
                for w in ZH_BANNED:
                    if w in node:
                        flag(where, f"zh黑话 {w}", node)

    walk(data, [], False, False, False)


# ---- xcstrings：ja / en 译文列（zh 源串有开发豁免区，不在此扫） -----------

def check_xcstrings() -> None:
    for path in sorted(ROOT.glob("Packages/MeterKit/Sources/*/Resources/Localizable.xcstrings")) + [
        ROOT / "App/Resources/Localizable.xcstrings"
    ]:
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        rel = path.relative_to(ROOT)
        for key, entry in data.get("strings", {}).items():
            locs = entry.get("localizations") or {}
            ja = ((locs.get("ja") or {}).get("stringUnit") or {}).get("value", "")
            en = ((locs.get("en") or {}).get("stringUnit") or {}).get("value", "")
            for w in JA_BANNED:
                if w in ja:
                    flag(f"{rel}:{key[:24]}", f"ja禁词 {w}", ja)
            if APOS.search(en):
                flag(f"{rel}:{key[:24]}", "en直引号", en)
            for w in EN_BANNED:
                if w in en:
                    flag(f"{rel}:{key[:24]}", f"en禁词 {w}", en)


# ---- Android 独有清单 + 站点 i18n ----------------------------------------

def check_android_only() -> None:
    path = ROOT / "Android/app/strings-android-only.json"
    text = path.read_text(encoding="utf-8")
    for i, line in enumerate(text.splitlines(), 1):
        if '"ja"' in line:
            for w in JA_BANNED:
                if w in line:
                    flag(f"strings-android-only.json:{i}", f"ja禁词 {w}", line.strip())


KANA = re.compile(r"[ぁ-んァ-ヶ]")


def check_site_file(rel: str) -> None:
    # 三语混在一个文件里：含假名的行按日文规则，其余按中文规则。
    # 「留言」「文案」是合法中文，只有漏进日文句子里才算事故。
    path = ROOT / rel
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if KANA.search(line):
            for w in JA_BANNED:
                if w in line:
                    flag(f"{rel}:{i}", f"ja禁词 {w}", line.strip())
        else:
            for w in ZH_BANNED:
                if w in line:
                    flag(f"{rel}:{i}", f"zh黑话 {w}", line.strip())


def check_site() -> None:
    check_site_file("site/src/i18n/index.ts")


# ---- changelog.json：结构和 catalog 一样，按 en / ja 键分语言 --------------

def check_changelog() -> None:
    """更新说明是对外文案。权威在 shared/changelog.json，站点那份是生成物，

    所以扫权威——而且这里能按 `en` / `ja` 键准确分语言，不用站点那套假名启发式。
    """
    path = ROOT / "shared/changelog.json"
    data = json.loads(path.read_text(encoding="utf-8"))

    def walk(node, parts, in_en, in_ja):
        if isinstance(node, dict):
            for k, v in node.items():
                if k == "$comment":
                    continue  # 注释是给写代码的人看的，仓库黑话在那里是对的
                walk(v, parts + [k], in_en or k == "en", in_ja or k == "ja")
        elif isinstance(node, list):
            for i, v in enumerate(node):
                walk(v, parts + [str(i)], in_en, in_ja)
        elif isinstance(node, str):
            where = "changelog.json:" + ".".join(parts[:4])
            if in_ja:
                for w in JA_BANNED:
                    if w in node:
                        flag(where, f"ja禁词 {w}", node)
            elif in_en:
                if APOS.search(node):
                    flag(where, "en直引号", node)
                for w in EN_BANNED:
                    if w in node:
                        flag(where, f"en禁词 {w}", node)
            else:
                for w in ZH_BANNED:
                    if w in node:
                        flag(where, f"zh黑话 {w}", node)

    walk(data, [], False, False)


def main() -> int:
    check_catalog()
    check_xcstrings()
    check_android_only()
    check_site()
    check_changelog()
    if violations:
        print(f"check-copy-terms: {len(violations)} 处违反 BRAND.md 词表：")
        for v in violations[:40]:
            print("  " + v)
        if len(violations) > 40:
            print(f"  … 还有 {len(violations) - 40} 处")
        return 1
    print("check-copy-terms: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
