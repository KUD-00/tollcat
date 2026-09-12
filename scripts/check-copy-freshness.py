#!/usr/bin/env python3
"""翻译新鲜度闸：中文改了，同一单元的 en / ja 必须在同一次改动里跟着动。

对比对象默认是 HEAD（pre-commit 场景：工作树 vs 上一个提交）；CI 可用
`--against origin/main` 对比整个分支。判据：

- 站点 `site/src/i18n/index.ts`：三语 Copy 树按相同 JSON 路径逐叶子配对。
- `catalog.json`：每个中文字段与它的 en / ja overlay 配对。
- `strings-android-only.json` / `strings-windows-only.json`：每条的 zh / en / ja 配对。
- `shared/changelog.json`：每条按 `items[].id` 配对，不按下标——改序不会误报。
- 只在「zh 变了而 en（或 ja）与基准逐字节相同」时红——纯润色译文不拦，
  新增/删除单元不拦（存在性由 i18n coverage 与 CatalogLocalizationTests 管）。
- xcstrings 不进这道闸：那边改中文就是改 key，en / ja 条目物理上必须重挂。

红了怎么修：在同一次改动里把该单元的 en / ja 一起更新。中文改动确实不影响
译文时（错别字、标点），用 `--allow <单元id>` 放行这一次（id 在失败信息里），
并在提交说明里写明译文核对过——放行是签名，不是后门。
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SITE_I18N = "site/src/i18n/index.ts"
CATALOG = "Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json"
ANDROID_ONLY = "Android/app/strings-android-only.json"
WINDOWS_ONLY = "Windows/app/strings-windows-only.json"
CHANGELOG = "shared/changelog.json"


def git_show(rev: str, path: str) -> str | None:
    proc = subprocess.run(
        ["git", "show", f"{rev}:{path}"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    return proc.stdout if proc.returncode == 0 else None


# ---- 站点 i18n：esbuild 求值成三棵树，按路径抽字符串叶子 -------------------

def site_units(source: str) -> dict[str, tuple[str, str, str]] | None:
    with tempfile.NamedTemporaryFile(
        "w",
        dir=ROOT / "site/src/i18n",
        prefix=".freshness-",
        suffix=".ts",
        delete=False,
        encoding="utf-8",
    ) as handle:
        handle.write(source)
        temp = Path(handle.name)
    try:
        proc = subprocess.run(
            ["node", str(ROOT / "scripts/dump-site-copy.cjs"), str(temp)],
            capture_output=True,
            text=True,
        )
    finally:
        temp.unlink(missing_ok=True)
    if proc.returncode != 0:
        print(f"check-copy-freshness: 站点 i18n 求值失败：{proc.stderr.strip()[:200]}", file=sys.stderr)
        return None
    trees = json.loads(proc.stdout)

    def leaves(node, path, out):
        if isinstance(node, dict):
            for k, v in node.items():
                leaves(v, f"{path}.{k}", out)
        elif isinstance(node, list):
            for i, v in enumerate(node):
                leaves(v, f"{path}[{i}]", out)
        elif isinstance(node, str):
            out[path] = node

    zh: dict[str, str] = {}
    en: dict[str, str] = {}
    ja: dict[str, str] = {}
    leaves(trees["zh"], "site", zh)
    leaves(trees["en"], "site", en)
    leaves(trees["ja"], "site", ja)
    return {p: (zh[p], en.get(p, ""), ja.get(p, "")) for p in zh}


# ---- catalog.json：中文字段 + en/ja overlay --------------------------------

def catalog_units(source: str) -> dict[str, tuple[str, str, str]]:
    data = json.loads(source)
    units: dict[str, tuple[str, str, str]] = {}

    def pair(node: dict, key: str, at: str) -> None:
        base = node.get(key)
        if not isinstance(base, str) or not base.strip():
            return
        en = ((node.get("en") or {}).get(key)) or ""
        ja = ((node.get("ja") or {}).get(key)) or ""
        units[at] = (base, en, ja)

    for gid, g in (data.get("guides") or {}).items():
        pair(g, "summary", f"catalog.{gid}.summary")
        pair(g, "verifyHint", f"catalog.{gid}.verifyHint")
        for pi, part in enumerate(g.get("parts") or []):
            for fi, f in enumerate(part.get("fields") or []):
                at = f"catalog.{gid}.p{pi}.f{fi}"
                pair(f, "label", f"{at}.label")
                pair(f, "hint", f"{at}.hint")
                if isinstance(f.get("validation"), dict):
                    pair(f["validation"], "message", f"{at}.validation")
            for si, s in enumerate(part.get("steps") or []):
                pair(s, "text", f"catalog.{gid}.p{pi}.s{si}")
        for ti, t in enumerate(g.get("troubleshooting") or []):
            pair(t, "explanation", f"catalog.{gid}.t{ti}.explanation")
            pair(t, "nextStep", f"catalog.{gid}.t{ti}.nextStep")
    for i, plan in enumerate(data.get("plans") or []):
        pair(plan, "name", f"catalog.plans[{i}]")
    for i, notice in enumerate(data.get("notices") or []):
        pair(notice, "message", f"catalog.notices[{i}]")
    return units


# ---- strings-android-only.json：每条 zh/en/ja -----------------------------

def android_units(source: str) -> dict[str, tuple[str, str, str]]:
    data = json.loads(source)
    units: dict[str, tuple[str, str, str]] = {}
    items = data.get("strings", data) if isinstance(data, dict) else data
    if isinstance(items, dict):
        rows = items.items()
    elif isinstance(items, list):
        rows = ((row.get("name") or f"[{i}]", row) for i, row in enumerate(items))
    else:
        return units
    for name, row in rows:
        if not isinstance(row, dict):
            continue
        zh = row.get("zh")
        if isinstance(zh, str):
            units[f"android-only.{name}"] = (zh, row.get("en") or "", row.get("ja") or "")
    return units


def windows_units(source: str) -> dict[str, tuple[str, str, str]]:
    units = android_units(source)
    return {k.replace("android-only.", "windows-only.", 1): v for k, v in units.items()}


# ---- changelog.json：每条按 items[].id 配对（不按下标，改序不会误报） -------

def changelog_units(source: str) -> dict[str, tuple[str, str, str]]:
    data = json.loads(source)
    units: dict[str, tuple[str, str, str]] = {}

    def pair(node: dict, key: str, at: str) -> None:
        base = node.get(key)
        if not isinstance(base, str) or not base.strip():
            return
        units[at] = (base, (node.get("en") or {}).get(key) or "", (node.get("ja") or {}).get(key) or "")

    for entry in data.get("entries") or []:
        version = entry.get("version") or "?"
        pair(entry, "title", f"changelog.{version}.title")
        for item in entry.get("items") or []:
            ident = item.get("id") or "?"
            pair(item, "title", f"changelog.{version}.{ident}.title")
            pair(item, "body", f"changelog.{version}.{ident}.body")
    return units


def compare(
    now: dict[str, tuple[str, str, str]],
    base: dict[str, tuple[str, str, str]],
    allow: set[str],
    errors: list[str],
) -> None:
    for unit, (zh_now, en_now, ja_now) in now.items():
        if unit in allow or unit not in base:
            continue
        zh_old, en_old, ja_old = base[unit]
        if zh_now == zh_old:
            continue
        stale = [lang for lang, new, old in (("en", en_now, en_old), ("ja", ja_now, ja_old)) if new == old]
        if stale:
            errors.append(f"{unit} 的中文改了，{'/'.join(stale)} 没跟上：{zh_old[:26]} → {zh_now[:26]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--against", default="HEAD", help="对比基准（默认 HEAD）")
    parser.add_argument("--allow", action="append", default=[], help="放行的单元 id，可多次")
    args = parser.parse_args()
    allow = set(args.allow)
    errors: list[str] = []

    for path, extract in (
        (SITE_I18N, site_units),
        (CATALOG, catalog_units),
        (ANDROID_ONLY, android_units),
        (WINDOWS_ONLY, windows_units),
        (CHANGELOG, changelog_units),
    ):
        old = git_show(args.against, path)
        if old is None:
            continue  # 基准里还没有这个文件
        now_text = (ROOT / path).read_text(encoding="utf-8")
        if now_text == old:
            continue
        now_units = extract(now_text)
        old_units = extract(old)
        if now_units is None or old_units is None:
            return 1
        compare(now_units, old_units, allow, errors)

    if errors:
        print(f"check-copy-freshness: {len(errors)} 个单元中文动了、译文没动：")
        for line in errors[:20]:
            print("  " + line)
        if len(errors) > 20:
            print(f"  … 还有 {len(errors) - 20} 个")
        print("  修法：同一次改动里把这些单元的 en/ja 一起更新。译文核对过确实不用变的，")
        print("  用 --allow <单元id> 放行这一次，并在提交说明里写明。")
        return 1
    print("check-copy-freshness: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
