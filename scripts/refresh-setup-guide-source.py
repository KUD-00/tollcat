#!/usr/bin/env python3
"""刷新或补上 docs/setup-guide-sources.json 里某一家的 stepsFingerprint。

出处文件 App 不读。改 catalog.json 的 fields / steps 之后，核对 sourceURL
还适用，再跑本脚本。不能对所有人一键刷新——那会把「没对过出处」洗成绿。

  python3 scripts/refresh-setup-guide-source.py cloudflare
  python3 scripts/refresh-setup-guide-source.py --url https://example.com/docs/api-keys cloudflare
  python3 scripts/refresh-setup-guide-source.py --bootstrap
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _setup_guide_sources import (  # noqa: E402
    SOURCES_REL,
    credential_setup_urls,
    dump_sources,
    guides_with_steps,
    load_catalog_guides,
    load_sources,
    source_url_errors,
    sources_path,
    steps_fingerprint,
)
from _swift_scan import repo_root  # noqa: E402


def bootstrap(root: Path) -> int:
    path = sources_path(root)
    if path.exists():
        print(
            f"{SOURCES_REL} 已经存在。bootstrap 不会覆盖。"
            "要改某一家用 --url 或只刷 fingerprint。",
            file=sys.stderr,
        )
        return 1
    catalog = guides_with_steps(load_catalog_guides(root))
    urls = credential_setup_urls(root)
    # 不接入、描述里连创建页都没有的家，bootstrap 不能空着。只允许列在这里。
    urls.setdefault(
        "klaviyo",
        "https://developers.klaviyo.com/en/docs/retrieve_api_credentials",
    )
    missing = sorted(key for key in catalog if key not in urls)
    if missing:
        print(
            "这些家有教程却没有 credentialSetupURL，bootstrap 不能编一个出处：",
            file=sys.stderr,
        )
        for key in missing:
            print(f"  {key}", file=sys.stderr)
        return 1
    guides = {
        key: {
            "sourceURL": urls[key],
            "verified": False,
            "stepsFingerprint": steps_fingerprint(guide),
        }
        for key, guide in catalog.items()
    }
    dump_sources(root, {"guides": guides})
    print(f"写了 {SOURCES_REL}（{len(guides)} 家，verified=false，出处暂用 credentialSetupURL）")
    return 0


def refresh(root: Path, keys: list[str], url: str | None) -> int:
    catalog = guides_with_steps(load_catalog_guides(root))
    try:
        data = load_sources(root)
    except FileNotFoundError:
        print(f"找不到 {SOURCES_REL}。先 --bootstrap。", file=sys.stderr)
        return 1
    guides = data.setdefault("guides", {})
    status = 0
    for key in keys:
        if key not in catalog:
            print(f"catalog.json 没有 {key} 的教程", file=sys.stderr)
            status = 1
            continue
        entry = guides.get(key)
        if not isinstance(entry, dict):
            entry = {}
        if url:
            problems = source_url_errors(url, key)
            if problems:
                for line in problems:
                    print(line, file=sys.stderr)
                status = 1
                continue
            entry["sourceURL"] = url
            entry["verified"] = True
        elif not entry.get("sourceURL"):
            print(
                f"{key} 还没有 sourceURL。加上：python3 scripts/refresh-setup-guide-source.py --url https://… {key}",
                file=sys.stderr,
            )
            status = 1
            continue
        entry["stepsFingerprint"] = steps_fingerprint(catalog[key])
        guides[key] = entry
        print(f"{key}: fingerprint {entry['stepsFingerprint']}")
    if status == 0:
        dump_sources(root, data)
    return status


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("keys", nargs="*", help="catalog.json 的 provider id")
    parser.add_argument("--url", help="同时写下 sourceURL，并标 verified=true")
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="仅当文件不存在：用 credentialSetupURL 铺一版，全部 verified=false",
    )
    args = parser.parse_args()
    root = repo_root()
    if args.bootstrap:
        if args.keys or args.url:
            print("--bootstrap 不能和 id / --url 一起用", file=sys.stderr)
            return 2
        return bootstrap(root)
    if not args.keys:
        parser.print_help()
        return 2
    return refresh(root, args.keys, args.url)


if __name__ == "__main__":
    sys.exit(main())
