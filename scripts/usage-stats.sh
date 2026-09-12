#!/usr/bin/env bash
# 拉最近的匿名页面计数。需要本机已 wrangler login。
set -euo pipefail
cd "$(dirname "$0")/../worker"

echo "=== visits (last 30 UTC days) ==="
npx wrangler d1 execute tollcat --remote --command \
  "SELECT day, platform, visits FROM usage_visits WHERE day >= date('now', '-30 day') ORDER BY day DESC, platform"

echo
echo "=== screens (last 7 UTC days) ==="
npx wrangler d1 execute tollcat --remote --command \
  "SELECT day, platform, screen, views FROM usage_screens WHERE day >= date('now', '-7 day') ORDER BY day DESC, views DESC"
