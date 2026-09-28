#!/usr/bin/env bash
# Swift Static Linux SDK → 全静态 x86_64 / aarch64 二进制。
# 需要本机已装对应 SDK：swift sdk list
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
sdk="${SWIFT_STATIC_LINUX_SDK:-}"
arch="${1:-$(uname -m)}"
triple=""
case "$arch" in
  x86_64|amd64) triple="x86_64-swift-linux-musl" ;;
  aarch64|arm64) triple="aarch64-swift-linux-musl" ;;
  *)
    echo "usage: $0 x86_64|aarch64" >&2
    exit 2
    ;;
esac

if [[ -z "$sdk" ]]; then
  sdk="$(swift sdk list 2>/dev/null | awk '/swift-linux-musl/{print $1; exit}')"
fi
if [[ -z "$sdk" ]]; then
  echo "install the Swift Static Linux SDK first: https://www.swift.org/documentation/articles/static-linux-getting-started.html" >&2
  exit 1
fi

swift build --package-path "$root/CLI" -c release --swift-sdk "$sdk" --arch "${triple%%-*}"
echo "binary: $root/CLI/.build/release/tollcat"
