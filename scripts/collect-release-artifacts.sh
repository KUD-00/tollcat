#!/usr/bin/env bash
# 从 archive / export 收集发版资产：IPA、sha256、dSYM、LC_UUID、构建环境。
set -euo pipefail

archive="${1:?archive path}"
export_dir="${2:?export path}"
out="${3:?output directory}"
commit="${4:-unknown}"

mkdir -p "$out"

ipa="$(find "$export_dir" -maxdepth 1 -name '*.ipa' | head -n 1)"
if [[ -z "$ipa" ]]; then
  echo "collect-release-artifacts: no IPA in $export_dir" >&2
  exit 1
fi

cp "$ipa" "$out/TollCat.ipa"
shasum -a 256 "$out/TollCat.ipa" | tee "$out/TollCat.ipa.sha256"

dsym_dir="$archive/dSYMs"
if [[ -d "$dsym_dir" ]]; then
  ditto -c -k --keepParent "$dsym_dir" "$out/TollCat.dSYMs.zip"
else
  echo "collect-release-artifacts: missing dSYMs at $dsym_dir" >&2
  exit 1
fi

app="$(find "$archive/Products/Applications" -maxdepth 1 -name '*.app' | head -n 1)"
if [[ -z "$app" ]]; then
  echo "collect-release-artifacts: no .app in archive" >&2
  exit 1
fi

{
  echo "=== App executable ==="
  dwarfdump --uuid "$app/$(basename "$app" .app)"
  widget="$(find "$app/PlugIns" -name '*.appex' -maxdepth 1 2>/dev/null | head -n 1 || true)"
  if [[ -n "$widget" ]]; then
    echo
    echo "=== Widget executable ==="
    dwarfdump --uuid "$widget/$(basename "$widget" .appex)"
  fi
  echo
  echo "=== dSYMs ==="
  find "$dsym_dir" -name '*.dSYM' -print0 | sort -z | while IFS= read -r -d '' dsym; do
    echo "-- $(basename "$dsym") --"
    dwarfdump --uuid "$dsym"
  done
} > "$out/uuids.txt"

{
  echo "commit: $commit"
  echo "xcode:"
  xcodebuild -version
  echo "macos:"
  sw_vers
  echo "clang:"
  clang --version | head -n 1
} > "$out/build-info.txt"

cat "$out/build-info.txt"
echo
echo "=== uuids ==="
cat "$out/uuids.txt"
