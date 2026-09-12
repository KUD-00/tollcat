#!/usr/bin/env bash
# 把本仓库跟踪的 .githooks/ 接到本地 clone 上。
# CI 不装 hook：同一组闸在 workflow 里当步骤跑，避免和 git hook 跑两遍。

set -euo pipefail

if [[ -n "${CI:-}" ]]; then
  echo "Skip git hook setup: CI (gates run as workflow steps, not a hook)."
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "Skip git hook setup: not in a git repository."
  exit 0
fi

cd "$ROOT"
git config --local core.hooksPath .githooks

if [[ -d .githooks ]]; then
  chmod +x .githooks/* 2>/dev/null || true
fi
chmod +x scripts/git-hooks/*.sh scripts/check-i18n-coverage.py scripts/check-source-invariants.py scripts/check-app-store-invariants.py scripts/check-outbound-hosts.sh scripts/check-copy-terms.py scripts/check-copy-freshness.py

echo "Configured git hooks: core.hooksPath=.githooks"
