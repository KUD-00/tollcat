#!/usr/bin/env python3
"""跨端跟进：按 Apple 目录点头。

盖戳记的是「这个目录自上次点头之后改过，某跟随端的人看过」。不发明能力，
不维护跨语言依赖。预提交只核地图合法性，过期不红。过期列表给人看、给
release-status.sh 加一行「未点头」。

    python3 scripts/check-follow-up.py check
    python3 scripts/check-follow-up.py due [--platform android]
    python3 scripts/check-follow-up.py show dashboard [--platform android]
    python3 scripts/check-follow-up.py stamp dashboard android --decision reviewed --note "…"
    python3 scripts/check-follow-up.py --self-test
"""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from datetime import date
from fnmatch import fnmatch
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _swift_scan import mask_comments, rel, repo_root  # noqa: E402

GENERATED_MARK = "GENERATED"
PLATFORMS = ("android", "windows", "cli")
DECISIONS = ("reviewed", "n/a", "deferred")
MAP_PATH = Path("scripts/follow-up.json")


def map_file(root: Path) -> Path:
    return root / MAP_PATH


def load_map(root: Path) -> dict:
    path = map_file(root)
    if not path.is_file():
        raise SystemExit(f"check-follow-up: 找不到 {MAP_PATH}")
    return json.loads(path.read_text(encoding="utf-8"))


def dump_map(root: Path, data: dict) -> None:
    watches = sorted(data.get("watches") or [], key=lambda item: item["id"])
    excludes = sorted(data.get("excludes") or [])
    stamps: dict[str, dict] = {}
    for platform in PLATFORMS:
        per = (data.get("stamps") or {}).get(platform) or {}
        stamps[platform] = {key: per[key] for key in sorted(per)}
    payload = {"excludes": excludes, "stamps": stamps, "watches": watches}
    text = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    map_file(root).write_text(text, encoding="utf-8")


def watch_by_id(data: dict, watch_id: str) -> dict | None:
    for watch in data.get("watches") or []:
        if watch.get("id") == watch_id:
            return watch
    return None


def is_generated(path: Path) -> bool:
    try:
        head = path.read_text(encoding="utf-8")[:2048]
    except OSError:
        return False
    for line in head.splitlines()[:8]:
        stripped = line.strip()
        if not stripped:
            continue
        return GENERATED_MARK in stripped
    return False


def excluded_name(name: str, patterns: list[str]) -> bool:
    return any(fnmatch(name, pattern) for pattern in patterns)


def listed_files(root: Path, watch: dict, excludes: list[str]) -> list[Path]:
    apple = root / watch["apple"]
    if not apple.exists():
        return []
    depth = watch.get("depth", "tree")
    if depth == "files":
        candidates = [path for path in apple.iterdir() if path.is_file()]
    else:
        candidates = [path for path in apple.rglob("*") if path.is_file()]
    out: list[Path] = []
    for path in sorted(candidates):
        if path.suffix != ".swift":
            continue
        if "Resources" in path.parts:
            continue
        if excluded_name(path.name, excludes):
            continue
        if is_generated(path):
            continue
        out.append(path)
    return out


def canonical_text(raw: str) -> str:
    masked = mask_comments(raw)
    lines = [line.rstrip() for line in masked.splitlines()]
    lines = [line for line in lines if line.strip() != ""]
    return "\n".join(lines) + ("\n" if lines else "")


