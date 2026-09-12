#!/usr/bin/env bash
# Commit messages are English only.
#
# The code, comments and docs in this repository are largely Chinese; the
# commit log is not. It is the one surface every contributor, tool and
# release note reads, so it stays in a single language.
#
# Usage:
#   commit-msg-gate.sh <message-file>   # as the commit-msg hook
#   commit-msg-gate.sh --history        # every commit reachable from any ref (CI)
#
# "English" here means: no CJK ideographs, kana, hangul, or fullwidth
# punctuation anywhere in the message. Everything else (code identifiers,
# URLs, provider names) is fine.

set -euo pipefail

check_file() {
  # $1 = label for the error, $2 = file holding the message text
  python3 - "$1" "$2" <<'PY'
import re, sys
label, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8", errors="replace").read()
cjk = re.compile(r'[\u3000-\u303f\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uff00-\uffef\uac00-\ud7af]')
bad = [(n, line) for n, line in enumerate(text.splitlines(), 1)
       if not line.startswith('#') and cjk.search(line)]
if bad:
    print(f"\n✖ {label}: commit message is not English.", file=sys.stderr)
    for n, line in bad[:5]:
        print(f"  line {n}: {line.strip()[:100]}", file=sys.stderr)
    print("  Why: the commit log is the one surface everyone reads; it stays in one language.", file=sys.stderr)
    print("  Fix: rewrite the message in English (git commit --amend for the last commit).", file=sys.stderr)
    sys.exit(1)
PY
}

if [[ "${1:-}" == "--history" ]]; then
  status=0
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  while read -r sha; do
    git log -1 --format=%B "$sha" > "$tmp"
    if ! check_file "$(git log -1 --format=%h "$sha")" "$tmp"; then
      status=1
    fi
  done < <(git rev-list --all)
  exit "$status"
fi

[[ -n "${1:-}" && -f "$1" ]] || { echo "usage: $0 <message-file> | --history" >&2; exit 2; }
check_file "commit-msg" "$1"
