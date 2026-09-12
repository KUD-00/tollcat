#!/usr/bin/env python3
"""把各 worktree 里指定 key 的教程 / 出处合回当前树。

不跑 git merge。只覆盖 catalog.json 的 guides[key] 和
docs/setup-guide-sources.json 的 guides[key]。Swift URL 需人工看 diff。
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _setup_guide_sources import dump_sources, load_sources, steps_fingerprint  # noqa: E402
from _swift_scan import repo_root  # noqa: E402

CATALOG = Path("Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--from",
        dest="sources",
        action="append",
        required=True,
        metavar="WORKTREE:key,key,…",
        help="worktree 路径和它负责的 catalog key，可重复",
    )
    args = parser.parse_args()
    root = repo_root()
    catalog_path = root / CATALOG
    catalog = load_json(catalog_path)
    sources = load_sources(root)
    src_guides = sources.setdefault("guides", {})

    copied = 0
    missing = []
    for item in args.sources:
        if ":" not in item:
            print(f"坏参数 {item}，要 WORKTREE:key,key", file=sys.stderr)
            return 2
        tree, keys_blob = item.split(":", 1)
        tree_path = Path(tree)
        child_catalog = load_json(tree_path / CATALOG)
        child_sources_path = tree_path / "docs/setup-guide-sources.json"
        child_sources = (
            json.loads(child_sources_path.read_text(encoding="utf-8"))
            if child_sources_path.is_file()
            else {"guides": {}}
        )
        child_src_guides = child_sources.get("guides") or {}
        child_guides = child_catalog.get("guides") or {}
        for key in [k for k in keys_blob.split(",") if k]:
            if key not in child_guides:
                missing.append(f"{tree_path.name}:{key} 子树 catalog 没有")
                continue
            catalog["guides"][key] = child_guides[key]
            if key in child_src_guides:
                entry = dict(child_src_guides[key])
                entry["stepsFingerprint"] = steps_fingerprint(child_guides[key])
                src_guides[key] = entry
            copied += 1

    catalog_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    dump_sources(root, sources)
    print(f"合入 {copied} 家教程")
    for line in missing:
        print(line, file=sys.stderr)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
