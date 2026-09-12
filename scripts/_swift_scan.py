#!/usr/bin/env python3
"""闸脚本共用的 Swift 词法工具。

`check-source-invariants.py` 和 `check-design-lint.py` 要先抹注释和字符串再找括号。
`check-follow-up.py` 哈希时只抹注释、保留字符串（产品行为经常落在字面量上）。

这里**只放词法**，不放任何规则：规则各自留在自己的脚本里。
"""

from __future__ import annotations

import re
from pathlib import Path

CONTROL_RE = re.compile(r"\b(?:Button|ShareLink)\b")


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def swift_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.rglob("*.swift") if path.is_file())


def rel(root: Path, path: Path) -> str:
    return str(path.relative_to(root))


def gate_text(root: Path, path: Path, errors: list[str]) -> str | None:
    """闸盯着的文件必须在，读不到就报错——**不是**静默放行。

    这里以前是 `if path.is_file():`。把被守的文件改个名或者挪个位置，
    这一整条规矩就一条都不查了，而脚本仍然打印 `ok`。
    闸最糟的失效方式不是误报，是"看起来通过了"。

    真删掉一个文件时也该在这里响一次：那说明这条规矩要么跟着搬，要么该删。
    """
    if not path.is_file():
        errors.append(
            f"{rel(root, path)} 不在了：闸盯着这个文件。改名 / 挪位要同时改闸，"
            "不能让规矩悄悄失效。"
        )
        return None
    return path.read_text(encoding="utf-8")


def scan_app_widget_sources(root: Path) -> list[Path]:
    files: list[Path] = []
    for folder in ("App", "Mac", "Widget", "Packages/MeterKit/Sources"):
        files.extend(swift_files(root / folder))
    return files


def _scan_swift_lexemes(text: str, *, blank_strings: bool) -> str:
    """Keep length. Blank comments; optionally blank string literals too.

    `blank_strings=True` is for brace matching (design-lint). `False` is for
    follow-up hashing: product copy lives in string literals and must count.
    """
    out: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if ch == "/" and nxt == "/":
            while i < n and text[i] != "\n":
                out.append(" ")
                i += 1
            continue
        if ch == "/" and nxt == "*":
            out.extend([" ", " "])
            i += 2
            while i < n:
                if text[i] == "*" and i + 1 < n and text[i + 1] == "/":
                    out.extend([" ", " "])
                    i += 2
                    break
                out.append("\n" if text[i] == "\n" else " ")
                i += 1
            continue
        if ch in "\"'`":
            quote = ch
            out.append(" " if blank_strings else ch)
            i += 1
            if quote == "`":
                while i < n and text[i] != "`":
                    cur = text[i]
                    if blank_strings:
                        out.append("\n" if cur == "\n" else " ")
                    else:
                        out.append(cur)
                    i += 1
                if i < n:
                    out.append(" " if blank_strings else text[i])
                    i += 1
                continue
            while i < n:
                cur = text[i]
                if cur == "\\":
                    if blank_strings:
                        out.extend([" ", " "])
                    else:
                        out.append(cur)
                        if i + 1 < n:
                            out.append(text[i + 1])
                    i += 2
                    continue
                if cur == quote:
                    out.append(" " if blank_strings else cur)
                    i += 1
                    break
                if blank_strings:
                    out.append("\n" if cur == "\n" else " ")
                else:
                    out.append(cur)
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def mask_comments_and_strings(text: str) -> str:
    """Keep length; blank out comments and string literals so braces stay aligned."""
    return _scan_swift_lexemes(text, blank_strings=True)


def mask_comments(text: str) -> str:
    """Keep length; blank comments only. String literals stay (follow-up hash)."""
    return _scan_swift_lexemes(text, blank_strings=False)


def last_control_start(masked: str, end: int) -> int | None:
    last = None
    for match in CONTROL_RE.finditer(masked[:end]):
        last = match.start()
    return last

