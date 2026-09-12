#!/usr/bin/env bash
# Mac 直发版从 Developer ID 导出到「能被 Sparkle 装上」之间的全部步骤：
# 公证 → 盖章 → 打分发 zip → sha256 / dSYM / LC_UUID → 用 EdDSA 私钥签 zip → 写 appcast.xml。
#
# 用法：
#   package-mac-release.sh <archive> <export_dir> <out_dir> <commit> <tag> <download_url_prefix>
# 环境：
#   ASC_KEY_PATH / APP_STORE_CONNECT_KEY_ID / ISSUER_ID   notarytool 用的 App Store Connect API key
#   SPARKLE_BIN                                            Sparkle 发行版的 bin/ 目录（sign_update 在里面）
#   SPARKLE_PRIVATE_KEY_FILE                               generate_keys -x 导出的私钥文件
#
# appcast 只写这一版：清单由 mac-appcast.yml 在 Publish 时覆盖到滚动 Release「mac-appcast」，老版本的条目跟着老 release 走，
# Sparkle 只需要知道「最新是哪个、去哪下、签名是什么」。因此没有增量补丁。
set -euo pipefail

archive="${1:?archive path}"
export_dir="${2:?export path}"
out="${3:?output directory}"
commit="${4:-unknown}"
tag="${5:?git tag}"
download_prefix="${6:?download url prefix}"

: "${ASC_KEY_PATH:?}" "${APP_STORE_CONNECT_KEY_ID:?}" "${ISSUER_ID:?}"
: "${SPARKLE_BIN:?}" "${SPARKLE_PRIVATE_KEY_FILE:?}"

mkdir -p "$out"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

app="$(find "$export_dir" -maxdepth 1 -name '*.app' | head -n 1)"
if [[ -z "$app" ]]; then
  echo "package-mac-release: no .app in $export_dir" >&2
  exit 1
fi

plist="$app/Contents/Info.plist"
read_plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$plist"; }
version="$(read_plist CFBundleShortVersionString)"
build="$(read_plist CFBundleVersion)"
min_os="$(read_plist LSMinimumSystemVersion)"
feed_url="$(read_plist SUFeedURL)"
public_key="$(read_plist SUPublicEDKey)"

if [[ "$tag" != "v$version" ]]; then
  echo "package-mac-release: tag $tag does not match CFBundleShortVersionString $version" >&2
  exit 1
fi

# 公钥/私钥必须是一对，否则发出去的包所有已装机的 App 都拒装，而且要等用户反馈才知道。
derived_public="$(swift "$(dirname "$0")/sparkle-public-key.swift" "$SPARKLE_PRIVATE_KEY_FILE")"
if [[ "$derived_public" != "$public_key" ]]; then
  echo "package-mac-release: SUPublicEDKey in Info.plist does not match the signing key" >&2
  echo "  Info.plist: $public_key" >&2
  echo "  key file:   $derived_public" >&2
  exit 1
fi

echo "=== notarize ==="
ditto -c -k --keepParent "$app" "$tmp/notarize.zip"
submission="$(xcrun notarytool submit "$tmp/notarize.zip" \
  --key "$ASC_KEY_PATH" \
  --key-id "$APP_STORE_CONNECT_KEY_ID" \
  --issuer "$ISSUER_ID" \
  --wait --timeout 45m \
  --output-format json)"
echo "$submission"
status="$(echo "$submission" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))')"
submission_id="$(echo "$submission" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))')"
if [[ "$status" != "Accepted" ]]; then
  echo "package-mac-release: notarization status '$status'" >&2
  if [[ -n "$submission_id" ]]; then
    xcrun notarytool log "$submission_id" \
      --key "$ASC_KEY_PATH" --key-id "$APP_STORE_CONNECT_KEY_ID" --issuer "$ISSUER_ID" >&2 || true
  fi
  exit 1
fi

echo "=== staple ==="
xcrun stapler staple "$app"
xcrun stapler validate "$app"
codesign --verify --deep --strict --verbose=2 "$app"

echo "=== package ==="
zip_name="TollCat-${version}-mac.zip"
# --sequesterRsrc 把扩展属性收进 __MACOSX，解压后签名和盖章都还在；不加这个 Gatekeeper 会重新联网核验。
ditto -c -k --sequesterRsrc --keepParent "$app" "$out/$zip_name"
(cd "$out" && shasum -a 256 "$zip_name" | tee "$zip_name.sha256")

