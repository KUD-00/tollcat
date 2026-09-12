#!/usr/bin/env bash
# 扫描源码里的 https:// 字面量。host 不在 OutboundHosts 里就失败。
# 清单是唯一事实来源：加新域名先改 OutboundHosts.swift，关于页和本脚本一起跟上。
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
list="$root/Packages/MeterKit/Sources/MeterProviders/OutboundHosts.swift"

if [[ ! -f "$list" ]]; then
  echo "check-outbound-hosts: missing $list" >&2
  exit 1
fi

allowed="$(mktemp)"
trap 'rm -f "$allowed"' EXIT

{
  grep -oE 'host: "[^"]+"' "$list" | sed 's/host: "//; s/"$//'
  awk '/reservedHosts/,/]/' "$list" | grep -oE '"[^"]+"' | tr -d '"'
} | sed '/^$/d' | sort -u > "$allowed"

if [[ ! -s "$allowed" ]]; then
  echo "check-outbound-hosts: allowlist is empty" >&2
  exit 1
fi

status=0
while IFS= read -r file; do
  quoted="$(grep -oE '"https://[^"]+"' "$file" || true)"
  [[ -z "$quoted" ]] && continue
  while IFS= read -r raw; do
    url="${raw#\"}"
    url="${url%\"}"
    rest="${url#https://}"
    host="${rest%%/*}"
    host="${host%%\?*}"
    host="${host%%#*}"
    host="${host%%:*}"
    # `https://api.twilio.com\(nextPageURI)` 这种插值，反斜杠后面不是 host。
    # `https://\(shareHost)` 整段都是插值，剥完是空串，不是未申报域名。
    host="${host%%\\*}"
    if [[ -z "$host" ]]; then
      continue
    fi
    if ! grep -qxF "$host" "$allowed"; then
      echo "check-outbound-hosts: $file: $url" >&2
      echo "  host '$host' is not in OutboundHosts" >&2
      status=1
    fi
  done <<< "$quoted"
done < <(
  # 白名单目录，不扫仓库根：.claude/.atlas 里有 vendored 的第三方 js，
  # Mac/ 也要扫源码——plist 那一遍只看 <string>https://，壳源里写死的 URL 它看不见。
  # 任何一次工具升级带进一个含 URL 字面量的文件都会变成无关红灯。
  # cors.ts 豁免：里面的 https:// 是 CORS 允许的「来访 origin」，
  # 不是出站目标，进 OutboundHosts（关于页）反而是误报成出站。
  find "$root/App" "$root/Widget" "$root/Packages" "$root/worker" "$root/site" "$root/Android" "$root/Windows" "$root/Mac" \
    \( -name '*.swift' -o -name '*.ts' -o -name '*.js' -o -name '*.kt' -o -name '*.cs' \) \
    ! -path '*/.build/*' \
    ! -path '*/build/*' \
    ! -path '*/DerivedData/*' \
    ! -path '*/node_modules/*' \
    ! -name 'worker-configuration.d.ts' \
    ! -name 'cors.ts' \
    | sort
)

# Info.plist 里也有出站 URL：Mac 壳的 Sparkle 更新清单（SUFeedURL）。
# 这条不在 Swift 源里，上面那一遍扫不到，这里按 <string>https://…</string> 再扫一遍。
while IFS= read -r file; do
  quoted="$(grep -oE '<string>https://[^<]+</string>' "$file" || true)"
  [[ -z "$quoted" ]] && continue
  while IFS= read -r raw; do
    url="${raw#<string>}"
    url="${url%</string>}"
    rest="${url#https://}"
    host="${rest%%/*}"
    host="${host%%\?*}"
    host="${host%%:*}"
    if [[ -z "$host" ]]; then
      continue
    fi
    if ! grep -qxF "$host" "$allowed"; then
      echo "check-outbound-hosts: $file: $url" >&2
      echo "  host '$host' is not in OutboundHosts" >&2
      status=1
    fi
  done <<< "$quoted"
done < <(find "$root/App" "$root/Widget" "$root/Mac" -maxdepth 1 -name '*.plist' | sort)

if [[ "$status" -ne 0 ]]; then
  echo "check-outbound-hosts: undeclared outbound host(s) found" >&2
  echo "Add the host to Packages/MeterKit/Sources/MeterProviders/OutboundHosts.swift if it is intentional." >&2
  exit 1
fi

echo "check-outbound-hosts: ok ($(wc -l < "$allowed" | tr -d ' ') hosts allowed)"