def watch_hash(root: Path, files: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in files:
        digest.update(rel(root, path).encode("utf-8"))
        digest.update(b"\0")
        digest.update(canonical_text(path.read_text(encoding="utf-8")).encode("utf-8"))
        digest.update(b"\0")
    return digest.hexdigest()


def git_head(root: Path) -> str:
    proc = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root,
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip() if proc.returncode == 0 else ""


def git_diff(root: Path, rev: str, files: list[Path]) -> str:
    if not rev or not files:
        return ""
    args = ["git", "diff", rev, "--"] + [rel(root, path) for path in files]
    proc = subprocess.run(args, cwd=root, capture_output=True, text=True)
    return proc.stdout


def stamp_of(data: dict, platform: str, watch_id: str) -> dict | None:
    return ((data.get("stamps") or {}).get(platform) or {}).get(watch_id)


def is_due(stamp: dict | None, current: str) -> bool:
    if stamp is None:
        return True
    if stamp.get("decision") == "n/a":
        return False
    if stamp.get("decision") == "deferred":
        return True
    return stamp.get("hash") != current


def map_errors(root: Path, data: dict) -> list[str]:
    errors: list[str] = []
    watches = data.get("watches")
    if not isinstance(watches, list) or not watches:
        errors.append("watches 必须是非空数组")
        return errors
    ids: list[str] = []
    for watch in watches:
        watch_id = watch.get("id")
        apple = watch.get("apple")
        depth = watch.get("depth")
        if not isinstance(watch_id, str) or not watch_id:
            errors.append("有一条 watch 缺 id")
            continue
        ids.append(watch_id)
        if not isinstance(apple, str) or not apple:
            errors.append(f"{watch_id}: 缺 apple 路径")
            continue
        path = root / apple
        if not path.exists():
            errors.append(f"{watch_id}: {apple} 不存在")
        elif depth == "files" and not path.is_dir():
            errors.append(f"{watch_id}: {apple} 必须是目录")
        elif depth == "tree" and not path.is_dir():
            errors.append(f"{watch_id}: {apple} 必须是目录")
        if depth not in {"tree", "files"}:
            errors.append(f"{watch_id}: depth 必须是 tree 或 files")
        files = listed_files(root, watch, data.get("excludes") or [])
        if path.is_dir() and not files:
            errors.append(f"{watch_id}: 排除之后没有可哈希的 .swift")
    if len(ids) != len(set(ids)):
        errors.append("watch id 重复")
    known = set(ids)
    stamps = data.get("stamps") or {}
    if not isinstance(stamps, dict):
        errors.append("stamps 必须是对象")
        return errors
    for platform, per in stamps.items():
        if platform not in PLATFORMS:
            errors.append(f"未知跟随端 {platform}")
            continue
        if not isinstance(per, dict):
            errors.append(f"stamps.{platform} 必须是对象")
            continue
        for watch_id, stamp in per.items():
            if watch_id not in known:
                errors.append(f"stamps.{platform}.{watch_id} 没有对应 watch")
            if not isinstance(stamp, dict):
                errors.append(f"stamps.{platform}.{watch_id} 必须是对象")
                continue
            if stamp.get("decision") not in DECISIONS:
                errors.append(f"stamps.{platform}.{watch_id}: decision 必须是 {' / '.join(DECISIONS)}")
    for platform in PLATFORMS:
        if platform not in stamps:
            errors.append(f"stamps 缺 {platform}")
    excludes = data.get("excludes")
    if excludes is not None and not isinstance(excludes, list):
        errors.append("excludes 必须是数组")
    return errors


def due_payload(root: Path, data: dict) -> dict[str, dict]:
    excludes = data.get("excludes") or []
    hashes: dict[str, str] = {}
    for watch in data["watches"]:
        files = listed_files(root, watch, excludes)
        hashes[watch["id"]] = watch_hash(root, files)
    out: dict[str, dict] = {}
    for platform in PLATFORMS:
        unacked: list[str] = []
        na: list[str] = []
        deferred: list[str] = []
        for watch in data["watches"]:
            watch_id = watch["id"]
            stamp = stamp_of(data, platform, watch_id)
            if stamp and stamp.get("decision") == "n/a":
                na.append(watch_id)
                continue
            if stamp and stamp.get("decision") == "deferred":
                deferred.append(watch_id)
                unacked.append(watch_id)
                continue
            if is_due(stamp, hashes[watch_id]):
                unacked.append(watch_id)
        out[platform] = {"unacked": unacked, "na": na, "deferred": deferred}
    return out


def cmd_check(root: Path, data: dict) -> int:
    errors = map_errors(root, data)
    if errors:
        print(f"check-follow-up: {len(errors)} 处地图不合法:", file=sys.stderr)
        for line in errors:
            print(f"  {line}", file=sys.stderr)
        return 1
    print("check-follow-up: ok")
    return 0


def cmd_due(root: Path, data: dict, platform: str | None, as_json: bool) -> int:
    errors = map_errors(root, data)
    if errors:
        return cmd_check(root, data)
    payload = due_payload(root, data)
    if as_json:
        dump = payload if platform is None else {platform: payload[platform]}
        json.dump(dump, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return 0
    platforms = (platform,) if platform else PLATFORMS
    for name in platforms:
        unacked = payload[name]["unacked"]
        na = payload[name]["na"]
        if unacked:
            print(f"{name:8} 未点头  {', '.join(unacked)}")
        else:
            print(f"{name:8} 已点头")
        if na:
            print(f"         n/a     {', '.join(na)}")
    # 过期是读数，不是失败。预提交不跑 due。release-status 用 --json。
    return 0


def cmd_show(root: Path, data: dict, watch_id: str, platform: str | None) -> int:
    errors = map_errors(root, data)
    if errors:
        return cmd_check(root, data)
    watch = watch_by_id(data, watch_id)
    if watch is None:
        print(f"check-follow-up: 没有 watch {watch_id}", file=sys.stderr)
        return 1
    files = listed_files(root, watch, data.get("excludes") or [])
    current = watch_hash(root, files)
    print(f"watch   {watch_id}")
    print(f"apple   {watch['apple']}  ({watch.get('depth', 'tree')})")
    print(f"hash    {current}")
    print(f"files   {len(files)}")
    for path in files:
        print(f"  {rel(root, path)}")
    targets = (platform,) if platform else PLATFORMS
    for name in targets:
        stamp = stamp_of(data, name, watch_id)
        hints = (watch.get("hints") or {}).get(name) or []
        print(f"\n{name}:")
        if hints:
            for hint in hints:
                print(f"  看  {hint}")
        else:
            print("  看  （无提示路径，闸不核这个）")
        if stamp is None:
            print("  戳  无（未点头；下面不是 diff，是当前纳入哈希的文件）")
            continue
        print(
            f"  戳  {stamp.get('decision')}  {stamp.get('date', '')}  "
            f"hash={stamp.get('hash') or '—'}  {stamp.get('note', '')}"
        )
        if stamp.get("decision") == "n/a":
            continue
        if stamp.get("hash") == current:
            print("  哈希未变")
            continue
        print("  哈希已过期")
        rev = stamp.get("gitRev") or ""
        if rev:
            diff = git_diff(root, rev, files)
            if diff.strip():
                print(f"  git diff {rev[:12]} -- <watch files>")
                print(diff.rstrip())
            else:
                print(f"  git diff {rev[:12]} 无输出（改动可能已被抹成注释）")
    return 0


def cmd_stamp(
    root: Path,
    data: dict,
    watch_id: str,
    platform: str,
    decision: str,
    note: str,
) -> int:
    errors = map_errors(root, data)
    if errors:
        return cmd_check(root, data)
    if platform not in PLATFORMS:
        print(f"check-follow-up: 跟随端必须是 {' / '.join(PLATFORMS)}", file=sys.stderr)
        return 1
    watch = watch_by_id(data, watch_id)
    if watch is None:
        print(f"check-follow-up: 没有 watch {watch_id}", file=sys.stderr)
        return 1
    if decision not in DECISIONS:
        print(f"check-follow-up: decision 必须是 {' / '.join(DECISIONS)}", file=sys.stderr)
        return 1
    if not note.strip():
        print("check-follow-up: --note 必填", file=sys.stderr)
        return 1
    files = listed_files(root, watch, data.get("excludes") or [])
    current = watch_hash(root, files)
    entry = {
        "date": date.today().isoformat(),
        "decision": decision,
        "gitRev": git_head(root),
        "hash": "" if decision == "n/a" else current,
        "note": note.strip(),
    }
    data.setdefault("stamps", {}).setdefault(platform, {})[watch_id] = entry
    dump_map(root, data)
    print(f"stamped {platform} {watch_id} {decision} {entry['hash'] or '—'}")
    return 0


class FollowUpSelfTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        apple = self.root / "AppleDir"
        apple.mkdir()
        (apple / "Visible.swift").write_text("let a = 1\n", encoding="utf-8")
        (apple / "PadOnly.swift").write_text("let pad = 1\n", encoding="utf-8")
        (apple / "Generated.swift").write_text(
            f"// {GENERATED_MARK} — 测试\nlet g = 1\n", encoding="utf-8"
        )
        payload = {
            "excludes": ["*Pad*"],
            "stamps": {name: {} for name in PLATFORMS},
            "watches": [
                {
                    "id": "demo",
                    "apple": "AppleDir",
                    "depth": "tree",
                    "hints": {"android": [], "windows": []},
                }
            ],
        }
        (self.root / "scripts").mkdir()
        (self.root / MAP_PATH).write_text(
            json.dumps(payload, indent=2) + "\n", encoding="utf-8"
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_generated_and_pad_excluded(self) -> None:
        data = load_map(self.root)
        files = listed_files(self.root, data["watches"][0], data["excludes"])
        names = [path.name for path in files]
        self.assertEqual(names, ["Visible.swift"])

    def test_comment_does_not_change_hash(self) -> None:
        data = load_map(self.root)
        watch = data["watches"][0]
        before = watch_hash(self.root, listed_files(self.root, watch, data["excludes"]))
        visible = self.root / "AppleDir" / "Visible.swift"
        visible.write_text("let a = 1\n// 计算总和\n", encoding="utf-8")
        after = watch_hash(self.root, listed_files(self.root, watch, data["excludes"]))
        self.assertEqual(before, after)

    def test_due_then_stamp_then_clear(self) -> None:
        data = load_map(self.root)
        payload = due_payload(self.root, data)
        self.assertEqual(payload["android"]["unacked"], ["demo"])
        code = cmd_stamp(self.root, data, "demo", "android", "reviewed", "看过")
        self.assertEqual(code, 0)
        data = load_map(self.root)
        payload = due_payload(self.root, data)
        self.assertEqual(payload["android"]["unacked"], [])
        (self.root / "AppleDir" / "Visible.swift").write_text(
            'let a = 1\nlet copy = "改了"\n', encoding="utf-8"
        )
        payload = due_payload(self.root, data)
        self.assertEqual(payload["android"]["unacked"], ["demo"])

    def test_na_never_due(self) -> None:
        data = load_map(self.root)
        cmd_stamp(self.root, data, "demo", "cli", "n/a", "无 GUI")
        data = load_map(self.root)
        (self.root / "AppleDir" / "Visible.swift").write_text("let a = 2\n", encoding="utf-8")
        payload = due_payload(self.root, data)
        self.assertEqual(payload["cli"]["unacked"], [])
        self.assertEqual(payload["cli"]["na"], ["demo"])

    def test_check_rejects_missing_watch_path(self) -> None:
        data = load_map(self.root)
        data["watches"][0]["apple"] = "NoSuch"
        errors = map_errors(self.root, data)
        self.assertTrue(any("不存在" in item for item in errors))


def main() -> int:
    parser = argparse.ArgumentParser(description="按 Apple 目录给跟随端点头")
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="跑内置 unittest（不读仓库地图）",
    )
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("check", help="地图合法性。过期不红。")

    due = sub.add_parser("due", help="列出未点头的目录")
    due.add_argument("--platform", choices=PLATFORMS)
    due.add_argument("--json", action="store_true")

    show = sub.add_parser("show", help="一个目录纳入哈希的文件和戳")
    show.add_argument("id")
    show.add_argument("--platform", choices=PLATFORMS)

    stamp = sub.add_parser("stamp", help="给一个目录盖戳")
    stamp.add_argument("id")
    stamp.add_argument("platform", choices=PLATFORMS)
    stamp.add_argument("--decision", required=True, choices=DECISIONS)
    stamp.add_argument("--note", required=True)

    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(FollowUpSelfTest)
        # 自测里会真的盖戳（在临时仓库上），那几行 `stamped …` 混在测试报告里
        # 看着像真盖了。测试的输出只留 unittest 自己的。
        with contextlib.redirect_stdout(sys.stderr):
            result = unittest.TextTestRunner(verbosity=2, stream=sys.stderr).run(suite)
        return 0 if result.wasSuccessful() else 1

    if args.cmd is None:
        parser.print_help()
        return 2

    root = repo_root()
    data = load_map(root)
    if args.cmd == "check":
        return cmd_check(root, data)
    if args.cmd == "due":
        return cmd_due(root, data, args.platform, args.json)
    if args.cmd == "show":
        return cmd_show(root, data, args.id, args.platform)
    if args.cmd == "stamp":
        return cmd_stamp(root, data, args.id, args.platform, args.decision, args.note)
    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