dsym_dir="$archive/dSYMs"
if [[ -d "$dsym_dir" ]]; then
  ditto -c -k --keepParent "$dsym_dir" "$out/TollCat-mac.dSYMs.zip"
else
  echo "package-mac-release: missing dSYMs at $dsym_dir" >&2
  exit 1
fi

{
  echo "=== App executable ==="
  dwarfdump --uuid "$app/Contents/MacOS/$(basename "$app" .app)"
  widget="$(find "$app/Contents/PlugIns" "$app/Contents/Extensions" -maxdepth 1 -name '*.appex' 2>/dev/null | head -n 1 || true)"
  if [[ -n "$widget" ]]; then
    echo
    echo "=== Widget executable ==="
    dwarfdump --uuid "$widget/Contents/MacOS/$(basename "$widget" .appex)"
  fi
  echo
  echo "=== dSYMs ==="
  find "$dsym_dir" -name '*.dSYM' -print0 | sort -z | while IFS= read -r -d '' dsym; do
    echo "-- $(basename "$dsym") --"
    dwarfdump --uuid "$dsym"
  done
} > "$out/uuids-mac.txt"

{
  echo "commit: $commit"
  echo "tag: $tag"
  echo "version: $version ($build)"
  echo "xcode:"
  xcodebuild -version
  echo "macos:"
  sw_vers
  echo "sparkle tools:"
  "$SPARKLE_BIN/sign_update" --version 2>/dev/null || echo "(sign_update has no --version)"
} > "$out/build-info-mac.txt"

echo "=== sign for Sparkle ==="
# 输出形如：sparkle:edSignature="…" length="…"
signature_attrs="$("$SPARKLE_BIN/sign_update" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" "$out/$zip_name")"
echo "$signature_attrs"
if [[ "$signature_attrs" != *sparkle:edSignature=* ]]; then
  echo "package-mac-release: sign_update did not return a signature" >&2
  exit 1
fi
# 用 App 里那把公钥再验一次：签名工具和 Info.plist 各说各的，这里是它们唯一的交汇点。
signature="$(sed -nE 's/.*sparkle:edSignature="([^"]+)".*/\1/p' <<< "$signature_attrs")"
swift "$(dirname "$0")/verify-sparkle-signature.swift" "$out/$zip_name" "$signature" "$public_key"

echo "=== appcast ==="
pub_date="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"
release_page="https://github.com/KUD-00/tollcat/releases/tag/${tag}"

# 更新说明：和 App 抽屉、落地页、商店文案同一个权威（shared/changelog.json），
# 由 generate-shared.py 铺成 HTML 片段。zh 那份不带 xml:lang——Sparkle 找不到
# 匹配语言时用的就是没有属性的那一条，所以它同时是中文版和兜底版。
notes_dir="$(cd "$(dirname "$0")/.." && pwd)/docs/release/appcast-notes"
descriptions=""
for lang in zh en ja; do
  file="$notes_dir/$lang.html"
  if [[ ! -f "$file" ]]; then
    echo "package-mac-release: 缺 $file——改了 shared/changelog.json 要重跑 generate-shared.py" >&2
    exit 1
  fi
  if [[ "$lang" == "zh" ]]; then
    open_tag="<description>"
  else
    open_tag="<description xml:lang=\"$lang\">"
  fi
  descriptions+="      ${open_tag}<![CDATA[
$(cat "$file")
]]></description>
"
done

cat > "$out/appcast.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>TollCat</title>
    <link>${feed_url}</link>
    <description>TollCat for Mac updates</description>
    <language>zh-Hans</language>
    <item>
      <title>${version}</title>
      <pubDate>${pub_date}</pubDate>
      <link>${release_page}</link>
${descriptions%$'\n'}
      <sparkle:version>${build}</sparkle:version>
      <sparkle:shortVersionString>${version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>${min_os}</sparkle:minimumSystemVersion>
      <enclosure url="${download_prefix%/}/${zip_name}" ${signature_attrs} type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
# 写完就验一遍：Sparkle 静默吃掉坏 XML，用户那边只会看到「已是最新」。
xmllint --noout "$out/appcast.xml"

cat "$out/build-info-mac.txt"
echo
echo "=== uuids ==="
cat "$out/uuids-mac.txt"
echo
echo "=== appcast ==="
cat "$out/appcast.xml"
