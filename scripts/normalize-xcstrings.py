#!/usr/bin/env python3
"""把 String Catalog 收成一种写法，好让 Xcode 的回写不再变成 diff。

Xcode 每次构建都会拿源码里抽出来的字串回写 `.xcstrings`：重排键、给没抽到的
键盖 `extractionState: stale`。那不是谁改的，是构建副产物——可它照样出现在
`git status` 里，每次都要人去分辨「这一千多行里哪几行是真的」。

这里定一种规范写法，Xcode 的回写落到它上面就是空操作：

- 键按码位排序。`xcstringstool sync` 自己就是这么排的，所以排过一次之后，
  Xcode 的回写在顺序上是空操作——那上千行噪音的来源就没了。
- 格式跟 Xcode 一致：UTF-8、两格缩进、`"键" : 值`

**`extractionState` 原样留着**，包括 `stale`。试过丢掉：`stale` 同时也是
i18n 闸的跳过标记，一丢，闸就开始挑早已没人用的字串的毛病。而且它本来就
随平台变（Mac 专属的字串在 iOS 构建里必然抽不到），仓库里留着哪一版都不算错。
同一份源码反复构建产出的 stale 集合是稳定的，顺序钉死之后日常构建就不再有 diff。

译文一个字都不动，键一个都不删。

  python3 scripts/normalize-xcstrings.py           # 就地收拾
  python3 scripts/normalize-xcstrings.py --check   # 只报告，不写（提交闸用）
  python3 scripts/normalize-xcstrings.py --stdin   # 一份进一份出，给 git filter 用

想让它连 `git status` 都不出现，把 `--stdin` 挂成 clean filter（每台机器一次）：

  git config filter.xcstrings.clean "python3 scripts/normalize-xcstrings.py --stdin"

`.gitattributes` 已经点名了要走这个 filter 的路径。没配也不会坏：git 对没定义
的 filter 就是原样放行，只是回到「Xcode 一构建就有 diff」而已。
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# 只管人写的那几份。构建产物里到处都是同名文件：`.build` / `.derived` 下的
# 副本，以及 `Android/app/src/main/assets/swiftpm/` 里那两份——后者虽然进了
# 仓库，却是 Android native 构建摆出来的，收拾它只会让下一次构建又不一致。
CATALOG_ROOTS = ("Packages/MeterKit/Sources", "App/Resources")


def catalogs(root: Path) -> list[Path]:
    found = []
    for base in CATALOG_ROOTS:
        found.extend(sorted((root / base).rglob("*.xcstrings")))
    return found


def sort_keys(node):
    """递归按键排序。Xcode 写出来就是排好的，跟着它就不会有第二种写法。"""
    if isinstance(node, dict):
        return {key: sort_keys(node[key]) for key in sorted(node)}
    if isinstance(node, list):
        return [sort_keys(item) for item in node]
    return node


def normalized(text: str) -> str:
    data = sort_keys(json.loads(text))
    return json.dumps(data, ensure_ascii=False, indent=2, separators=(",", " : ")) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="只报告要改哪些文件，不写")
    parser.add_argument("--stdin", action="store_true", help="从标准输入读一份，写到标准输出")
    parser.add_argument("paths", nargs="*", help="指定文件；不给就扫整棵树")
    args = parser.parse_args()

    if args.stdin:
        # git 的 clean filter 会拿各种东西喂过来（合并中途的半份、空文件）。
        # 看不懂就原样放行——filter 不是校验器，挡在这里只会让 git 操作失败。
        raw = sys.stdin.read()
        try:
            sys.stdout.write(normalized(raw))
        except (json.JSONDecodeError, AttributeError):
            sys.stdout.write(raw)
        return 0

    root = Path(__file__).resolve().parent.parent
    targets = [Path(p) for p in args.paths] if args.paths else catalogs(root)

    dirty = []
    for path in targets:
        before = path.read_text(encoding="utf-8")
        after = normalized(before)
        if before == after:
            continue
        dirty.append(path)
        if not args.check:
            path.write_text(after, encoding="utf-8")

    if not dirty:
        print(f"normalize-xcstrings: ok（{len(targets)} 份都是规范写法）")
        return 0

    if args.check:
        print("normalize-xcstrings: 下面这些不是规范写法，多半是 Xcode 构建回写的：", file=sys.stderr)
        for path in dirty:
            print(f"  {path.relative_to(root)}", file=sys.stderr)
        print("  跑 python3 scripts/normalize-xcstrings.py 收拾干净。", file=sys.stderr)
        return 1

    for path in dirty:
        print(f"收拾 {path.relative_to(root)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
