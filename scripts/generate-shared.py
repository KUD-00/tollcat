#!/usr/bin/env python3
"""shared/ 单一事实源 → 各端生成物。

数据只在 shared/*.json 里改，跑本脚本铺到 Swift / Kotlin / TypeScript / C#，
生成物提交进仓库（和 xcodegen 的 xcodeproj 同一哲学）。

    python3 scripts/generate-shared.py           # 写出全部生成物
    python3 scripts/generate-shared.py --check   # 只比对，不一致退出 1（提交闸用）

生成物开头都有 GENERATED 标记。手改生成物没有意义：下一次生成会盖掉，
`--check` 闸也会红。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

GENERATED_MARK = "GENERATED"


def swift_header(source: str) -> str:
    return (
        f"// {GENERATED_MARK} — 由 scripts/generate-shared.py 从 {source} 生成。\n"
        f"// 不要手改：改 {source} 后重跑生成器。\n"
    )


def kotlin_header(source: str) -> str:
    return swift_header(source)


def ts_header(source: str) -> str:
    return (
        f"// {GENERATED_MARK} — 由 scripts/generate-shared.py 从 {source} 生成。\n"
        f"// 不要手改：改 {source} 后重跑生成器。\n"
    )


def csharp_header(source: str) -> str:
    return swift_header(source)


def doc_comment(lines: list[str], prefix: str = "/// ") -> str:
    return "\n".join(f"{prefix}{line}" if line else prefix.rstrip() for line in lines)


# ---------------------------------------------------------------------------
# providers.json → glyph path / 品牌色 / fill / evenOdd


def load_providers() -> dict:
    return json.loads((ROOT / "shared/providers.json").read_text(encoding="utf-8"))


def provider_path_map(doc: dict) -> tuple[list[dict], dict[str, str]]:
    """返回 (条目, key→path 已解析 pathRef)。"""
    resolved: dict[str, str] = {}
    by_key = {p["key"]: p for p in doc["providers"]}
    for p in doc["providers"]:
        if "path" in p:
            resolved[p["key"]] = p["path"]
    for p in doc["providers"]:
        if "pathRef" in p:
            ref = p["pathRef"]
            if ref not in resolved:
                raise SystemExit(f"providers.json: {p['key']} 的 pathRef={ref} 不存在")
            resolved[p["key"]] = resolved[ref]
    return doc["providers"], resolved


def gen_swift_glyph_artwork(doc: dict) -> str:
    providers, _ = provider_path_map(doc)
    default_fill = doc["defaultFill"]
    even_odd = [p["key"] for p in providers if p.get("evenOdd")]
    fills = [(p["key"], p["fill"]) for p in providers if "fill" in p]

    lines: list[str] = [swift_header("shared/providers.json"), "", "import SwiftUI", ""]
    lines.append(doc_comment(doc["provenance"]))
    lines.append("enum ProviderGlyphArtwork {")
    lines.append("    static func pathData(for colorKey: String) -> String? {")
    lines.append("        switch colorKey.lowercased() {")
    for p in providers:
        if "path" in p:
            lines.append(f'        case "{p["key"]}": {p["key"]}')
        elif "pathRef" in p:
            lines.append(f'        case "{p["key"]}": {p["pathRef"]}')
    lines.append("        default: nil")
    lines.append("        }")
    lines.append("    }")
    lines.append("")
    lines.append("    /// 外框+挖空的官方 path，nonzero 会糊成实心块。")
    lines.append("    static func usesEvenOddFill(for colorKey: String) -> Bool {")
    lines.append("        switch colorKey.lowercased() {")
    lines.append("        case " + ", ".join(f'"{k}"' for k in even_odd) + ": true")
    lines.append("        default: false")
    lines.append("        }")
    lines.append("    }")
    lines.append("")
    lines.append("    /// glyph 在 tile 里的边长占比。")
    lines.append("    static func fillRatio(for colorKey: String) -> CGFloat {")
    lines.append("        switch colorKey.lowercased() {")
    for key, fill in fills:
        lines.append(f'        case "{key}": {fill}')
    lines.append(f"        default: {default_fill}")
    lines.append("        }")
    lines.append("    }")
    lines.append("")
    lines.append("    /// 拿不到官方 path 的 key 回落到首字母，不手绘仿制 logo。")
    lines.append("    static func monogramLetter(for colorKey: String) -> String {")
    lines.append("        let key = colorKey.trimmingCharacters(in: .whitespacesAndNewlines)")
    lines.append('        guard let first = key.first else { return "?" }')
    lines.append("        return String(first).uppercased()")
    lines.append("    }")
    for p in providers:
        if "path" in p:
            lines.append("")
            lines.append(f'    private static let {p["key"]} = "{p["path"]}"')
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_swift_palette(doc: dict) -> str:
    providers = doc["providers"]
    fb = doc["fallback"]
    lines = [swift_header("shared/providers.json"), "", "import SwiftUI", ""]
    lines.append("/// 厂商标识色，light / dark 两套。只进 `ProviderGlyph` 的 tile，")
    lines.append("/// 不进图表和大面积。语义色在 `MeterColor`。")
    lines.append("enum ProviderPalette {")
    lines.append("    /// 目录外的 key 用回落灰——和 Android `ProviderColors`、site 同一份值。")
    lines.append(
        f"    static let fallback = Color(light: 0x{fb['light'][1:]}, dark: 0x{fb['dark'][1:]})"
    )
    lines.append("")
    lines.append("    static func color(for key: String) -> Color {")
    lines.append("        switch key.lowercased() {")
    for p in providers:
        lines.append(
            f'        case "{p["key"]}": Color(light: 0x{p["light"][1:]}, dark: 0x{p["dark"][1:]})'
        )
    lines.append("        default: fallback")
    lines.append("        }")
    lines.append("    }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_kotlin_glyph_artwork(doc: dict) -> str:
    providers, _ = provider_path_map(doc)
    default_fill = doc["defaultFill"]
    even_odd = [p["key"] for p in providers if p.get("evenOdd")]
    fills = [(p["key"], p["fill"]) for p in providers if "fill" in p]

    lines = [kotlin_header("shared/providers.json"), "", "package com.zhechengqi.tollcat.services", ""]
    lines.append("import androidx.compose.ui.graphics.Path")
    lines.append("import androidx.compose.ui.graphics.PathFillType")
    lines.append("import androidx.compose.ui.graphics.vector.PathParser")
    lines.append("")
    lines.append("/**")
    for line in doc["provenance"]:
        lines.append(f" * {line}")
    lines.append(" */")
    lines.append("internal object ProviderGlyphArtwork {")
    lines.append("    /** glyph 在 tile 里的边长占比。 */")
    lines.append("    fun fillRatio(colorKey: String): Float = when (colorKey.lowercase()) {")
    for key, fill in fills:
        lines.append(f'        "{key}" -> {fill}f')
    lines.append(f"        else -> {default_fill}f")
    lines.append("    }")
    lines.append("")
    lines.append("    /** 外框+挖空的官方 path，nonzero 会糊成实心块。 */")
    lines.append("    fun usesEvenOddFill(colorKey: String): Boolean = when (colorKey.lowercase()) {")
    lines.append("        " + ", ".join(f'"{k}"' for k in even_odd) + " -> true")
    lines.append("        else -> false")
    lines.append("    }")
    lines.append("")
    lines.append("    /** 拿不到官方 path 的 key 回落到首字母，不手绘仿制 logo。 */")
    lines.append("    fun monogramLetter(colorKey: String): String {")
    lines.append('        val first = colorKey.trim().firstOrNull() ?: return "?"')
    lines.append("        return first.uppercase()")
    lines.append("    }")
    lines.append("")
    lines.append("    private val cache = mutableMapOf<String, Path?>()")
    lines.append("")
    lines.append("    /** 每个 key 的 path 只 tokenize 一次。挖空 path 直接带 EvenOdd fillType。 */")
    lines.append("    fun path(colorKey: String): Path? {")
    lines.append("        val key = colorKey.lowercase()")
    lines.append("        return cache.getOrPut(key) {")
    lines.append("            pathData(key)?.let {")
    lines.append("                PathParser().parsePathString(it).toPath().apply {")
    lines.append("                    if (usesEvenOddFill(key)) fillType = PathFillType.EvenOdd")
    lines.append("                }")
    lines.append("            }")
    lines.append("        }")
    lines.append("    }")
    lines.append("")
    lines.append("    fun pathData(colorKey: String): String? = when (colorKey.lowercase()) {")
    for p in providers:
        if "path" in p:
            lines.append(f'        "{p["key"]}" -> {p["key"].upper()}')
        elif "pathRef" in p:
            lines.append(f'        "{p["key"]}" -> {p["pathRef"].upper()}')
    lines.append("        else -> null")
    lines.append("    }")
    for p in providers:
        if "path" in p:
            lines.append("")
            lines.append(f'    private const val {p["key"].upper()} = "{p["path"]}"')
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_kotlin_colors(doc: dict) -> str:
    providers = doc["providers"]
    fb = doc["fallback"]
    lines = [kotlin_header("shared/providers.json"), "", "package com.zhechengqi.tollcat", ""]
    lines.append("import androidx.compose.ui.graphics.Color")
    lines.append("")
    lines.append("/** 厂商标识色，和 iOS `ProviderPalette`、site 同一份表。只进 glyph tile，不进图表和大面积。 */")
    lines.append("object ProviderColors {")
    lines.append("    fun of(key: String, dark: Boolean): Color {")
    lines.append("        val packed = when (key.lowercase()) {")
    for p in providers:
        lines.append(
            f'            "{p["key"]}" -> if (dark) 0xFF{p["dark"][1:]} else 0xFF{p["light"][1:]}'
        )
    lines.append(f"            else -> if (dark) 0xFF{fb['dark'][1:]} else 0xFF{fb['light'][1:]}")
    lines.append("        }")
    lines.append("        return Color(packed)")
    lines.append("    }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_site_providers(doc: dict) -> str:
    providers, resolved = provider_path_map(doc)
    lines = [ts_header("shared/providers.json"), ""]
    lines.append("/** App 里同一份 Simple Icons path（CC0）。xAI / Azure 条款不许改色，走字母回落。 */")
    lines.append("export type ProviderMark = {")
    lines.append("  key: string;")
    lines.append("  name: string;")
    lines.append("  light: string;")
    lines.append("  dark: string;")
    lines.append("  path?: string;")
    lines.append("  evenOdd?: true;")
    lines.append("  fill?: number;")
    lines.append("};")
    lines.append("")
    lines.append("export const providerMarks: readonly ProviderMark[] = [")
    for p in providers:
        if p.get("offered") is False:
            continue
        parts = [
            f'key: "{p["key"]}"',
            f'name: "{p["name"]}"',
            f'light: "{p["light"]}"',
            f'dark: "{p["dark"]}"',
        ]
        if p["key"] in resolved:
            parts.append(f'path: "{resolved[p["key"]]}"')
        if p.get("evenOdd"):
            parts.append("evenOdd: true")
        if "fill" in p:
            parts.append(f'fill: {p["fill"]}')
        lines.append("  { " + ", ".join(parts) + " },")
    lines.append("];")
    lines.append("")
    lines.append("/** 含不接入的家。落地页清单用这份；marquee 仍走 providerMarks。 */")
    lines.append("export const providerNames: readonly { key: string; name: string }[] = [")
    for p in providers:
        lines.append(f'  {{ key: "{p["key"]}", name: "{p["name"]}" }},')
    lines.append("];")
    lines.append("")
    lines.append("/** 落地页 marquee 只放拿到官方 path 的家；字母回落只在 App 内列表出现。 */")
    lines.append("export const marqueeMarks: readonly ProviderMark[] = providerMarks.filter((item) => item.path);")
    lines.append("")
    lines.append("export function providerRows(count = 3): ProviderMark[][] {")
    lines.append("  const rows: ProviderMark[][] = Array.from({ length: count }, () => []);")
    lines.append("  marqueeMarks.forEach((item, index) => {")
    lines.append("    rows[index % count].push(item);")
    lines.append("  });")
    lines.append("  return rows;")
    lines.append("}")
    return "\n".join(lines) + "\n"



def provider_catalog_sources() -> str:
    """目录权威：ProviderCatalog.swift 加上各 Batch 扩展。描述体不在壳里。"""
    root = ROOT / "Packages/MeterKit/Sources/MeterProviders"
    parts = [(root / "ProviderCatalog.swift").read_text(encoding="utf-8")]
    for batch in sorted(root.glob("ProviderCatalog+Batch*.swift")):
        parts.append(batch.read_text(encoding="utf-8"))
    return "\n".join(parts)

def parse_provider_catalog() -> list[dict]:
    """接入分层的权威在 ProviderCatalog.swift（含 Batch 扩展），落地页清单从这里生成。"""
    text = provider_catalog_sources()
    rows: list[dict] = []
    for block in text.split("\n    public static let ")[1:]:
        color = re.search(r'colorKey:\s*"([^"]+)"', block)
        display = re.search(r'displayName:\s*"([^"]+)"', block)
        status = re.search(r"accessStatus:\s*\.(\w+)", block)
        kind = re.search(r"kind:\s*\.(\w+)", block)
        if not (color and display and status and kind):
            continue
        billing = re.search(r'billingURL:\s*URL\(string:\s*"([^"]+)"\)', block)
        setup = re.search(r'credentialSetupURL:\s*URL\(string:\s*"([^"]+)"\)', block)
        reason = re.search(r'declineReason:\s*"((?:\\.|[^"\\])*)"', block)
        market_tier = re.search(r"tier:\s*\.(one|two|three|four)", block)
        market_reason = re.search(r'tierReason:\s*"((?:\\.|[^"\\])*)"', block)
        if not market_tier or not market_reason or not market_reason.group(1).strip():
            key = color.group(1)
            raise SystemExit(f"ProviderCatalog.swift: {key} 缺 tier / tierReason")
        lookback = re.search(r"historyLookbackMonths:\s*(\d+)", block)
        refresh_interval = re.search(r"minimumRefreshInterval:\s*([0-9_]+)", block)
        keywords_m = re.search(r"searchKeywords:\s*\[(.*?)\]", block, re.S)
        keywords = re.findall(r'"((?:\\.|[^"\\])*)"', keywords_m.group(1)) if keywords_m else []
        guide_m = re.search(r"guideURLs:\s*\[(.*?)\]\s*(?:,|\))", block, re.S)
        guide_urls: list[dict[str, str]] = []
        if guide_m:
            for item in re.finditer(
                r'"([^"]+)"\s*:\s*URL\(\s*string:\s*"([^"]+)"\)',
                guide_m.group(1),
            ):
                guide_urls.append({"id": item.group(1), "url": item.group(2)})
        rows.append(
            {
                "key": color.group(1),
                "name": display.group(1),
                "status": status.group(1),
                "kind": kind.group(1),
                "inbox": bool(re.search(r"supportsInboxIngest:\s*true", block)),
                "costsMoneyToRefresh": bool(re.search(r"costsMoneyToRefresh:\s*true", block)),
                "supportsDailyGranularity": bool(
                    re.search(r"supportsDailyGranularity:\s*true", block)
                ),
                "historyLookbackMonths": int(lookback.group(1)) if lookback else 0,
                "minimumRefreshInterval": int(refresh_interval.group(1).replace("_", ""))
                if refresh_interval
                else 0,
                "marketTier": {"one": 1, "two": 2, "three": 3, "four": 4}[
                    market_tier.group(1)
                ],
                "marketTierReason": market_reason.group(1)
                .replace('\\"', '"')
                .replace("\\\\", "\\"),
                "declineReason": reason.group(1) if reason else None,
                "searchKeywords": keywords,
                "billingURL": billing.group(1) if billing else None,
                "credentialSetupURL": setup.group(1) if setup else None,
                "guideURLs": guide_urls,
            }
        )
    if len(rows) < 50:
        raise SystemExit(f"ProviderCatalog.swift: 解析到 {len(rows)} 家，像是解析坏了")
    return rows


# ---------------------------------------------------------------------------
# ProviderCatalog.swift → 厂商身份表（叫什么 / 什么色 / 什么类），生成进 MeterCore


def provider_id_members() -> dict[str, str]:
    """`ProviderID.cloudflare` → `"cloudflare"`。目录里写的是成员名，表要按 rawValue 建。"""
    path = ROOT / "Packages/MeterKit/Sources/MeterCore/ProviderID.swift"
    members = dict(
        re.findall(
            r'public static let (\w+) = ProviderID\(rawValue: "([^"]+)"\)',
            path.read_text(encoding="utf-8"),
        )
    )
    if len(members) < 50:
        raise SystemExit(f"ProviderID.swift: 只解析到 {len(members)} 个 id，像是解析坏了")
    return members


def parse_provider_identity() -> list[dict]:
    """身份的权威是 ProviderCatalog.swift（和接入分层同一份），不是 providers.json——
    后者只管画：glyph path 和品牌色。名字两边必须一致，`verify_provider_identity` 守着。
    """
    members = provider_id_members()
    text = provider_catalog_sources()
    rows: list[dict] = []
    seen: set[str] = set()
    for block in text.split("\n    public static let ")[1:]:
        ident = re.search(r"id:\s*\.(\w+)", block)
        display = re.search(r'displayName:\s*"([^"]+)"', block)
        color = re.search(r'colorKey:\s*"([^"]+)"', block)
        category = re.search(r"category:\s*\.(\w+)", block)
        if not (ident and display and color and category):
            continue
        raw = members.get(ident.group(1))
        if raw is None:
            raise SystemExit(f"ProviderCatalog.swift: id .{ident.group(1)} 在 ProviderID.swift 里没有")
        if raw in seen:
            continue
        seen.add(raw)
        tier = re.search(r"tier:\s*\.(one|two|three|four)", block)
        reason = re.search(r'tierReason:\s*"((?:\\.|[^"\\])*)"', block)
        if not tier:
            raise SystemExit(f"ProviderCatalog.swift: {ident.group(1)} 缺 tier")
        if not reason or not reason.group(1).strip():
            raise SystemExit(f"ProviderCatalog.swift: {ident.group(1)} 缺 tierReason")
        rows.append(
            {
                "raw": raw,
                "member": ident.group(1),
                "name": display.group(1),
                "colorKey": color.group(1),
                "category": category.group(1),
                "costsMoneyToRefresh": bool(re.search(r"costsMoneyToRefresh:\s*true", block)),
                "tier": tier.group(1),
                "tierReason": reason.group(1).replace('\\"', '"').replace("\\\\", "\\"),
            }
        )
    if len(rows) < 50:
        raise SystemExit(f"ProviderCatalog.swift: 身份只解析到 {len(rows)} 家，像是解析坏了")
    return rows


# 字母回落必须写清为什么。条款只覆盖少数几家，不能当万能借口。
LETTER_REASON_PREFIXES = (
    "条款禁止改色改 path",
    "品牌并入另一家",
    "只有扁字标",
    "官网 SVG 是位图",
    "官网 SVG 是 HTML",
    "官网 SVG 是描边",
    "官网 SVG 是渐变/mask",
    "抓到的是框架默认图标",
    "Simple Icons 没有",
    "商标条款",
)


def verify_letter_reasons(providers: dict) -> None:
    """没有 path / pathRef 的条目必须写 letterReason；有官方 path 的不许留这条。"""
    missing: list[str] = []
    stale: list[str] = []
    vague: list[str] = []
    for p in providers["providers"]:
        has_path = "path" in p or "pathRef" in p
        reason = (p.get("letterReason") or "").strip()
        if has_path:
            if reason:
                stale.append(p["key"])
            continue
        if not reason:
            missing.append(p["key"])
            continue
        if not any(reason.startswith(prefix) for prefix in LETTER_REASON_PREFIXES):
            vague.append(f"{p['key']}: {reason}")
    errors: list[str] = []
    if missing:
        errors.append(
            "providers.json 字母回落缺 letterReason（"
            + ", ".join(missing)
            + "）"
        )
    if stale:
        errors.append(
            "providers.json 已有 path 却还留着 letterReason（"
            + ", ".join(stale)
            + "）"
        )
    if vague:
        errors.append(
            "providers.json letterReason 必须用既定前缀开头（条款 / 并入 / 扁字标 / 位图 / "
            "HTML / 描边 / 渐变/mask / 框架默认图标 / Simple Icons 没有）：\n  "
            + "\n  ".join(vague)
        )
    if errors:
        raise SystemExit("\n".join(errors))


def verify_provider_identity(rows: list[dict], providers: dict) -> None:
    """同一个厂商的名字只许有一处说了算。

    `shared/providers.json` 里也带 `name`（落地页和 Android 用），它必须和目录一致——
    不一致就说明有人只改了一边，构成行和落地页会开始叫两个名字。
    """
    by_key = {p["key"]: p["name"] for p in providers["providers"]}
    for row in rows:
        expected = by_key.get(row["colorKey"])
        if expected is None:
            raise SystemExit(
                f"{row['raw']}: colorKey {row['colorKey']} 不在 shared/providers.json 里"
            )
        if expected != row["name"]:
            raise SystemExit(
                f"{row['raw']}: 名字两边不一致——ProviderCatalog.swift 写 {row['name']!r}，"
                f"shared/providers.json 写 {expected!r}"
            )


def gen_swift_provider_identity(rows: list[dict]) -> str:
    lines = [
        swift_header("Packages/MeterKit/Sources/MeterProviders/ProviderCatalog.swift"),
        "",
        "import Foundation",
        "",
        doc_comment(
            [
                "厂商的身份：叫什么、什么色、属于哪一类、市占在哪一档。**只是数据，不含任何取数**。",
                "",
                "住在 MeterCore 的理由：`ProviderID` 和 `ProviderCategory` 本来就在这儿，",
                "身份和它们是同一类事实。放这儿之后，「把账本折算成模块内容」不再需要",
                "链接 MeterProviders——widget 也就够得着同一份折算了。",
                "",
                "权威是 `ProviderCatalog.swift`（连同接入分层）。改那边、跑生成器，别手改这份。",
            ]
        ),
        "public struct ProviderIdentity: Hashable, Sendable {",
        "    public let id: ProviderID",
        "    public let displayName: String",
        "    /// 品牌色和 glyph 的键。目录里和 `id.rawValue` 一致，但它是独立字段：",
        "    /// 两家合并到同一套视觉时，只有它会变。",
        "    public let colorKey: String",
        "    public let category: ProviderCategory",
        "    /// 刷这家要花钱（AWS Cost Explorer 每次约 $0.01）。全局刷新默认跳过它们。",
        "    public let costsMoneyToRefresh: Bool",
        "    /// 所属品类里的市占位置。",
        "    public let tier: ProviderTier",
        "    /// 为什么标这个档。给人读的，不进 String Catalog。",
        "    public let tierReason: String",
        "",
        "    public init(",
        "        id: ProviderID,",
        "        displayName: String,",
        "        colorKey: String,",
        "        category: ProviderCategory,",
        "        costsMoneyToRefresh: Bool,",
        "        tier: ProviderTier,",
        "        tierReason: String",
        "    ) {",
        "        self.id = id",
        "        self.displayName = displayName",
        "        self.colorKey = colorKey",
        "        self.category = category",
        "        self.costsMoneyToRefresh = costsMoneyToRefresh",
        "        self.tier = tier",
        "        self.tierReason = tierReason",
        "    }",
        "}",
        "",
        "public extension ProviderIdentity {",
        "    /// 查不到就现编一个：拿 rawValue 当名字和色键、类别归「其他」。",
        "    /// **不返回 nil** —— 调用方全是「这一行要显示什么」，没有一个能对 nil 做出更好的处理，",
        "    /// 逼它们各写一遍回落只会写出四五种不同的占位。",
        "    static func lookup(_ id: ProviderID) -> ProviderIdentity {",
        "        table[id.rawValue] ?? ProviderIdentity(",
        "            id: id,",
        "            displayName: id.rawValue,",
        "            colorKey: id.rawValue,",
        "            category: .other,",
        "            costsMoneyToRefresh: false,",
        "            tier: .three,",
        "            tierReason: \"\"",
        "        )",
        "    }",
        "",
        "    /// 目录里真有这一家才返回。用在「不认识就整行不画」的地方——",
        "    /// 那些地方回落成 rawValue 会在界面上摆出一行 `someprovider`，不如不摆。",
        "    static func known(_ id: ProviderID) -> ProviderIdentity? {",
        "        table[id.rawValue]",
        "    }",
        "",
        "    /// 只有一个 key（构成段的 provider 键、widget 的段）时用这个。",
        "    static func displayName(forKey key: String) -> String {",
        "        table[key.lowercased()]?.displayName ?? key",
        "    }",
        "",
        "    static let all: [ProviderIdentity] = [",
    ]
    for row in rows:
        name = row["name"].replace("\\", "\\\\").replace('"', '\\"')
        reason = row["tierReason"].replace("\\", "\\\\").replace('"', '\\"')
        lines.append(
            f'        ProviderIdentity(id: .{row["member"]}, displayName: "{name}",'
            f' colorKey: "{row["colorKey"]}", category: .{row["category"]},'
            f' costsMoneyToRefresh: {str(row["costsMoneyToRefresh"]).lower()},'
            f' tier: .{row["tier"]}, tierReason: "{reason}"),'
        )
    lines += [
        "    ]",
        "",
        "    private static let table: [String: ProviderIdentity] = Dictionary(",
        "        all.map { ($0.id.rawValue, $0) },",
        "        uniquingKeysWith: { first, _ in first }",
        "    )",
        "}",
    ]
    return "\n".join(lines) + "\n"


def load_app_catalog() -> dict:
    return json.loads(
        (
            ROOT / "Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json"
        ).read_text(encoding="utf-8")
    )


def gen_site_catalog_entries() -> str:
    """落地页详情 sheet：编译目录的结构化字段 + catalog.json 的文字。

    文本字段带三语列（catalog.json 的 en/ja overlay，缺列回落中文，
    与 App 的 CatalogLanguage 同一条回落规矩）。declineReason 和
    marketTierReason 源头在 ProviderCatalog.swift，没有译文，保持纯中文，
    站点英日页不展示这两句。
    """
    app = load_app_catalog()
    guides: dict = app.get("guides") or {}

    def tri(node: dict | None, key: str) -> dict | None:
        base = ((node or {}).get(key) or "").strip()
        if not base:
            return None
        en = (((node or {}).get("en") or {}).get(key) or "").strip()
        ja = (((node or {}).get("ja") or {}).get(key) or "").strip()
        return {"zh": base, "en": en or base, "ja": ja or base}

    plans_by: dict[str, list[dict]] = {}
    for plan in app.get("plans") or []:
        pid = plan.get("providerID")
        if not pid:
            continue
        plans_by.setdefault(pid, []).append(
            {
                "name": tri(plan, "name"),
                "amountUSD": plan["amountUSD"],
                "period": plan.get("period", "monthly"),
            }
        )
    notices_by: dict[str, list[dict]] = {}
    for notice in app.get("notices") or []:
        pid = notice.get("providerID")
        message = tri(notice, "message")
        if not pid or not message:
            continue
        notices_by.setdefault(pid, []).append(message)

    entries = []
    for row in parse_provider_catalog():
        guide = guides.get(row["key"]) or {}
        fields: list[dict] = []
        steps: list[dict] = []
        for part in guide.get("parts") or []:
            for field in part.get("fields") or []:
                item = {
                    "key": field.get("key", ""),
                    "label": tri(field, "label") or {"zh": "", "en": "", "ja": ""},
                    "isSecret": bool(field.get("isSecret")),
                }
                hint = tri(field, "hint")
                if hint:
                    item["hint"] = hint
                validation = field.get("validation") or {}
                message = tri(validation, "message")
                if message:
                    item["validation"] = message
                fields.append(item)
            for step in part.get("steps") or []:
                text = tri(step, "text")
                if text:
                    steps.append(text)
        troubleshooting = []
        for issue in guide.get("troubleshooting") or []:
            troubleshooting.append(
                {
                    "explanation": tri(issue, "explanation") or {"zh": "", "en": "", "ja": ""},
                    "nextStep": tri(issue, "nextStep") or {"zh": "", "en": "", "ja": ""},
                    **(
                        {"httpStatus": issue["httpStatus"]}
                        if "httpStatus" in issue
                        else {}
                    ),
                }
            )
        entry = {
            "key": row["key"],
            "name": row["name"],
            "kind": row["kind"],
            "status": row["status"],
            "inbox": row["inbox"],
            "costsMoneyToRefresh": row["costsMoneyToRefresh"],
            "supportsDailyGranularity": row["supportsDailyGranularity"],
            "historyLookbackMonths": row["historyLookbackMonths"],
            "minimumRefreshInterval": row["minimumRefreshInterval"],
            "marketTier": row["marketTier"],
            "marketTierReason": row["marketTierReason"],
            "searchKeywords": row["searchKeywords"],
            "fields": fields,
            "steps": steps,
            "troubleshooting": troubleshooting,
            "plans": plans_by.get(row["key"], []),
            "notices": notices_by.get(row["key"], []),
            "guideURLs": row["guideURLs"],
        }
        if row["declineReason"]:
            entry["declineReason"] = row["declineReason"]
        if row["billingURL"]:
            entry["billingURL"] = row["billingURL"]
        if row["credentialSetupURL"]:
            entry["credentialSetupURL"] = row["credentialSetupURL"]
        summary = tri(guide, "summary")
        if summary:
            entry["summary"] = summary
        verify_hint = tri(guide, "verifyHint")
        if verify_hint:
            entry["verifyHint"] = verify_hint
        entries.append(entry)

    payload = json.dumps(entries, ensure_ascii=False, indent=2)
    header = ts_header(
        "Packages/MeterKit/Sources/MeterProviders/ProviderCatalog.swift + Catalog/catalog.json"
    )
    return (
        header
        + "\n"
        + "export type CatalogKind = "
        + '"usage" | "prepaid" | "subscription" | "freeTier" | "planAndUsage";\n'
        + "export type CatalogStatus = "
        + '"available" | "pendingVerification" | "declined";\n'
        + "export type CatalogMarketTier = 1 | 2 | 3 | 4;\n"
        + "export type LocalizedText = { zh: string; en: string; ja: string };\n"
        + "\n"
        + "export type CatalogEntry = {\n"
        + "  key: string;\n"
        + "  name: string;\n"
        + "  kind: CatalogKind;\n"
        + "  status: CatalogStatus;\n"
        + "  inbox: boolean;\n"
        + "  costsMoneyToRefresh: boolean;\n"
        + "  supportsDailyGranularity: boolean;\n"
        + "  historyLookbackMonths: number;\n"
        + "  minimumRefreshInterval: number;\n"
        + "  marketTier: CatalogMarketTier;\n"
        + "  marketTierReason: string;\n"
        + "  searchKeywords: readonly string[];\n"
        + "  declineReason?: string;\n"
        + "  billingURL?: string;\n"
        + "  credentialSetupURL?: string;\n"
        + "  summary?: LocalizedText;\n"
        + "  verifyHint?: LocalizedText;\n"
        + "  fields: readonly {\n"
        + "    key: string;\n"
        + "    label: LocalizedText;\n"
        + "    isSecret: boolean;\n"
        + "    hint?: LocalizedText;\n"
        + "    validation?: LocalizedText;\n"
        + "  }[];\n"
        + "  steps: readonly LocalizedText[];\n"
        + "  troubleshooting: readonly {\n"
        + "    explanation: LocalizedText;\n"
        + "    nextStep: LocalizedText;\n"
        + "    httpStatus?: number;\n"
        + "  }[];\n"
        + "  plans: readonly { name: LocalizedText; amountUSD: string; period: string }[];\n"
        + "  notices: readonly LocalizedText[];\n"
        + "  guideURLs: readonly { id: string; url: string }[];\n"
        + "};\n"
        + "\n"
        + f"export const catalogEntries: readonly CatalogEntry[] = {payload};\n"
        + "\n"
        + "export const catalogByKey: Readonly<Record<string, CatalogEntry>> = "
        + "Object.fromEntries(catalogEntries.map((item) => [item.key, item]));\n"
    )


def gen_site_support_tiers(doc: dict) -> str:
    json_keys = [p["key"] for p in doc["providers"]]
    json_set = set(json_keys)
    catalog = parse_provider_catalog()
    catalog_keys = [row["key"] for row in catalog]
    catalog_set = set(catalog_keys)
    missing = json_set - catalog_set
    extra = catalog_set - json_set
    if missing or extra:
        raise SystemExit(
            "ProviderCatalog.swift 的 colorKey 和 shared/providers.json 对不上："
            f" json有目录无={sorted(missing)} 目录有json无={sorted(extra)}"
        )
    if len(catalog_keys) != len(catalog_set):
        raise SystemExit("ProviderCatalog.swift: 重复的 colorKey")

    by_key = {p["key"]: p for p in doc["providers"]}
    tiers: dict[str, list[str]] = {
        "tested": [],
        "theoretical": [],
        "inbox": [],
        "unsupported": [],
    }
    for row in catalog:
        offered = by_key[row["key"]].get("offered") is not False
        if row["status"] == "declined":
            if offered:
                raise SystemExit(f"{row['key']} 是 declined 但 providers.json 没标 offered: false")
            tiers["unsupported"].append(row["key"])
        elif row["inbox"]:
            if not offered:
                raise SystemExit(f"{row['key']} 走读数信箱，不该标 offered: false")
            tiers["inbox"].append(row["key"])
        elif row["status"] == "pendingVerification":
            if not offered:
                raise SystemExit(f"{row['key']} 是 pendingVerification 但标了 offered: false")
            tiers["theoretical"].append(row["key"])
        elif row["status"] == "available":
            if not offered:
                raise SystemExit(f"{row['key']} 是 available 但标了 offered: false")
            tiers["tested"].append(row["key"])
        else:
            raise SystemExit(f"{row['key']}: 未知 accessStatus {row['status']}")

    for key, offered in ((p["key"], p.get("offered") is not False) for p in doc["providers"]):
        if not offered and key not in tiers["unsupported"]:
            raise SystemExit(f"{key} 标了 offered: false 但目录不是 declined")

    lines = [
        ts_header("Packages/MeterKit/Sources/MeterProviders/ProviderCatalog.swift"),
        "",
        "export const supportTiers = {",
    ]
    for name, keys in tiers.items():
        inner = ", ".join(f'"{key}"' for key in keys)
        lines.append(f"  {name}: [{inner}],")
    lines.append("} as const;")
    lines.append("")
    lines.append("export type SupportTier = keyof typeof supportTiers;")
    lines.append("")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# cat.json → CatArtwork（两端全文件生成：90% 是几何数据，函数是数据的直接访问器）


def load_cat() -> dict:
    return json.loads((ROOT / "shared/cat.json").read_text(encoding="utf-8"))


def _cat_point_swift(p: list, tags: bool) -> str:
    x, y, tag = p
    literal = f"CGPoint(x: {x}, y: {y})"
    if not tags or tag == "":
        return literal
    return f"{'left' if tag == 'L' else 'right'}({literal})"


def _cat_point_kotlin(p: list, tags: bool) -> str:
    x, y, tag = p
    literal = f"Offset({x}f, {y}f)"
    if not tags or tag == "":
        return literal
    return f"{'left' if tag == 'L' else 'right'}({literal})"


def gen_swift_cat_artwork(cat: dict) -> str:
    paths = cat["paths"]
    notes = cat["layerNotes"]
    anchors = cat["anchors"]
    anchor_notes = cat["anchorNotes"]
    zzz = cat["zzz"]
    seg = cat["silhouetteSegments"]

    def note_lines(key: str) -> list[str]:
        return [f"    /// {notes[key]}"] if key in notes else []

    def single(key: str) -> list[str]:
        return note_lines(key) + [f"    static let {key} =", f'        "{paths[key]}"', ""]

    def array(key: str) -> list[str]:
        out = note_lines(key) + [f"    static let {key} = ["]
        out += [f'        "{d}",' for d in paths[key]]
        out += ["    ]", ""]
        return out

    lines = [swift_header("shared/cat.json"), "", "import SwiftUI", ""]
    lines.append("/// `docs/assets/tollcat.svg` 的图层库，内联成常量。不要在运行时读 SVG。")
    lines.append("enum CatArtwork {")
    lines.append(f"    static let viewBox: CGFloat = {cat['viewBox']}")
    for name in ("bodyCenter", "tailPivot", "leftEarPivot", "rightEarPivot"):
        if name in anchor_notes:
            lines.append(f"    /// {anchor_notes[name]}")
        x, y = anchors[name]
        lines.append(f"    static let {name} = CGPoint(x: {x}, y: {y})")
    for note in zzz["note"].split("。"):
        if note:
            lines.append(f"    /// {note}。")
    lines.append("    static let zzzMarks: [(center: CGPoint, size: CGFloat)] = [")
    for mark in zzz["marks"]:
        cx, cy = mark["center"]
        lines.append(f"        (CGPoint(x: {cx}, y: {cy}), {mark['size']}),")
    lines.append("    ]")
    lines.append("")
    lines += single("silhouette")
    lines += single("tail")
    for key in ("eyeNormal", "eyeClosed", "eyeSparkle", "eyeAlert", "eyeX"):
        lines += array(key)
    for key in ("mouthNeutral", "mouthSmile", "mouthFlat", "mouthO", "mouthSmallO", "mouthWave"):
        lines += single(key)
    lines += array("glassesLenses")
    lines += array("glassesBridgeAndArms")
    lines += single("zzz")
    lines.append(f"    static let zzzWidth: CGFloat = {zzz['width']}")
    lines.append(f"    static let zzzHeight: CGFloat = {zzz['height']}")
    lines.append("")
    lines += array("bang")
    lines += single("skullHead")
    lines += array("skullEyes")
    lines += array("bubbleDots")
    lines.append(
        """    // MARK: - 解析好的 Path

    /// 每条路径在进程里只 tokenize 一次。
    ///
    /// 之前每个图层都是一个 `Shape`，`path(in:)` 每次布局都要把五百来字符的 `d`
    /// 重新扫一遍。一只猫十几个图层、一秒几十帧，等于每秒解析上千次同样的字符串。
    /// `static let` 是惰性 + 线程安全的，正好当一次性缓存用。
    static let silhouettePath = SVGPathParser.path(from: silhouette)
    static let tailPath = SVGPathParser.path(from: tail)
    static let zzzPath = SVGPathParser.path(from: zzz)
    static let bangPaths = bang.map(SVGPathParser.path(from:))
    static let skullHeadPath = SVGPathParser.path(from: skullHead)
    static let skullEyePaths = skullEyes.map(SVGPathParser.path(from:))
    static let bubbleDotPaths = bubbleDots.map(SVGPathParser.path(from:))

    private static let eyeNormalPaths = eyeNormal.map(SVGPathParser.path(from:))
    private static let eyeClosedPaths = eyeClosed.map(SVGPathParser.path(from:))
    private static let eyeSparklePaths = eyeSparkle.map(SVGPathParser.path(from:))
    private static let eyeAlertPaths = eyeAlert.map(SVGPathParser.path(from:))
    private static let eyeXPaths = eyeX.map(SVGPathParser.path(from:))

    private static let mouthNeutralPath = SVGPathParser.path(from: mouthNeutral)
    private static let mouthSmilePath = SVGPathParser.path(from: mouthSmile)
    private static let mouthFlatPath = SVGPathParser.path(from: mouthFlat)
    private static let mouthOPath = SVGPathParser.path(from: mouthO)
    private static let mouthSmallOPath = SVGPathParser.path(from: mouthSmallO)
    private static let mouthWavePath = SVGPathParser.path(from: mouthWave)

    static let glassesLensPaths = glassesLenses.map(SVGPathParser.path(from:))
    static let glassesFramePaths = glassesBridgeAndArms.map(SVGPathParser.path(from:))

    /// 两只眼珠。眨眼只压这几条；吊眼的眉留在 `eyeMarkShapes`。
    static func eyeballShapes(for eyes: CatEyes) -> [Path] {
        switch eyes {
        case .normal:
            return eyeNormalPaths
        case .closed:
            return eyeClosedPaths
        case .sparkle:
            return eyeSparklePaths
        case .alert:
            return Array(eyeAlertPaths.prefix(2))
        case .x:
            return eyeXPaths
        }
    }

    static func eyeMarkShapes(for eyes: CatEyes) -> [Path] {
        switch eyes {
        case .alert:
            return Array(eyeAlertPaths.suffix(2))
        case .normal, .closed, .sparkle, .x:
            return []
        }
    }

    static func mouthShape(for mouth: CatMouth) -> Path? {
        switch mouth {
        case .none:
            return nil
        case .neutral:
            return mouthNeutralPath
        case .smile:
            return mouthSmilePath
        case .flat:
            return mouthFlatPath
        case .smallO:
            return mouthSmallOPath
        case .o:
            return mouthOPath
        case .wave:
            return mouthWavePath
        }
    }

    /// 仍是同一条闭合剪影。0 度就是原稿；非 0 只把耳尖和近根控制点绕耳根转。
    /// 控制点和 `silhouette` 的 `d` 是同一份数据，生成器会校验两者重组一致。
    static func silhouettePath(leftEarDegrees: Double, rightEarDegrees: Double) -> Path {
        if leftEarDegrees == 0, rightEarDegrees == 0 {
            return silhouettePath
        }
        let left: (CGPoint) -> CGPoint = {
            rotated($0, around: leftEarPivot, degrees: leftEarDegrees)
        }
        let right: (CGPoint) -> CGPoint = {
            rotated($0, around: rightEarPivot, degrees: rightEarDegrees)
        }
        var path = Path()"""
    )
    lines.append(f"        path.move(to: {_cat_point_swift(seg['start'], True)})")
    for curve in seg["curves"]:
        lines.append("        path.addCurve(")
        lines.append(f"            to: {_cat_point_swift(curve['to'], True)},")
        lines.append(f"            control1: {_cat_point_swift(curve['c1'], True)},")
        lines.append(f"            control2: {_cat_point_swift(curve['c2'], True)}")
        lines.append("        )")
    lines.append(
        """        path.closeSubpath()
        return path
    }

    /// Canvas / SwiftUI 正角度顺时针。
    private static func rotated(_ point: CGPoint, around pivot: CGPoint, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        let cosine = Foundation.cos(radians)
        let sine = Foundation.sin(radians)
        let dx = point.x - pivot.x
        let dy = point.y - pivot.y
        return CGPoint(
            x: pivot.x + dx * cosine + dy * sine,
            y: pivot.y - dx * sine + dy * cosine
        )
    }
}"""
    )
    return "\n".join(lines) + "\n"


def _screaming(name: str) -> str:
    import re

    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name).upper()


def gen_kotlin_cat_artwork(cat: dict) -> str:
    paths = cat["paths"]
    notes = cat["layerNotes"]
    anchors = cat["anchors"]
    anchor_notes = cat["anchorNotes"]
    zzz = cat["zzz"]
    seg = cat["silhouetteSegments"]

    def note_lines(key: str) -> list[str]:
        return [f"    /** {notes[key]} */"] if key in notes else []

    def single(key: str) -> list[str]:
        return note_lines(key) + [
            f"    private const val {_screaming(key)} =",
            f'        "{paths[key]}"',
            "",
        ]

    def array(key: str) -> list[str]:
        out = note_lines(key) + [f"    private val {_screaming(key)} = listOf("]
        out += [f'        "{d}",' for d in paths[key]]
        out += ["    )", ""]
        return out

    lines = [kotlin_header("shared/cat.json"), "", "package com.zhechengqi.tollcat.ui.cat", ""]
    lines.append("import androidx.compose.ui.geometry.Offset")
    lines.append("import androidx.compose.ui.graphics.Path")
    lines.append("import androidx.compose.ui.graphics.PathFillType")
    lines.append("import androidx.compose.ui.graphics.vector.PathParser")
    lines.append("import kotlin.math.cos")
    lines.append("import kotlin.math.sin")
    lines.append("")
    lines.append("/**")
    lines.append(" * `docs/assets/tollcat.svg` 的图层库，和 iOS `MeterDesign.CatArtwork` 同一份 path。")
    lines.append(" * 每条路径在进程里只 tokenize 一次（`lazy`），绘制阶段不再扫字符串。")
    lines.append(" */")
    lines.append("internal object CatArtwork {")
    lines.append(f"    const val VIEW_BOX = {cat['viewBox']}f")
    for name in ("bodyCenter", "tailPivot"):
        x, y = anchors[name]
        lines.append(f"    val {name} = Offset({x}f, {y}f)")
    for name in ("leftEarPivot", "rightEarPivot"):
        lines.append("")
        lines.append(f"    /** {anchor_notes[name]} */")
        x, y = anchors[name]
        lines.append(f"    val {name} = Offset({x}f, {y}f)")
    lines.append("")
    lines.append(f"    /** {zzz['note']} */")
    lines.append("    data class ZzzMark(val center: Offset, val size: Float)")
    lines.append("")
    lines.append("    val zzzMarks = listOf(")
    for mark in zzz["marks"]:
        cx, cy = mark["center"]
        lines.append(f"        ZzzMark(Offset({cx}f, {cy}f), {mark['size']}f),")
    lines.append("    )")
    lines.append(f"    const val ZZZ_WIDTH = {zzz['width']}f")
    lines.append(f"    const val ZZZ_HEIGHT = {zzz['height']}f")
    lines.append("")
    lines += single("silhouette")
    lines += single("tail")
    for key in ("eyeNormal", "eyeClosed", "eyeSparkle", "eyeAlert", "eyeX"):
        lines += array(key)
    for key in ("mouthNeutral", "mouthSmile", "mouthFlat", "mouthO", "mouthSmallO", "mouthWave"):
        lines += single(key)
    lines += array("glassesLenses")
    lines += array("glassesBridgeAndArms")
    lines += single("zzz")
    lines += array("bang")
    lines += single("skullHead")
    lines += array("skullEyes")
    lines += array("bubbleDots")
    lines.append(
        """    private fun parse(d: String): Path = PathParser().parsePathString(d).toPath()

    val silhouettePath: Path by lazy { parse(SILHOUETTE) }
    val tailPath: Path by lazy { parse(TAIL) }
    val zzzPath: Path by lazy { parse(ZZZ) }
    val bangPaths: List<Path> by lazy { BANG.map(::parse) }
    val skullHeadPath: Path by lazy { parse(SKULL_HEAD) }
    val skullEyePaths: List<Path> by lazy { SKULL_EYES.map(::parse) }
    val bubbleDotPaths: List<Path> by lazy { BUBBLE_DOTS.map(::parse) }

    private val eyeNormalPaths by lazy { EYE_NORMAL.map(::parse) }
    private val eyeClosedPaths by lazy { EYE_CLOSED.map(::parse) }
    private val eyeSparklePaths by lazy { EYE_SPARKLE.map(::parse) }
    private val eyeAlertPaths by lazy { EYE_ALERT.map(::parse) }
    private val eyeXPaths by lazy { EYE_X.map(::parse) }

    private val mouthNeutralPath by lazy { parse(MOUTH_NEUTRAL) }
    private val mouthSmilePath by lazy { parse(MOUTH_SMILE) }
    private val mouthFlatPath by lazy { parse(MOUTH_FLAT) }
    private val mouthOPath by lazy { parse(MOUTH_O) }
    private val mouthSmallOPath by lazy { parse(MOUTH_SMALL_O) }
    private val mouthWavePath by lazy { parse(MOUTH_WAVE) }

    val glassesLensPaths: List<Path> by lazy {
        GLASSES_LENSES.map { parse(it).apply { fillType = PathFillType.EvenOdd } }
    }
    val glassesFramePaths: List<Path> by lazy { GLASSES_BRIDGE_AND_ARMS.map(::parse) }

    /** 两只眼珠。眨眼只压这几条；吊眼的眉留在 [eyeMarkShapes]。 */
    fun eyeballShapes(eyes: CatEyes): List<Path> = when (eyes) {
        CatEyes.Normal -> eyeNormalPaths
        CatEyes.Closed -> eyeClosedPaths
        CatEyes.Sparkle -> eyeSparklePaths
        CatEyes.Alert -> eyeAlertPaths.take(2)
        CatEyes.X -> eyeXPaths
    }

    fun eyeMarkShapes(eyes: CatEyes): List<Path> = when (eyes) {
        CatEyes.Alert -> eyeAlertPaths.drop(2)
        else -> emptyList()
    }

    fun mouthShape(mouth: CatMouth): Path? = when (mouth) {
        CatMouth.None -> null
        CatMouth.Neutral -> mouthNeutralPath
        CatMouth.Smile -> mouthSmilePath
        CatMouth.Flat -> mouthFlatPath
        CatMouth.SmallO -> mouthSmallOPath
        CatMouth.O -> mouthOPath
        CatMouth.Wave -> mouthWavePath
    }

    /**
     * 仍是同一条闭合剪影。0 度就是原稿；非 0 只把耳尖和近根控制点绕耳根转。
     * 控制点和 [SILHOUETTE] 的 `d` 是同一份数据，生成器会校验两者重组一致。
     */
    fun silhouettePath(leftEarDegrees: Float, rightEarDegrees: Float): Path {
        if (leftEarDegrees == 0f && rightEarDegrees == 0f) return silhouettePath
        fun left(p: Offset) = rotated(p, leftEarPivot, leftEarDegrees)
        fun right(p: Offset) = rotated(p, rightEarPivot, rightEarDegrees)
        val path = Path()"""
    )
    start = _cat_point_kotlin(seg["start"], True)
    lines.append(f"        val start = {start}")
    lines.append("        path.moveTo(start.x, start.y)")
    for curve in seg["curves"]:
        c1 = _cat_point_kotlin(curve["c1"], True)
        c2 = _cat_point_kotlin(curve["c2"], True)
        to = _cat_point_kotlin(curve["to"], True)
        lines.append(f"        cubic(path, {c1}, {c2}, {to})")
    lines.append(
        """        path.close()
        return path
    }

    private fun cubic(path: Path, c1: Offset, c2: Offset, to: Offset) {
        path.cubicTo(c1.x, c1.y, c2.x, c2.y, to.x, to.y)
    }

    /** 和 iOS 同一套旋转，保证两端剪影逐点一致。 */
    private fun rotated(point: Offset, pivot: Offset, degrees: Float): Offset {
        val radians = degrees * Math.PI.toFloat() / 180f
        val cosine = cos(radians)
        val sine = sin(radians)
        val dx = point.x - pivot.x
        val dy = point.y - pivot.y
        return Offset(
            x = pivot.x + dx * cosine + dy * sine,
            y = pivot.y - dx * sine + dy * cosine,
        )
    }
}"""
    )
    return "\n".join(lines) + "\n"


def verify_cat(cat: dict) -> None:
    """分段控制点必须能重组出 silhouette 的 `d`，否则耳朵一动剪影就变形。"""
    import re as _re

    seg = cat["silhouetteSegments"]
    numbers = [seg["start"][0], seg["start"][1]]
    for c in seg["curves"]:
        for p in (c["c1"], c["c2"], c["to"]):
            numbers += [p[0], p[1]]
    d_numbers = [int(n) for n in _re.findall(r"-?\d+", cat["paths"]["silhouette"])]
    if numbers != d_numbers:
        raise SystemExit("cat.json: silhouetteSegments 和 paths.silhouette 重组不一致")


# ---------------------------------------------------------------------------
# jni-copy.json + Localizable.xcstrings → JNICopy.swift（编进 Android .so 的三语文案表）

XCSTRINGS_FOR_JNI = (
    "Packages/MeterKit/Sources/MeterFeatures/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterDesign/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterFormat/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterModules/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterPersistence/Resources/Localizable.xcstrings",
    "Packages/MeterKit/Sources/MeterProviders/Resources/Localizable.xcstrings",
)


def gen_jni_copy() -> str:
    wanted = json.loads((ROOT / "shared/jni-copy.json").read_text(encoding="utf-8"))["keys"]
    table: dict[str, dict[str, str]] = {}
    for relative in XCSTRINGS_FOR_JNI:
        data = json.loads((ROOT / relative).read_text(encoding="utf-8"))
        for key, entry in data.get("strings", {}).items():
            if key not in wanted or key in table:
                continue
            locs = entry.get("localizations") or {}
            values = {}
            for lang in ("en", "ja"):
                unit = (locs.get(lang) or {}).get("stringUnit") or {}
                if unit.get("value"):
                    values[lang] = unit["value"]
            if len(values) == 2:
                table[key] = values
    missing = [key for key in wanted if key not in table]
    if missing:
        raise SystemExit(
            "jni-copy.json 里的键在 xcstrings 找不到齐 en/ja："
            + "、".join(missing)
        )

    def swift_str(s: str) -> str:
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

    lines = [swift_header("shared/jni-copy.json + 各模块 Localizable.xcstrings"), ""]
    lines.append("import Foundation")
    lines.append("")
    lines.append("/// 桥出口的用户可见文案。Android / Windows 的 SwiftPM 构建不编 String Catalog，")
    lines.append("/// `String(localized:)` 会静默回落源语言，所以把需要的键连三语译文一起编进动态库。")
    lines.append("package enum JNICopy {")
    lines.append("    /// languageTag 前缀匹配；表里没有或语言对不上就回落中文源串。")
    lines.append("    static func text(_ key: String, _ localeTag: String) -> String {")
    lines.append("        guard let entry = table[key] else { return key }")
    lines.append("        if localeTag.hasPrefix(\"en\") { return entry.en }")
    lines.append("        if localeTag.hasPrefix(\"ja\") { return entry.ja }")
    lines.append("        return key")
    lines.append("    }")
    lines.append("")
    lines.append("    /// %@ / %lld（含 %1$@ 位置式）按顺序或位置替换。实参先由调用方转成字符串。")
    lines.append("    static func format(_ key: String, _ localeTag: String, _ args: String...) -> String {")
    lines.append("        let pattern = text(key, localeTag)")
    lines.append("        var result = \"\"")
    lines.append("        var next = 0")
    lines.append("        var index = pattern.startIndex")
    lines.append("        while index < pattern.endIndex {")
    lines.append("            guard pattern[index] == \"%\" else {")
    lines.append("                result.append(pattern[index])")
    lines.append("                index = pattern.index(after: index)")
    lines.append("                continue")
    lines.append("            }")
    lines.append("            var cursor = pattern.index(after: index)")
    lines.append("            if cursor < pattern.endIndex, pattern[cursor] == \"%\" {")
    lines.append("                result.append(\"%\")")
    lines.append("                index = pattern.index(after: cursor)")
    lines.append("                continue")
    lines.append("            }")
    lines.append("            var position: Int?")
    lines.append("            var digits = \"\"")
    lines.append("            while cursor < pattern.endIndex, pattern[cursor].isNumber {")
    lines.append("                digits.append(pattern[cursor])")
    lines.append("                cursor = pattern.index(after: cursor)")
    lines.append("            }")
    lines.append("            if !digits.isEmpty, cursor < pattern.endIndex, pattern[cursor] == \"$\" {")
    lines.append("                position = Int(digits)")
    lines.append("                cursor = pattern.index(after: cursor)")
    lines.append("            } else if !digits.isEmpty {")
    lines.append("                // %20 这种不是占位符，原样放回")
    lines.append("                result.append(\"%\" + digits)")
    lines.append("                index = cursor")
    lines.append("                continue")
    lines.append("            }")
    lines.append("            let rest = pattern[cursor...]")
    lines.append("            var consumed = 0")
    lines.append("            if rest.hasPrefix(\"@\") { consumed = 1 }")
    lines.append("            else if rest.hasPrefix(\"lld\") { consumed = 3 }")
    lines.append("            else if rest.hasPrefix(\"ld\") { consumed = 2 }")
    lines.append("            else if rest.hasPrefix(\"d\") { consumed = 1 }")
    lines.append("            guard consumed > 0 else {")
    lines.append("                result.append(pattern[index])")
    lines.append("                index = pattern.index(after: index)")
    lines.append("                continue")
    lines.append("            }")
    lines.append("            let argIndex = (position ?? (next + 1)) - 1")
    lines.append("            if position == nil { next += 1 }")
    lines.append("            result.append(argIndex < args.count ? args[argIndex] : \"\")")
    lines.append("            index = pattern.index(cursor, offsetBy: consumed)")
    lines.append("        }")
    lines.append("        return result")
    lines.append("    }")
    lines.append("")
    lines.append("    private struct Entry {")
    lines.append("        let en: String")
    lines.append("        let ja: String")
    lines.append("    }")
    lines.append("")
    lines.append("    private static let table: [String: Entry] = [")
    for key in wanted:
        en = swift_str(table[key]["en"])
        ja = swift_str(table[key]["ja"])
        lines.append(f"        {swift_str(key)}: Entry(en: {en}, ja: {ja}),")
    lines.append("    ]")
    lines.append("}")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# api-contract.json → worker 常量 / Swift 字段上限 / site 表单（补丁式）


def load_contract() -> dict:
    return json.loads((ROOT / "shared/api-contract.json").read_text(encoding="utf-8"))


def snake_to_camel(value: str) -> str:
    parts = value.split("_")
    return parts[0] + "".join(part.title() for part in parts[1:])


def gen_worker_contract(contract: dict) -> str:
    tip = contract["tip"]
    fb = contract["feedback"]
    usage = contract["usage"]
    lines = [ts_header("shared/api-contract.json"), ""]
    lines.append("/** 字段上限与类别枚举，和 Swift 客户端、site 表单同一份。 */")
    lines.append(f'export const TIP_NAME_MAX = {tip["nameMax"]};')
    lines.append(f'export const TIP_MESSAGE_MAX = {tip["messageMax"]};')
    lines.append(f'export const FEEDBACK_MESSAGE_MAX = {fb["messageMax"]};')
    lines.append(f'export const FEEDBACK_CONTACT_MAX = {fb["contactMax"]};')
    lines.append(f'export const FEEDBACK_PROVIDERS_MAX = {fb["providersMax"]};')
    lines.append(f'export const FEEDBACK_EXCHANGE_MAX = {fb["exchangeMax"]};')
    lines.append(f'export const FEEDBACK_VERSION_MAX = {fb["versionMax"]};')
    lines.append(f'export const FEEDBACK_LOCALE_MAX = {fb["localeMax"]};')
    lines.append(f'export const FEEDBACK_DEVICE_MAX = {fb["deviceMax"]};')
    categories = ", ".join(f'"{c}"' for c in fb["categories"])
    lines.append(f"export const FEEDBACK_CATEGORIES = new Set([{categories}]);")
    lines.append(f'export const USAGE_VERSION_MAX = {usage["versionMax"]};')
    lines.append(f'export const USAGE_SCREENS_MAX = {usage["screensMax"]};')
    lines.append(f'export const USAGE_COUNT_MAX = {usage["countMax"]};')
    platforms = ", ".join(f'"{p}"' for p in usage["platforms"])
    lines.append(f"export const USAGE_PLATFORMS = new Set([{platforms}]);")
    screens = ", ".join(f'"{s}"' for s in usage["screens"])
    lines.append(f"export const USAGE_SCREENS = new Set([{screens}]);")
    return "\n".join(lines) + "\n"


def gen_swift_usage_limits(contract: dict) -> str:
    usage = contract["usage"]
    return (
        swift_header("shared/api-contract.json")
        + f"""
import Foundation

/// 和 Worker 的常量同一份（shared/api-contract.json）。
public enum UsageFieldLimits: Sendable {{
    public static let version = {usage["versionMax"]}
    public static let screens = {usage["screensMax"]}
    public static let count = {usage["countMax"]}
}}
"""
    )


def gen_swift_usage_screens(contract: dict) -> str:
    usage = contract["usage"]
    lines = [
        swift_header("shared/api-contract.json"),
        "",
        "import Foundation",
        "",
        "/// 允许上报的页面。不在这份名单里的，客户端不发、服务端丢弃。",
        "/// 名单是产品页面，不是某家服务、不是某个账号。",
        "public enum UsageAnalyticsScreen: String, Hashable, Sendable, Codable, CaseIterable {",
    ]
    for screen in usage["screens"]:
        lines.append(f'    case {snake_to_camel(screen)} = "{screen}"')
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_kotlin_usage_screens(contract: dict) -> str:
    usage = contract["usage"]
    lines = [
        kotlin_header("shared/api-contract.json"),
        "",
        "package com.zhechengqi.tollcat",
        "",
        "/** 允许上报的页面。不在这份名单里的，客户端不发、服务端丢弃。 */",
        "object UsageScreens {",
    ]
    for screen in usage["screens"]:
        lines.append(f'    const val {screen.upper()} = "{screen}"')
    names = ",\n        ".join(screen.upper() for screen in usage["screens"])
    lines.append("")
    lines.append(f"    val all: Set<String> = setOf(\n        {names},\n    )")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def gen_csharp_usage_screens(contract: dict) -> str:
    usage = contract["usage"]
    lines = [
        csharp_header("shared/api-contract.json"),
        "",
        "namespace TollCat;",
        "",
        "/// <summary>允许上报的页面。不在这份名单里的，客户端不发、服务端丢弃。</summary>",
        "internal static class UsageScreens",
        "{",
    ]
    for screen in usage["screens"]:
        ident = "".join(part.title() for part in screen.split("_"))
        lines.append(f'    public const string {ident} = "{screen}";')
    names = ",\n        ".join(
        "".join(part.title() for part in screen.split("_")) for screen in usage["screens"]
    )
    lines.append("")
    lines.append("    public static readonly HashSet<string> All = new()")
    lines.append("    {")
    lines.append(f"        {names},")
    lines.append("    };")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def gen_csharp_usage_limits(contract: dict) -> str:
    usage = contract["usage"]
    lines = [
        csharp_header("shared/api-contract.json"),
        "",
        "namespace TollCat;",
        "",
        "/// <summary>和 Worker 的常量同一份（shared/api-contract.json）。</summary>",
        "internal static class UsageFieldLimits",
        "{",
        f"    public const int Version = {usage['versionMax']};",
        f"    public const int Screens = {usage['screensMax']};",
        f"    public const int Count = {usage['countMax']};",
        "}",
        "",
    ]
    return "\n".join(lines)


def gen_csharp_glyph_artwork(doc: dict) -> str:
    providers, _ = provider_path_map(doc)
    default_fill = doc["defaultFill"]
    even_odd = [p["key"] for p in providers if p.get("evenOdd")]
    fills = [(p["key"], p["fill"]) for p in providers if "fill" in p]

    lines = [csharp_header("shared/providers.json"), "", "namespace TollCat;", ""]
    lines.append("/// <summary>")
    for line in doc["provenance"]:
        lines.append(f"/// {line}")
    lines.append("/// </summary>")
    lines.append("internal static class ProviderGlyphArtwork")
    lines.append("{")
    lines.append("    public static float FillRatio(string colorKey) => colorKey.ToLowerInvariant() switch")
    lines.append("    {")
    for key, fill in fills:
        lines.append(f'        "{key}" => {fill}f,')
    lines.append(f"        _ => {default_fill}f,")
    lines.append("    };")
    lines.append("")
    lines.append("    public static bool UsesEvenOddFill(string colorKey) => colorKey.ToLowerInvariant() switch")
    lines.append("    {")
    if even_odd:
        cases = ", ".join(f'"{k}"' for k in even_odd)
        lines.append(f"        {cases} => true,")
    lines.append("        _ => false,")
    lines.append("    };")
    lines.append("")
    lines.append("    public static string MonogramLetter(string colorKey)")
    lines.append("    {")
    lines.append('        var key = colorKey.Trim();')
    lines.append('        return key.Length == 0 ? "?" : char.ToUpperInvariant(key[0]).ToString();')
    lines.append("    }")
    lines.append("")
    lines.append("    public static string? PathData(string colorKey) => colorKey.ToLowerInvariant() switch")
    lines.append("    {")
    for p in providers:
        if "path" in p:
            lines.append(f'        "{p["key"]}" => {_screaming(p["key"])},')
        elif "pathRef" in p:
            lines.append(f'        "{p["key"]}" => {_screaming(p["pathRef"])},')
    lines.append("        _ => null,")
    lines.append("    };")
    for p in providers:
        if "path" in p:
            lines.append("")
            lines.append(f'    private const string {_screaming(p["key"])} = "{p["path"]}";')
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def gen_csharp_palette(doc: dict) -> str:
    providers = doc["providers"]
    fb = doc["fallback"]
    lines = [csharp_header("shared/providers.json"), "", "namespace TollCat;", ""]
    lines.append("using Windows.UI;")
    lines.append("")
    lines.append("/// <summary>厂商标识色，和 iOS ProviderPalette、Android ProviderColors 同一份表。只进 glyph tile。</summary>")
    lines.append("internal static class ProviderPalette")
    lines.append("{")
    lines.append("    public static Color Of(string key, bool dark)")
    lines.append("    {")
    lines.append("        var packed = key.ToLowerInvariant() switch")
    lines.append("        {")
    for p in providers:
        lines.append(
            f'            "{p["key"]}" => dark ? 0xFF{p["dark"][1:]}u : 0xFF{p["light"][1:]}u,'
        )
    lines.append(f"            _ => dark ? 0xFF{fb['dark'][1:]}u : 0xFF{fb['light'][1:]}u,")
    lines.append("        };")
    lines.append("        return Color.FromArgb(")
    lines.append("            (byte)((packed >> 24) & 0xFF),")
    lines.append("            (byte)((packed >> 16) & 0xFF),")
    lines.append("            (byte)((packed >> 8) & 0xFF),")
    lines.append("            (byte)(packed & 0xFF));")
    lines.append("    }")
    lines.append("")
    lines.append("    public static string DisplayName(string key) => key.ToLowerInvariant() switch")
    lines.append("    {")
    for p in providers:
        name = p["name"].replace("\\", "\\\\").replace('"', '\\"')
        lines.append(f'        "{p["key"]}" => "{name}",')
    lines.append("        _ => key,")
    lines.append("    };")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def _cat_point_csharp(p: list, tags: bool) -> str:
    x, y, tag = p
    literal = f"new Vector2({x}f, {y}f)"
    if not tags or tag == "":
        return literal
    return f"{'Left' if tag == 'L' else 'Right'}({literal})"


def gen_csharp_cat_artwork(cat: dict) -> str:
    paths = cat["paths"]
    notes = cat["layerNotes"]
    anchors = cat["anchors"]
    anchor_notes = cat["anchorNotes"]
    zzz = cat["zzz"]
    seg = cat["silhouetteSegments"]

    def note_lines(key: str) -> list[str]:
        return [f"    /// <summary>{notes[key]}</summary>"] if key in notes else []

    def single(key: str) -> list[str]:
        return note_lines(key) + [
            f"    private const string {_screaming(key)} =",
            f'        "{paths[key]}";',
            "",
        ]

    def array(key: str) -> list[str]:
        out = note_lines(key) + [f"    private static readonly string[] {_screaming(key)} ="]
        out.append("    [")
        out += [f'        "{d}",' for d in paths[key]]
        out += ["    ];", ""]
        return out

    lines = [csharp_header("shared/cat.json"), "", "namespace TollCat;", ""]
    lines.append("using System.Collections.Generic;")
    lines.append("using System.Linq;")
    lines.append("using System.Numerics;")
    lines.append("using Microsoft.UI.Xaml.Media;")
    lines.append("")
    lines.append("/// <summary>")
    lines.append("/// docs/assets/tollcat.svg 的图层库，和 iOS MeterDesign.CatArtwork 同一份 path。")
    lines.append("/// 每条路径在进程里只 tokenize 一次。")
    lines.append("/// </summary>")
    lines.append("internal static class CatArtwork")
    lines.append("{")
    lines.append(f"    public const float ViewBox = {cat['viewBox']}f;")
    for name in ("bodyCenter", "tailPivot"):
        x, y = anchors[name]
        ident = name[0].upper() + name[1:]
        lines.append(f"    public static readonly Vector2 {ident} = new({x}f, {y}f);")
    for name in ("leftEarPivot", "rightEarPivot"):
        ident = name[0].upper() + name[1:]
        lines.append("")
        lines.append(f"    /// <summary>{anchor_notes[name]}</summary>")
        x, y = anchors[name]
        lines.append(f"    public static readonly Vector2 {ident} = new({x}f, {y}f);")
    lines.append("")
    lines.append(f"    /// <summary>{zzz['note']}</summary>")
    lines.append("    public readonly record struct ZzzMark(Vector2 Center, float Size);")
    lines.append("")
    lines.append("    public static readonly ZzzMark[] ZzzMarks =")
    lines.append("    [")
    for mark in zzz["marks"]:
        cx, cy = mark["center"]
        lines.append(f"        new(new Vector2({cx}f, {cy}f), {mark['size']}f),")
    lines.append("    ];")
    lines.append(f"    public const float ZzzWidth = {zzz['width']}f;")
    lines.append(f"    public const float ZzzHeight = {zzz['height']}f;")
    lines.append("")
    lines += single("silhouette")
    lines += single("tail")
    for key in ("eyeNormal", "eyeClosed", "eyeSparkle", "eyeAlert", "eyeX"):
        lines += array(key)
    for key in ("mouthNeutral", "mouthSmile", "mouthFlat", "mouthO", "mouthSmallO", "mouthWave"):
        lines += single(key)
    lines += array("glassesLenses")
    lines += array("glassesBridgeAndArms")
    lines += single("zzz")
    lines += array("bang")
    lines += single("skullHead")
    lines += array("skullEyes")
    lines += array("bubbleDots")
    lines.append(
        """    private static readonly Dictionary<string, object> Cache = new();

    private static PathGeometry Parse(string d) => SvgPathParser.Parse(d);

    private static PathGeometry Once(string key, string d)
    {
        lock (Cache)
        {
            if (Cache.TryGetValue(key, out var existing)) return (PathGeometry)existing;
            var parsed = Parse(d);
            Cache[key] = parsed;
            return parsed;
        }
    }

    private static IReadOnlyList<PathGeometry> OnceMany(string key, string[] data)
    {
        lock (Cache)
        {
            if (Cache.TryGetValue(key, out var existing)) return (IReadOnlyList<PathGeometry>)existing;
            var parsed = Array.ConvertAll(data, Parse);
            Cache[key] = parsed;
            return parsed;
        }
    }

    public static PathGeometry SilhouettePath => Once(nameof(SILHOUETTE), SILHOUETTE);
    public static PathGeometry TailPath => Once(nameof(TAIL), TAIL);
    public static PathGeometry ZzzPath => Once(nameof(ZZZ), ZZZ);
    public static IReadOnlyList<PathGeometry> BangPaths => OnceMany(nameof(BANG), BANG);
    public static PathGeometry SkullHeadPath => Once(nameof(SKULL_HEAD), SKULL_HEAD);
    public static IReadOnlyList<PathGeometry> SkullEyePaths => OnceMany(nameof(SKULL_EYES), SKULL_EYES);
    public static IReadOnlyList<PathGeometry> BubbleDotPaths => OnceMany(nameof(BUBBLE_DOTS), BUBBLE_DOTS);

    private static IReadOnlyList<PathGeometry> EyeNormalPaths => OnceMany(nameof(EYE_NORMAL), EYE_NORMAL);
    private static IReadOnlyList<PathGeometry> EyeClosedPaths => OnceMany(nameof(EYE_CLOSED), EYE_CLOSED);
    private static IReadOnlyList<PathGeometry> EyeSparklePaths => OnceMany(nameof(EYE_SPARKLE), EYE_SPARKLE);
    private static IReadOnlyList<PathGeometry> EyeAlertPaths => OnceMany(nameof(EYE_ALERT), EYE_ALERT);
    private static IReadOnlyList<PathGeometry> EyeXPaths => OnceMany(nameof(EYE_X), EYE_X);

    private static PathGeometry MouthNeutralPath => Once(nameof(MOUTH_NEUTRAL), MOUTH_NEUTRAL);
    private static PathGeometry MouthSmilePath => Once(nameof(MOUTH_SMILE), MOUTH_SMILE);
    private static PathGeometry MouthFlatPath => Once(nameof(MOUTH_FLAT), MOUTH_FLAT);
    private static PathGeometry MouthOPath => Once(nameof(MOUTH_O), MOUTH_O);
    private static PathGeometry MouthSmallOPath => Once(nameof(MOUTH_SMALL_O), MOUTH_SMALL_O);
    private static PathGeometry MouthWavePath => Once(nameof(MOUTH_WAVE), MOUTH_WAVE);

    public static IReadOnlyList<PathGeometry> GlassesLensPaths => OnceMany(nameof(GLASSES_LENSES), GLASSES_LENSES);
    public static IReadOnlyList<PathGeometry> GlassesFramePaths => OnceMany(nameof(GLASSES_BRIDGE_AND_ARMS), GLASSES_BRIDGE_AND_ARMS);

    public static IReadOnlyList<PathGeometry> EyeballShapes(CatEyes eyes) => eyes switch
    {
        CatEyes.Normal => EyeNormalPaths,
        CatEyes.Closed => EyeClosedPaths,
        CatEyes.Sparkle => EyeSparklePaths,
        CatEyes.Alert => EyeAlertPaths.Take(2).ToArray(),
        CatEyes.X => EyeXPaths,
        _ => [],
    };

    public static IReadOnlyList<PathGeometry> EyeMarkShapes(CatEyes eyes) => eyes switch
    {
        CatEyes.Alert => EyeAlertPaths.Skip(2).ToArray(),
        _ => [],
    };

    public static PathGeometry? MouthShape(CatMouth mouth) => mouth switch
    {
        CatMouth.None => null,
        CatMouth.Neutral => MouthNeutralPath,
        CatMouth.Smile => MouthSmilePath,
        CatMouth.Flat => MouthFlatPath,
        CatMouth.SmallO => MouthSmallOPath,
        CatMouth.O => MouthOPath,
        CatMouth.Wave => MouthWavePath,
        _ => null,
    };

    /// <summary>
    /// 仍是同一条闭合剪影。0 度就是原稿；非 0 只把耳尖和近根控制点绕耳根转。
    /// </summary>
    public static PathGeometry SilhouettePathAt(float leftEarDegrees, float rightEarDegrees)
    {
        if (leftEarDegrees == 0f && rightEarDegrees == 0f) return SilhouettePath;
        Vector2 Left(Vector2 p) => Rotated(p, LeftEarPivot, leftEarDegrees);
        Vector2 Right(Vector2 p) => Rotated(p, RightEarPivot, rightEarDegrees);
        var figure = new PathFigure { IsClosed = true, IsFilled = true };"""
    )
    start = _cat_point_csharp(seg["start"], True)
    lines.append(f"        var start = {start};")
    lines.append("        figure.StartPoint = new Windows.Foundation.Point(start.X, start.Y);")
    for curve in seg["curves"]:
        c1 = _cat_point_csharp(curve["c1"], True)
        c2 = _cat_point_csharp(curve["c2"], True)
        to = _cat_point_csharp(curve["to"], True)
        lines.append(f"        Cubic(figure, {c1}, {c2}, {to});")
    lines.append(
        """        var geometry = new PathGeometry();
        geometry.Figures.Add(figure);
        return geometry;
    }

    private static void Cubic(PathFigure figure, Vector2 c1, Vector2 c2, Vector2 to)
    {
        figure.Segments.Add(new BezierSegment
        {
            Point1 = new Windows.Foundation.Point(c1.X, c1.Y),
            Point2 = new Windows.Foundation.Point(c2.X, c2.Y),
            Point3 = new Windows.Foundation.Point(to.X, to.Y),
        });
    }

    /// <summary>和 iOS 同一套旋转，保证剪影逐点一致。</summary>
    private static Vector2 Rotated(Vector2 point, Vector2 pivot, float degrees)
    {
        var radians = degrees * MathF.PI / 180f;
        var cosine = MathF.Cos(radians);
        var sine = MathF.Sin(radians);
        var dx = point.X - pivot.X;
        var dy = point.Y - pivot.Y;
        return new Vector2(
            pivot.X + dx * cosine + dy * sine,
            pivot.Y - dx * sine + dy * cosine);
    }
}
"""
    )
    return "\n".join(lines) + "\n"


def gen_swift_tip_limits(contract: dict) -> str:
    tip = contract["tip"]
    return (
        swift_header("shared/api-contract.json")
        + f"""
import Foundation

/// 和 Worker 的常量同一份（shared/api-contract.json）。两边都截：
/// 客户端截是为了让用户当场看见字数，服务端截是因为客户端可以被绕过。
public enum TipFieldLimits: Sendable {{
    public static let name = {tip["nameMax"]}
    public static let message = {tip["messageMax"]}

    public static func clampName(_ raw: String?) -> String? {{
        clamp(raw, limit: name)
    }}

    public static func clampMessage(_ raw: String?) -> String? {{
        clamp(raw, limit: message)
    }}

    private static func clamp(_ raw: String?, limit: Int) -> String? {{
        guard let raw else {{ return nil }}
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {{ return nil }}
        return String(trimmed.prefix(limit))
    }}
}}
"""
    )


def gen_swift_feedback_limits(contract: dict) -> str:
    fb = contract["feedback"]
    return (
        swift_header("shared/api-contract.json")
        + f"""
import Foundation

/// 和 Worker 的常量同一份（shared/api-contract.json）。两边都截：
/// 客户端截是为了让用户当场看见字数，服务端截是因为客户端可以被绕过。
public enum FeedbackFieldLimits: Sendable {{
    public static let message = {fb["messageMax"]}
    public static let contact = {fb["contactMax"]}
    /// 服务名单拼平之后的上限。超了就整段不带——半截名单会误导诊断。
    public static let providers = {fb["providersMax"]}
    /// 测试连接的 HTTP 摘要。用户显式打开才带；超了截断，不当整段丢掉。
    public static let exchange = {fb["exchangeMax"]}

    public static func clampMessage(_ raw: String?) -> String? {{
        clamp(raw, limit: message)
    }}

    public static func clampContact(_ raw: String?) -> String? {{
        clamp(raw, limit: contact)
    }}

    public static func clampExchange(_ raw: String?) -> String? {{
        clamp(raw, limit: exchange)
    }}

    private static func clamp(_ raw: String?, limit: Int) -> String? {{
        guard let raw else {{ return nil }}
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {{ return nil }}
        return String(trimmed.prefix(limit))
    }}
}}
"""
    )


def patch_site_contact_form(contract: dict) -> str:
    """site 的表单脚本免打包直载，不能 import——类别那一行由生成器改写。"""
    import re as _re

    fb = contract["feedback"]
    path = ROOT / "site/src/scripts/contact-form.js"
    text = path.read_text(encoding="utf-8")
    categories = ", ".join(f"'{c}'" for c in fb["categories"])
    replacement = (
        f"// 类别来自 shared/api-contract.json（generate-shared.py 改写本行）。\n"
        f"const CATEGORIES = new Set([{categories}]);"
    )
    patched, count = _re.subn(
        r"(?:// 类别来自[^\n]*\n)?const CATEGORIES = new Set\(\[[^\]]*\]\);",
        replacement,
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("contact-form.js 里找不到 CATEGORIES 行")
    return patched


def patch_site_contact_view(contract: dict) -> str:
    """Contact.astro 的 maxlength 跟契约走。"""
    import re as _re

    fb = contract["feedback"]
    path = ROOT / "site/src/views/Contact.astro"
    text = path.read_text(encoding="utf-8")
    text = _re.sub(
        r'(<textarea name="message" required maxlength=")\d+(")',
        rf'\g<1>{fb["messageMax"]}\g<2>',
        text,
    )
    text = _re.sub(
        r'(<input name="contact" type="text" maxlength=")\d+(")',
        rf'\g<1>{fb["contactMax"]}\g<2>',
        text,
    )
    return text


def verify_contract(contract: dict) -> None:
    """Swift `FeedbackCategory` 的 case 必须和契约的类别一致。
    `UsageAnalyticsScreen` 由本脚本生成，outputs() 写入后下一轮 --check 对得上。
    """
    import re as _re

    swift = (ROOT / "Packages/MeterKit/Sources/MeterFeedback/FeedbackCategory.swift").read_text(
        encoding="utf-8"
    )
    cases = _re.findall(r"^\s*case (\w+)$", swift, _re.M)
    if cases != contract["feedback"]["categories"]:
        raise SystemExit(
            f"FeedbackCategory 的 case {cases} 和 api-contract 的类别"
            f" {contract['feedback']['categories']} 不一致"
        )

    # `UsageAnalyticsScreen` 是本脚本的生成物，不在这里和磁盘上那份比：那是拿生成物
    # 去校验它自己的源，而且比的是**改写之前**的内容——契约里加一个 screen 就会
    # 永久红，只能靠手改生成物解开，正好是禁令。一致性由 check_generated_shared
    # 在生成之后比，那是唯一成立的顺序。


# ---------------------------------------------------------------------------
# ui-test-ids.json → 两端 UI 冒烟锚点（iOS accessibilityIdentifier / Android testTag）


def load_ui_test_ids() -> dict:
    return json.loads((ROOT / "shared/ui-test-ids.json").read_text(encoding="utf-8"))


def _ui_test_id_swift_name(dotted: str) -> str:
    parts = dotted.split(".")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def _ui_test_id_kotlin_name(dotted: str) -> str:
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", dotted.replace(".", "_")).upper()


def gen_swift_ui_test_ids(doc: dict) -> str:
    lines = [
        swift_header("shared/ui-test-ids.json"),
        "",
        "import Foundation",
        "",
        "/// UI 冒烟测试（maestro/）的锚点。挂 `.accessibilityIdentifier`，不随语言变。",
        "/// 只有冒烟流程要点到 / 要断言的控件才有 id；不要拿它当样式或逻辑开关。",
        "///",
        "/// 住在 MeterDesign：模块视图（MeterModules）和页面（MeterFeatures）都要挂，",
        "/// 放在两边都够得着的最底层，不是因为它跟设计系统有关。",
        "public enum UITestID {",
    ]
    for dotted, note in doc["ids"].items():
        lines.append(f"    /// {note}")
        lines.append(f'    public static let {_ui_test_id_swift_name(dotted)} = "{dotted}"')
    for dotted, note in doc["prefixes"].items():
        lines.append(f"    /// {note}")
        lines.append(f"    public static func {_ui_test_id_swift_name(dotted)}(_ key: String) -> String {{")
        lines.append(f'        "{dotted}." + key')
        lines.append("    }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_kotlin_ui_test_ids(doc: dict) -> str:
    lines = [
        kotlin_header("shared/ui-test-ids.json"),
        "",
        "package com.zhechengqi.tollcat.ui",
        "",
        "/**",
        " * UI 冒烟测试（maestro/）的锚点。挂 `Modifier.testTag`，根上开了 testTagsAsResourceId，",
        " * Maestro 按 resource-id 找。不随语言变。只有冒烟流程要点到 / 要断言的控件才有 id。",
        " */",
        "object UITestId {",
    ]
    for dotted, note in doc["ids"].items():
        lines.append(f"    /** {note} */")
        lines.append(f'    const val {_ui_test_id_kotlin_name(dotted)} = "{dotted}"')
    for dotted, note in doc["prefixes"].items():
        lines.append(f"    /** {note} */")
        lines.append(f'    fun {_ui_test_id_swift_name(dotted)}(key: String): String = "{dotted}.$key"')
    lines.append("}")
    return "\n".join(lines) + "\n"


def verify_ui_test_ids(doc: dict) -> None:
    """maestro/ 里引用的每个 id 都得在表里；表里的 id 至少有一个流程在用。
    第二条是防「以后可能用」的堆积：没人点的锚点只会腐烂。
    """
    # system：平台自带的 identifier（iOS 的 BackButton 这类），流程可以点，但不生成常量。
    ids = set(doc["ids"]) | set(doc.get("system", {}))
    prefixes = tuple(doc["prefixes"])
    for dotted in list(doc["ids"]) + list(prefixes):
        if not re.fullmatch(r"[a-z][A-Za-z0-9]*(\.[a-z][A-Za-z0-9]*)+", dotted):
            raise SystemExit(f"ui-test-ids.json: {dotted} 不是 a.b 或 a.b.c 的小驼峰点号形式")
    used: set[str] = set()
    for path in sorted((ROOT / "maestro").rglob("*.yaml")):
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(r'\bid:\s*"?([A-Za-z0-9_.${}-]+)"?', text):
            ref = match.group(1)
            if "${" in ref:
                continue
            if ref in ids:
                used.add(ref)
                continue
            prefix = next((p for p in prefixes if ref.startswith(p + ".")), None)
            if prefix is None:
                raise SystemExit(
                    f"{path.relative_to(ROOT)}: id {ref} 不在 shared/ui-test-ids.json 里。"
                    " 先登记再用，两端才会一起打上这个锚点。"
                )
            used.add(prefix)
    unused = sorted((ids | set(prefixes)) - used)
    if unused:
        raise SystemExit(
            "shared/ui-test-ids.json 里这些 id 没有任何 maestro 流程引用，删掉或写流程：\n  "
            + "\n  ".join(unused)
        )


# ---------------------------------------------------------------------------
# module-size.json → 仪表盘模块的宽度档（模块视图在各壳里共用一套 View）


def load_module_size() -> dict:
    return json.loads((ROOT / "shared/module-size.json").read_text(encoding="utf-8"))


def verify_module_size(doc: dict) -> None:
    for axis, key in (("widths", "minWidth"), ("heights", "minHeight")):
        buckets = doc[axis]
        if len(buckets) < 2:
            raise SystemExit(f"module-size.json: {axis} 至少要两档，不然这根轴没有意义")
        if buckets[0][key] != 0:
            raise SystemExit(f"module-size.json: {axis} 第一档的 {key} 必须是 0（兜底档）")
        names: set[str] = set()
        previous = -1
        for bucket in buckets:
            name = bucket["name"]
            if not re.fullmatch(r"[a-z][A-Za-z0-9]*", name):
                raise SystemExit(f"module-size.json: {axis} 的 {name} 不是小驼峰")
            if name in names:
                raise SystemExit(f"module-size.json: {axis} 的档名 {name} 重复")
            names.add(name)
            value = bucket[key]
            if not isinstance(value, int) or value <= previous:
                raise SystemExit(f"module-size.json: {axis}.{name} 的 {key} 要是严格递增的整数")
            previous = value
            if not bucket.get("note"):
                raise SystemExit(
                    f"module-size.json: {axis}.{name} 少了 note——档位没有判据就会被乱用"
                )


def gen_swift_module_size(doc: dict) -> str:
    lines = [
        swift_header("shared/module-size.json"),
        "",
        "import CoreGraphics",
        "",
        doc_comment(
            [
                "模块的**宽度**档：横向能排下什么。",
                "",
                "和高度档（`ModuleHeight`）、容器档（`ModuleContainer`）是三根正交的轴，",
                "一起决定同一个模块视图在 iPhone 列表 / bento 卡 / 侧栏 / widget / 分享卡里的版式。",
                "",
                "档位由**容器**声明（`meterModuleStyle(width:height:container:)`），模块只读不量：",
                "量自身尺寸再回填是布局反馈环，会转死主线程。",
                "",
                "档位是提示不是义务。没做某一档版式的模块按就近的下一档画，",
                "所以判断一律写成 `width >= .wide` 这种区间比较，不要穷举 switch。",
            ]
        ),
        "public enum ModuleWidth: Int, CaseIterable, Comparable, Sendable {",
    ]
    for index, bucket in enumerate(doc["widths"]):
        lines.append(f"    /// {bucket['note']}")
        for line in _surface_doc(bucket):
            lines.append(line)
        lines.append(f"    case {bucket['name']} = {index}")
    lines += [
        "",
        "    /// 这一档从多宽起算。量的是模块拿到的内容宽，容器的内边距已经扣掉。",
        "    public var minContentWidth: CGFloat {",
        "        switch self {",
    ]
    for bucket in doc["widths"]:
        lines.append(f"        case .{bucket['name']}: {bucket['minWidth']}")
    lines += [
        "        }",
        "    }",
        "",
        "    /// 一个内容宽落在哪一档。容器算好宽度调这里，别在模块里调。",
        "    public static func bucket(forContentWidth width: CGFloat) -> ModuleWidth {",
        f"        allCases.last {{ width >= $0.minContentWidth }} ?? .{doc['widths'][0]['name']}",
        "    }",
        "",
        "    public static func < (lhs: ModuleWidth, rhs: ModuleWidth) -> Bool {",
        "        lhs.rawValue < rhs.rawValue",
        "    }",
        "}",
        "",
        doc_comment(
            [
                "模块的**高度**档：纵向预算。起头那个大数字要不要、图表多大、列表列几行。",
                "",
                "为什么高度必须单独成一根轴：widget 的 systemMedium 和 systemLarge 内容宽一样",
                "（都约 300），高度差 2.5 倍——宽度轴分不开它俩，容器档两个又都是 `.snapshot`。",
                "",
                "`.unbounded` 不是「很高」，是「没有上限」：手机 List 的行想多高就多高，",
                "所以它反过来是**不走卡版式**的那一档——圆环用整只、列表列全部。",
            ]
        ),
        "public enum ModuleHeight: Int, CaseIterable, Comparable, Sendable {",
    ]
    for index, bucket in enumerate(doc["heights"]):
        lines.append(f"    /// {bucket['note']}")
        for line in _surface_doc(bucket):
            lines.append(line)
        lines.append(f"    case {bucket['name']} = {index}")
    unbounded_index = len(doc["heights"])
    lines += [
        "    /// 高度不封顶：手机 `List` 的行。内容有多长就多长，没人裁。",
        f"    case unbounded = {unbounded_index}",
        "",
        "    /// 这一档从多高起算。`unbounded` 没有数值。",
        "    public var minContentHeight: CGFloat? {",
        "        switch self {",
    ]
    for bucket in doc["heights"]:
        lines.append(f"        case .{bucket['name']}: {bucket['minHeight']}")
    lines += [
        "        case .unbounded: nil",
        "        }",
        "    }",
        "",
        "    /// 走卡版式吗：起头一个大数字（定高卡靠它对齐第一行）、图表小一号、列表只列前几行。",
        "    /// 只有不封顶的那一档不走——它是模块的老家，手机列表。",
        "    public var prefersCardMetrics: Bool { self != .unbounded }",
        "",
        "    /// 一个内容高落在哪一档。容器算好高度调这里，别在模块里调。",
        "    public static func bucket(forContentHeight height: CGFloat) -> ModuleHeight {",
        "        allCases",
        "            .compactMap { bucket in bucket.minContentHeight.map { ($0, bucket) } }",
        f"            .last {{ height >= $0.0 }}?.1 ?? .{doc['heights'][0]['name']}",
        "    }",
        "",
        "    public static func < (lhs: ModuleHeight, rhs: ModuleHeight) -> Bool {",
        "        lhs.rawValue < rhs.rawValue",
        "    }",
        "}",
    ]
    return "\n".join(lines) + "\n"


def _surface_doc(bucket: dict) -> list[str]:
    surfaces = bucket.get("surfaces") or []
    if not surfaces:
        return []
    lines = ["    ///", "    /// 出现在："]
    lines += [f"    /// - {surface}" for surface in surfaces]
    return lines


# ---------------------------------------------------------------------------
# widgets.json → 哪些模块有小组件、各自几种尺寸（模块侧的表 + widget 侧的 bundle）

WIDGET_SIZES = ("small", "medium", "large")
# 手机和 iPad 的一格不一样大，各列一份。
WIDGET_IDIOMS = ("phone", "pad")


def load_widgets() -> dict:
    return json.loads((ROOT / "shared/widgets.json").read_text(encoding="utf-8"))


def dashboard_module_ids() -> list[str]:
    path = ROOT / "Packages/MeterKit/Sources/MeterModules/DashboardModuleID.swift"
    ids = re.findall(r"^    case (\w+)$", path.read_text(encoding="utf-8"), re.M)
    if len(ids) < 5:
        raise SystemExit(f"DashboardModuleID.swift: 只解析到 {len(ids)} 块模块，像是解析坏了")
    return ids


def verify_widgets(doc: dict) -> None:
    listed = [m["id"] for m in doc["modules"]]
    if len(listed) != len(set(listed)):
        raise SystemExit("widgets.json: 有重复的模块 id")
    actual = dashboard_module_ids()
    missing = [i for i in actual if i not in listed]
    extra = [i for i in listed if i not in actual]
    if missing:
        raise SystemExit(
            "widgets.json 少了这几块模块：" + "、".join(missing)
            + "。每块都要表态，没有小组件的写 \"sizes\": []"
        )
    if extra:
        raise SystemExit("widgets.json 里这几个 id 不是模块：" + "、".join(extra))
    for module in doc["modules"]:
        for size in module["sizes"]:
            if size not in WIDGET_SIZES:
                raise SystemExit(f"widgets.json: {module['id']} 的尺寸 {size} 不认识")
        if len(module["sizes"]) != len(set(module["sizes"])):
            raise SystemExit(f"widgets.json: {module['id']} 的尺寸有重复")
        if not module.get("note"):
            raise SystemExit(f"widgets.json: {module['id']} 少了 note——为什么给/不给这几档要写下来")
        if not isinstance(module.get("showsTitle", True), bool):
            raise SystemExit(f"widgets.json: {module['id']} 的 showsTitle 要是 true / false")
    frames = doc.get("frames") or {}
    for idiom in WIDGET_IDIOMS:
        table = frames.get(idiom)
        if not isinstance(table, dict):
            raise SystemExit(f"widgets.json: frames 少了 {idiom} 这一档（手机和 iPad 不是同一组数）")
        for size in WIDGET_SIZES:
            box = table.get(size)
            if not (
                isinstance(box, list) and len(box) == 2 and all(isinstance(n, int) for n in box)
            ):
                raise SystemExit(
                    f"widgets.json: frames.{idiom} 少了 {size} 的 [宽, 高]（整数 pt）"
                )
    for key in ("contentMargin", "cornerRadius"):
        if not isinstance(frames.get(key), int):
            raise SystemExit(f"widgets.json: frames.{key} 要是整数 pt")
    for idiom in WIDGET_IDIOMS:
        for size in WIDGET_SIZES:
            w, h = frames[idiom][size]
            if min(w, h) <= 2 * frames["contentMargin"]:
                raise SystemExit(
                    f"widgets.json: frames.{idiom}.{size} 扣掉两倍内容边距就没了"
                )


def gen_swift_module_widget_sizes(doc: dict) -> str:
    lines = [
        swift_header("shared/widgets.json"),
        "",
        "import CoreGraphics",
        "",
        doc_comment(
            [
                "小组件的尺寸。和 WidgetKit 的 `WidgetFamily` 一一对应，但**不是它**：",
                "MeterModules 不链 WidgetKit——模块这一层不该认识宿主框架。",
                "映射在 widget 壳里做（`TollCatWidgetBundle.swift`，生成物）。",
            ]
        ),
        "public enum ModuleWidgetSize: String, CaseIterable, Sendable {",
        "    /// 2×2。窄且矮：一个数加一行小字就满了。",
        "    case small",
        "    /// 4×2。比 small 宽，但一样矮。",
        "    case medium",
        "    /// 4×4。和 medium 一样宽，高 2 倍多。",
        "    case large",
        "}",
        "",
        "public extension DashboardModuleID {",
        doc_comment(
            [
                "这块模块提供哪几种小组件尺寸。空 = 主屏上没有它。",
                "",
                "判据是**装不装得下**，不是重不重要：给一个装不下的尺寸，",
                "用户拿到的是被裁掉半行的东西，比没有更糟。理由写在 `shared/widgets.json`。",
            ],
            prefix="    /// ",
        ),
        "    var widgetSizes: [ModuleWidgetSize] {",
        "        switch self {",
    ]
    for module in doc["modules"]:
        sizes = ", ".join(f".{size}" for size in module["sizes"])
        lines.append(f"        case .{module['id']}: [{sizes}]")
    lines += [
        "        }",
        "    }",
        "",
        "    /// 主屏上有没有它。",
        "    var hasWidget: Bool { !widgetSizes.isEmpty }",
        "",
        "    /// widget 里要不要在左上角写模块名。",
        "    /// 自己带标题、或者一眼就认得出的（圆环、格子图）不写——那行字只是把内容往下挤。",
        "    var widgetShowsTitle: Bool {",
        "        switch self {",
    ]
    for module in doc["modules"]:
        shows = "true" if module.get("showsTitle", True) else "false"
        lines.append(f"        case .{module['id']}: {shows}")
    lines += [
        "        }",
        "    }",
        "",
        "    /// 有小组件的模块，按版式顺序。图库里就是这几行。",
        "    static var widgetModules: [DashboardModuleID] { defaultOrder.filter(\\.hasWidget) }",
        "}",
        "",
        doc_comment(
            [
                "一格小组件长在哪种机器上。**手机和 iPad 的一格不一样大**，",
                "iPad 的 4×4 还是正方的——同一块模块在两边会落到不同的高度档。",
            ]
        ),
        "public enum ModuleWidgetIdiom: String, CaseIterable, Sendable {",
        "    /// 6.9\" iPhone。",
        "    case phone",
        "    /// 11\" iPad Pro。",
        "    case pad",
        "}",
        "",
        "public extension ModuleWidgetSize {",
        doc_comment(
            [
                "一格在主屏上占多大（pt）。数在 `shared/widgets.json` 的 frames 里，",
                "商店宣传图的主屏 mock-up 读的是同一份——图上那一格和用户装到主屏上的",
                "那一格必须是同一个尺寸。",
            ],
            prefix="    /// ",
        ),
        "    func frameSize(_ idiom: ModuleWidgetIdiom) -> CGSize {",
        "        switch (idiom, self) {",
    ]
    for idiom in WIDGET_IDIOMS:
        for size in WIDGET_SIZES:
            w, h = doc["frames"][idiom][size]
            lines.append(
                f"        case (.{idiom}, .{size}): CGSize(width: {w}, height: {h})"
            )
    lines += [
        "        }",
        "    }",
        "",
        "    /// WidgetKit 默认给内容留的边距。",
        f"    static let contentMargin: CGFloat = {doc['frames']['contentMargin']}",
        "",
        "    /// 主屏上那一格的圆角。渲图时用不到——底材是 mock-up 那一层画的。",
        f"    static let cornerRadius: CGFloat = {doc['frames']['cornerRadius']}",
        "",
        "    /// 模块实际拿到的那块地方：`frameSize` 扣掉两边内容边距。",
        "    func contentSize(_ idiom: ModuleWidgetIdiom) -> CGSize {",
        "        let frame = frameSize(idiom)",
        "        return CGSize(",
        "            width: frame.width - 2 * Self.contentMargin,",
        "            height: frame.height - 2 * Self.contentMargin",
        "        )",
        "    }",
        "}",
    ]
    return "\n".join(lines) + "\n"


def gen_swift_widget_bundle(doc: dict) -> str:
    with_widgets = [m for m in doc["modules"] if m["sizes"]]
    lines = [
        swift_header("shared/widgets.json"),
        "",
        "import SwiftUI",
        "import WidgetKit",
        "import MeterModules",
        "",
        doc_comment(
            [
                "一块模块一个 widget kind：图库里一行一块，能搜到名字，加完就是那一块。",
                "",
                "这份是**生成物**。手写的话，加一块模块就会安静地缺席主屏——",
                "没有编译错误、没有测试红，只有用户发现不了。所以清单只有一份：",
                "`shared/widgets.json`，生成器核对它和 `DashboardModuleID` 完全对齐。",
                "",
                "画什么一律走 `DashboardModuleFactory`，这里只负责登记和声明尺寸。",
            ]
        ),
        "@main",
        "struct TollCatWidgetBundle: WidgetBundle {",
        "    var body: some Widget {",
    ]
    for module in with_widgets:
        lines.append(f"        {module['id'][0].upper()}{module['id'][1:]}Widget()")
    lines += [
        "    }",
        "}",
    ]
    for module in with_widgets:
        name = f"{module['id'][0].upper()}{module['id'][1:]}Widget"
        families = ", ".join(f".system{size.capitalize()}" for size in module["sizes"])
        lines += [
            "",
            f"/// {module['note']}",
            f"struct {name}: Widget {{",
            f"    private let module = DashboardModuleID.{module['id']}",
            "",
            "    var body: some WidgetConfiguration {",
            "        StaticConfiguration(",
            f'            kind: "TollCatWidget.{module["id"]}",',
            f"            provider: ModuleTimelineProvider(module: .{module['id']})",
            "        ) { entry in",
            "            TollCatWidgetView(entry: entry)",
            "        }",
            "        .configurationDisplayName(module.title)",
            "        .description(module.summary)",
            f"        .supportedFamilies([{families}])",
            "        .containerBackgroundRemovable()",
            "    }",
            "}",
        ]
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# version.json → 各端的用户可见版本号（补丁式：只改那一个值，文件其余部分是各端自己的）


def load_version() -> str:
    doc = json.loads((ROOT / "shared/version.json").read_text(encoding="utf-8"))
    version = doc["version"]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise SystemExit(f"version.json: {version} 不是 X.Y.Z")
    return version


def _patch_one(path: Path, pattern: str, replacement: str, expect: int, label: str) -> str:
    text = path.read_text(encoding="utf-8")
    patched, count = re.subn(pattern, replacement, text, flags=re.M)
    if count != expect:
        raise SystemExit(f"{path.relative_to(ROOT)}: 期望改 {expect} 处{label}，实际 {count} 处")
    return patched


def patch_project_yml_version(version: str) -> str:
    # 两份 spec（iOS / Mac）共用的那一半才有 MARKETING_VERSION，只此一处。
    return _patch_one(
        ROOT / "project-common.yml",
        r'^( *MARKETING_VERSION: *")[^"]+(")',
        rf"\g<1>{version}\g<2>",
        1,
        " MARKETING_VERSION",
    )


def patch_gradle_version(version: str) -> str:
    return _patch_one(
        ROOT / "Android/app/build.gradle.kts",
        r'^( *versionName *= *")[^"]+(")',
        rf"\g<1>{version}\g<2>",
        1,
        " versionName",
    )


def patch_csproj_version(version: str) -> str:
    return _patch_one(
        ROOT / "Windows/app/TollCat.csproj",
        r"(<Version>)[^<]+(</Version>)",
        rf"\g<1>{version}\g<2>",
        1,
        " <Version>",
    )


def patch_appxmanifest_version(version: str) -> str:
    # MSIX 是四段，第四段给 CI 的 run number；仓库里钉 0。
    return _patch_one(
        ROOT / "Windows/app/Package.appxmanifest",
        r'(<Identity\b[^>]*?\bVersion=")[^"]+(")',
        rf"\g<1>{version}.0\g<2>",
        1,
        " Identity Version",
    )


def patch_appinstaller_version(version: str) -> str:
    # 只改 <MainPackage> 那一处；<AppInstaller Version> 是清单自己的版本，跟包版本同步走。
    return _patch_one(
        ROOT / "Windows/app/Packaging/TollCat.appinstaller",
        r'(<(?:AppInstaller|MainPackage)\b[^>]*?\bVersion=")[^"]+(")',
        rf"\g<1>{version}.0\g<2>",
        2,
        " AppInstaller/MainPackage Version",
    )


def patch_winget_version(version: str) -> str:
    return _patch_one(
        ROOT / "Windows/winget/com.zhechengqi.tollcat.yaml",
        r"^(PackageVersion: *)\S+",
        rf"\g<1>{version}",
        3,
        " PackageVersion",
    )


# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# changelog.json → 落地页 / 三端三语表 / Sparkle 说明 / 商店文案 / Release body
#
# 为什么是编译期而不是下发：更新说明描述的是**正在跑的这个二进制**，打 tag 那一刻
# 就全部已知；而抽屉在「更新后第一次冷启动」弹，那一刻缓存里按定义没有这条。
# 目录（catalog.json）走远程是因为教程会过期，那是关于外部世界的事实，不一样。

CHANGELOG_SOURCE = "shared/changelog.json"
CHANGELOG_PLATFORMS = ("ios", "mac", "android", "windows")
CHANGELOG_LANGS = ("zh", "en", "ja")
CHANGELOG_ID_RE = re.compile(r"[a-z][A-Za-z0-9]*")
CHANGELOG_SHOT_RE = re.compile(r"[a-z][a-z0-9-]*")
CHANGELOG_MAX_ITEMS = 5
# 两个商店的硬上限。超了要在闸上红，不要等上传被拒。
PLAY_WHATSNEW_LIMIT = 500
ASC_WHATSNEW_LIMIT = 4000

# 厂名不进 catalog。ios 那一班车是 iPhone 和 iPad 同一份。
CHANGELOG_PLATFORM_NAMES = {
    "ios": "iPhone · iPad",
    "mac": "Mac",
    "android": "Android",
    "windows": "Windows",
}

# shot 位图铺到哪儿。键是 <name> 和 <theme> 的模板。
CHANGELOG_SHOT_TARGETS = (
    "Packages/MeterKit/Sources/MeterFeatures/Resources/WhatsNew/{name}-{theme}@3x.png",
    "Android/app/src/main/res/drawable-nodpi/whats_new_{snake}_{theme}.png",
    "site/src/assets/whatsnew/{name}-{theme}@3x.png",
)


def load_changelog() -> dict:
    return json.loads((ROOT / CHANGELOG_SOURCE).read_text(encoding="utf-8"))


def parse_material_symbols() -> list[str]:
    """`MaterialSymbol` 的 case 名就是 `symbol.android` 的合法取值。

    Compose 没有「按名字查图标」这回事（那要反射），所以 Android 侧只能认这张
    图标字体表里已有的名字。写错了要在这里红，不能等到那一条在手机上没有图标。
    SF Symbol 名没法离线校验，`symbol.ios` 只能靠 review。
    """
    path = (
        ROOT
        / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/ui/symbols/MaterialSymbol.kt"
    )
    if not path.is_file():
        return []
    body = path.read_text(encoding="utf-8").split("enum class MaterialSymbol", 1)[-1]
    return re.findall(r"^ {4}([A-Z][A-Za-z0-9]*)\(", body, re.MULTILINE)


def parse_cat_moods() -> list[str]:
    """`CatMood` 的 case 就是 `hero.mood` 的合法取值。硬编码一份会漂。"""
    text = (ROOT / "Packages/MeterKit/Sources/MeterDesign/CatMood.swift").read_text(
        encoding="utf-8"
    )
    body = text.split("public enum CatMood", 1)[-1].split("public var", 1)[0]
    moods = re.findall(r"^ {4}case ([a-z][A-Za-z0-9]*)$", body, re.MULTILINE)
    if not moods:
        raise SystemExit("changelog: 没能从 CatMood.swift 解出情绪列表")
    return moods


def changelog_text(node: dict, key: str, lang: str) -> str:
    """中文是规范字段，en / ja 是就地 overlay，缺列回落中文（闸要求列齐）。"""
    base = (node.get(key) or "").strip()
    if lang == "zh":
        return base
    return ((node.get(lang) or {}).get(key) or "").strip() or base


def changelog_overlay_gap(node: dict, key: str, lang: str) -> str | None:
    """校验用的严格版：overlay 必须**写了**，不是「解析得出中文」。

    `changelog_text` 缺列回落中文是运行时的健壮性，不是翻译完成标准——
    只用它检查会让漏译静默通过（en / ja 的界面上出现中文），这道闸就白设了。
    """
    base = (node.get(key) or "").strip()
    if not base:
        return "中文是空的"
    if lang == "zh":
        return None
    value = ((node.get(lang) or {}).get(key) or "").strip()
    if not value:
        return f"{lang} 没写"
    if value == base:
        return f"{lang} 和中文逐字相同，像是没译"
    return None


def changelog_shows_drawer(entry: dict) -> bool:
    """缺省按 RELEASE.md 那条班次定义：X.Y.0 是一班车（弹），X.Y.Z 是热修复（不弹）。"""
    if "drawer" in entry:
        return bool(entry["drawer"])
    return entry["version"].split(".")[2] == "0"


def changelog_ordered_platforms(entry: dict) -> list[str]:
    return [name for name in CHANGELOG_PLATFORMS if name in entry["platforms"]]


def _changelog_strings(node) -> list[str]:
    if isinstance(node, dict):
        return [s for value in node.values() for s in _changelog_strings(value)]
    if isinstance(node, list):
        return [s for value in node for s in _changelog_strings(value)]
    return [node] if isinstance(node, str) else []


def render_store_notes(entry: dict, lang: str) -> str:
    """App Store Connect 的「此版本新增内容」。标题一行，每条标题 + 正文。"""
    lines = [changelog_text(entry, "title", lang), ""]
    for item in entry["items"]:
        lines.append(f"· {changelog_text(item, 'title', lang)}")
        lines.append(f"  {changelog_text(item, 'body', lang)}")
    return "\n".join(lines).rstrip() + "\n"


def render_play_whatsnew(entry: dict, lang: str) -> str:
    """Play 只给 500 字，正文放不下，只列标题。"""
    lines = [changelog_text(entry, "title", lang), ""]
    for item in entry["items"]:
        lines.append(f"· {changelog_text(item, 'title', lang)}")
    return "\n".join(lines).rstrip() + "\n"


def render_appcast_notes(entry: dict, lang: str) -> str:
    """Sparkle `<description>` 的正文。是片段不是整页——Sparkle 塞进它自己的 WebView。"""

    def esc(text: str) -> str:
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    lines = [
        "<!-- GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。 -->",
        '<div style="font: -apple-system-body; -webkit-text-size-adjust: none">',
        f'  <h2 style="margin:0 0 .5em">{esc(changelog_text(entry, "title", lang))}</h2>',
        '  <ul style="margin:0; padding-left:1.2em">',
    ]
    for item in entry["items"]:
        title = esc(changelog_text(item, "title", lang))
        body = esc(changelog_text(item, "body", lang))
        lines.append(f"    <li><b>{title}</b><br>{body}</li>")
    lines += ["  </ul>", "</div>", ""]
    return "\n".join(lines)


def render_release_notes_md(entry: dict) -> str:
    """GitHub Release body 的开头。release.yml 把它拼在构建溯源那段前面。"""
    lines: list[str] = []
    for lang in ("zh", "en"):
        lines += [f"### {changelog_text(entry, 'title', lang)}", ""]
        for item in entry["items"]:
            lines.append(
                f"- **{changelog_text(item, 'title', lang)}** — "
                f"{changelog_text(item, 'body', lang)}"
            )
        lines.append("")
    platforms = " · ".join(CHANGELOG_PLATFORM_NAMES[p] for p in changelog_ordered_platforms(entry))
    lines += [f"Shipping to: {platforms}", ""]
    return "\n".join(lines)


def changelog_shot_paths(name: str, theme: str) -> list[Path]:
    snake = name.replace("-", "_")
    return [
        ROOT / template.format(name=name, theme=theme, snake=snake)
        for template in CHANGELOG_SHOT_TARGETS
    ]


def verify_changelog(doc: dict, providers: dict) -> None:
    if doc.get("schemaVersion") != 1:
        raise SystemExit("changelog.json: schemaVersion 只支持 1")
    entries = doc.get("entries")
    if not isinstance(entries, list):
        raise SystemExit("changelog.json: entries 要是数组")
    if not entries:
        # 还没发过正式版。铺出去的商店 / Sparkle / Release 文案也就不该存在。
        for path in changelog_current_outputs_paths():
            if path.is_file():
                raise SystemExit(
                    f"changelog.json: entries 是空的，但 {path.relative_to(ROOT)} 还在。删掉它。"
                )
        return

    version = load_version()
    if entries[0].get("version") != version:
        raise SystemExit(
            f"changelog.json: 第一条是 {entries[0].get('version')!r}，"
            f"shared/version.json 是 {version}。发版那次提交要把两处一起改。"
        )

    provider_keys = {row["key"] for row in providers["providers"]}
    moods = set(parse_cat_moods())
    material_symbols = set(parse_material_symbols())
    seen_versions: set[str] = set()
    seen_ids: set[str] = set()
    previous: tuple[int, ...] | None = None

    for index, entry in enumerate(entries):
        at = f"changelog.json entries[{index}]"
        raw = entry.get("version") or ""
        if not re.fullmatch(r"\d+\.\d+\.\d+", raw):
            raise SystemExit(f"{at}: version {raw!r} 不是 X.Y.Z")
        if raw in seen_versions:
            raise SystemExit(f"{at}: version {raw} 重复")
        seen_versions.add(raw)
        parts = tuple(int(p) for p in raw.split("."))
        if previous is not None and parts >= previous:
            older = ".".join(str(p) for p in previous)
            raise SystemExit(f"{at}: 必须新的在上，{raw} 不该排在 {older} 前面")
        previous = parts

        if entry.get("date") is not None and not re.fullmatch(
            r"\d{4}-\d{2}-\d{2}", str(entry["date"])
        ):
            raise SystemExit(f"{at}: date 要是 YYYY-MM-DD。没上架就省略这个键，页面不编造日期")

        platforms = entry.get("platforms")
        if not isinstance(platforms, list) or not platforms:
            raise SystemExit(f"{at}: platforms 至少写一个端")
        if len(set(platforms)) != len(platforms):
            raise SystemExit(f"{at}: platforms 有重复")
        for name in platforms:
            if name not in CHANGELOG_PLATFORMS:
                raise SystemExit(
                    f"{at}: platforms 里的 {name!r} 不是 {' / '.join(CHANGELOG_PLATFORMS)}"
                )

        if "drawer" in entry and not isinstance(entry["drawer"], bool):
            raise SystemExit(f"{at}: drawer 要是 true / false")

        for lang in CHANGELOG_LANGS:
            if gap := changelog_overlay_gap(entry, "title", lang):
                raise SystemExit(f"{at}: title 的 {gap}")

        items = entry.get("items")
        if not isinstance(items, list) or not items:
            raise SystemExit(f"{at}: items 不能空")
        if len(items) > CHANGELOG_MAX_ITEMS:
            raise SystemExit(
                f"{at}: items 最多 {CHANGELOG_MAX_ITEMS} 条。"
                f"第 {CHANGELOG_MAX_ITEMS + 1} 条没人读，Play 的 500 字上限也会先炸"
            )
        for j, item in enumerate(items):
            spot = f"{at}.items[{j}]"
            ident = item.get("id") or ""
            if not CHANGELOG_ID_RE.fullmatch(ident):
                raise SystemExit(f"{spot}: id {ident!r} 要是小驼峰")
            if ident in seen_ids:
                raise SystemExit(
                    f"{spot}: id {ident} 和别处重复。"
                    "id 是以后远程文本 overlay 的钥匙，必须全文件唯一"
                )
            seen_ids.add(ident)
            for key in ("title", "body"):
                for lang in CHANGELOG_LANGS:
                    if gap := changelog_overlay_gap(item, key, lang):
                        raise SystemExit(f"{spot}: {key} 的 {gap}")
            symbol = item.get("symbol")
            if symbol is not None:
                if not isinstance(symbol, dict) or not symbol:
                    raise SystemExit(f"{spot}: symbol 要是 {{ios / android / windows: 名字}}")
                for key, value in symbol.items():
                    if key not in ("ios", "android", "windows"):
                        raise SystemExit(f"{spot}: symbol 里没有 {key!r} 这个端")
                    if not isinstance(value, str) or not value.strip():
                        raise SystemExit(f"{spot}: symbol.{key} 是空的")
                if "android" in symbol and material_symbols:
                    if symbol["android"] not in material_symbols:
                        raise SystemExit(
                            f"{spot}: symbol.android {symbol['android']!r} 不在 MaterialSymbol 里。"
                            "Compose 不能按名字查图标，只能用那张表里已有的 case 名"
                        )

        hero = entry.get("hero")
        if hero is not None:
            kind = hero.get("kind")
            if kind == "cat":
                if hero.get("mood") not in moods:
                    raise SystemExit(
                        f"{at}: hero.mood {hero.get('mood')!r} 不在 CatMood 里"
                        f"（{' / '.join(sorted(moods))}）"
                    )
            elif kind == "glyph":
                if hero.get("provider") not in provider_keys:
                    raise SystemExit(f"{at}: hero.provider {hero.get('provider')!r} 不在 providers.json 里")
            elif kind == "shot":
                if index != 0:
                    raise SystemExit(
                        f"{at}: 只有第一条能带 shot。包体要恒定——"
                        "老条目在 App 里退化成纯文字，站点上仍然带图"
                    )
                if entry.get("drawer") is False:
                    raise SystemExit(
                        f"{at}: drawer:false 却带了 shot。给没人会看见的抽屉做图是笔误，不是决定"
                    )
                name = hero.get("name") or ""
                if not CHANGELOG_SHOT_RE.fullmatch(name):
                    raise SystemExit(f"{at}: hero.name {name!r} 要是小写连字符")
                for theme in ("light", "dark"):
                    source = ROOT / f"shared/whatsnew/media/{name}-{theme}@3x.png"
                    if not source.is_file():
                        raise SystemExit(f"{at}: 缺 {source.relative_to(ROOT)}")
            else:
                raise SystemExit(f"{at}: hero.kind 只能是 cat / glyph / shot")

        # 拼出来而不是写字面量：check_copy_terms 扫 scripts/，写全了这个脚本自己就红。
        banned_key_word = "凭" + "证"
        for text in _changelog_strings(entry):
            if banned_key_word in text:
                raise SystemExit(f"{at}: 钥匙叫「凭据」，见 BRAND.md 术语表")

    current = entries[0]
    for lang in CHANGELOG_LANGS:
        play = render_play_whatsnew(current, lang)
        if len(play) > PLAY_WHATSNEW_LIMIT:
            raise SystemExit(
                f"changelog.json: {lang} 的 Play 文案 {len(play)} 字，"
                f"超过 {PLAY_WHATSNEW_LIMIT}。删一条或改短"
            )
        asc = render_store_notes(current, lang)
        if len(asc) > ASC_WHATSNEW_LIMIT:
            raise SystemExit(
                f"changelog.json: {lang} 的 App Store 文案 {len(asc)} 字，超过 {ASC_WHATSNEW_LIMIT}"
            )

    # 改名过的 shot 会在三个目标目录里留下没人引用的旧位图，包体就不恒定了。
    expected = {path for path in changelog_media_outputs(doc)}
    for template in CHANGELOG_SHOT_TARGETS:
        folder = (ROOT / template).parent
        if not folder.is_dir():
            continue
        for path in folder.iterdir():
            if path.is_file() and path.suffix == ".png" and path not in expected:
                raise SystemExit(
                    f"changelog.json: {path.relative_to(ROOT)} 没有对应的 hero.shot，删掉它"
                )


def changelog_current_outputs_paths() -> list[Path]:
    """只描述「当前版本」的那几份文案。entries 空时它们不该存在。"""
    paths = [ROOT / "docs/release/notes.md"]
    for locale in ("zh-Hans", "en-US", "ja"):
        paths.append(ROOT / f"docs/appstore/metadata/{locale}/release_notes.txt")
    for locale in ("zh-CN", "en-US", "ja-JP"):
        paths.append(ROOT / f"Android/app/distribution/whatsnew/whatsnew-{locale}")
    for lang in CHANGELOG_LANGS:
        paths.append(ROOT / f"docs/release/appcast-notes/{lang}.html")
    return paths


def changelog_media_outputs(doc: dict) -> dict[Path, bytes]:
    """`hero.shot` 的位图。只有 entries[0] 能带，所以每班车最多两张 × 三处。"""
    result: dict[Path, bytes] = {}
    entries = doc.get("entries") or []
    if not entries:
        return result
    hero = entries[0].get("hero") or {}
    if hero.get("kind") != "shot":
        return result
    name = hero["name"]
    for theme in ("light", "dark"):
        data = (ROOT / f"shared/whatsnew/media/{name}-{theme}@3x.png").read_bytes()
        for path in changelog_shot_paths(name, theme):
            result[path] = data
    return result


def gen_site_changelog(doc: dict) -> str:
    rows: list[dict] = []
    imports: list[str] = []
    shot_refs: dict[str, str] = {}
    for index, entry in enumerate(doc["entries"]):
        row: dict = {"version": entry["version"]}
        if entry.get("date"):
            row["date"] = entry["date"]
        row["platforms"] = changelog_ordered_platforms(entry)
        hero = entry.get("hero") or {}
        if hero.get("kind") == "shot":
            name = hero["name"]
            for theme in ("light", "dark"):
                ident = f"shot{theme.capitalize()}{index}"
                imports.append(f"import {ident} from './assets/whatsnew/{name}-{theme}@3x.png';")
                shot_refs[f"__{ident}__"] = ident
            row["shot"] = {
                "light": f"__shotLight{index}__",
                "dark": f"__shotDark{index}__",
            }
        row["copy"] = {
            lang: {
                "title": changelog_text(entry, "title", lang),
                "items": [
                    {
                        "id": item["id"],
                        "title": changelog_text(item, "title", lang),
                        "body": changelog_text(item, "body", lang),
                    }
                    for item in entry["items"]
                ],
            }
            for lang in CHANGELOG_LANGS
        }
        rows.append(row)

    body = json.dumps(rows, ensure_ascii=False, indent=2)
    for placeholder, ident in shot_refs.items():
        body = body.replace(f'"{placeholder}"', ident)
    body = "\n".join(("  " + line if line else line) for line in body.splitlines())

    lines = [ts_header(CHANGELOG_SOURCE).rstrip(), ""]
    lines.append("import { siteConfig, type Locale } from './config';")
    if imports:
        lines += sorted(imports)
    lines += [
        "",
        f"export type ChangelogPlatform = {' | '.join(repr(p) for p in CHANGELOG_PLATFORMS)};",
        "",
        "export type ChangelogItem = {",
        "  /** 稳定 id。改名等于换一条，所以它也是以后远程文本 overlay 的钥匙。 */",
        "  id: string;",
        "  title: string;",
        "  body: string;",
        "};",
        "",
        "export type ChangelogLocaleCopy = {",
        "  title: string;",
        "  items: readonly ChangelogItem[];",
        "};",
        "",
        "export type ChangelogEntry = {",
        "  version: string;",
        "  /** 上架当天的 YYYY-MM-DD。没上架就省略，页面不编造日期。 */",
        "  date?: string;",
        "  platforms: readonly ChangelogPlatform[];",
        "  /** hero 截图。只有最新一条会带。 */",
        "  shot?: { light: ImageMetadata; dark: ImageMetadata };",
        "  copy: Record<Locale, ChangelogLocaleCopy>;",
        "};",
        "",
        f"const PLATFORM_ORDER: readonly ChangelogPlatform[] = "
        f"[{', '.join(repr(p) for p in CHANGELOG_PLATFORMS)}];",
        "",
        "/** 厂名不进 catalog。ios 那一班车是 iPhone 和 iPad 同一份。 */",
        "export const platformNames: Record<ChangelogPlatform, string> = {",
    ]
    for key in CHANGELOG_PLATFORMS:
        lines.append(f"  {key}: {CHANGELOG_PLATFORM_NAMES[key]!r},")
    lines.append("};")
    lines.append("")
    if rows:
        # json.dumps 给的是整个数组，剥掉外层方括号塞进来。
        inner = body.strip()
        lines.append("export const changelog: readonly ChangelogEntry[] = [")
        lines.append("\n".join(inner.splitlines()[1:-1]))
        lines.append("];")
    else:
        lines.append("export const changelog: readonly ChangelogEntry[] = [];")
    lines += [
        "",
        "export function latestChangelog(): ChangelogEntry | undefined {",
        "  return changelog[0];",
        "}",
        "",
        "export function changelogAnchor(version: string): string {",
        "  return `v${version}`;",
        "}",
        "",
        "export function formatChangelogDate(locale: Locale, iso: string): string {",
        "  const [year, month, day] = iso.split('-').map(Number);",
        "  const date = new Date(Date.UTC(year, month - 1, day));",
        "  return new Intl.DateTimeFormat(siteConfig.localeBcp47[locale], {",
        "    dateStyle: 'long',",
        "    timeZone: 'UTC',",
        "  }).format(date);",
        "}",
        "",
        "export function formatChangelogPlatforms(",
        "  platforms: readonly ChangelogPlatform[]",
        "): string {",
        "  return PLATFORM_ORDER.filter((item) => platforms.includes(item))",
        "    .map((item) => platformNames[item])",
        "    .join(' · ');",
        "}",
        "",
    ]
    return "\n".join(lines)


def _swift_string(text: str) -> str:
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _swift_text(node: dict, key: str, indent: str) -> str:
    values = ", ".join(
        f"{lang}: {_swift_string(changelog_text(node, key, lang))}" for lang in CHANGELOG_LANGS
    )
    return f"{indent}{key}: WhatsNewText({values})"


def gen_swift_whats_new(doc: dict) -> str:
    lines = [
        swift_header(CHANGELOG_SOURCE).rstrip(),
        "",
        # `hero: .cat(.saved)` 的 `.saved` 要看得见 CatMood，而 import 是按文件算的。
        "import MeterDesign",
        "",
        doc_comment(
            [
                "每一班车的更新说明。新的在上。",
                "",
                "三语都编在这里，展示时按 `CatalogLanguage` 选列——和目录同一条规矩，",
                "不走 xcstrings（那边是界面外壳的文案，这边是内容）。",
                "",
                "**编译期，不下发。** 它描述的是正在跑的这个二进制，打 tag 那一刻就全部已知；",
                "而抽屉在「更新后第一次冷启动」弹，那一刻远程缓存里按定义没有这条。",
                "以后若要支持远程改错别字，能被覆盖的只有 `title` / `body`，按 `WhatsNewItem.id` 认。",
            ]
        ),
        "enum WhatsNewCatalog {",
    ]
    if not doc["entries"]:
        lines += [
            "    /// 还没发过正式版。发版时在 shared/changelog.json 顶上加一条。",
            "    static let entries: [WhatsNewEntry] = []",
            "}",
            "",
        ]
        return "\n".join(lines)

    lines.append("    static let entries: [WhatsNewEntry] = [")
    for entry in doc["entries"]:
        platforms = ", ".join(f".{name}" for name in changelog_ordered_platforms(entry))
        lines.append("        WhatsNewEntry(")
        lines.append(f"            version: {_swift_string(entry['version'])},")
        lines.append(f"            platforms: [{platforms}],")
        lines.append(
            f"            showsDrawer: {'true' if changelog_shows_drawer(entry) else 'false'},"
        )
        hero = entry.get("hero")
        if hero is None:
            lines.append("            hero: nil,")
        elif hero["kind"] == "cat":
            lines.append(f"            hero: .cat(.{hero['mood']}),")
        elif hero["kind"] == "glyph":
            lines.append(f"            hero: .glyph({_swift_string(hero['provider'])}),")
        else:
            lines.append(f"            hero: .shot({_swift_string(hero['name'])}),")
        lines.append(_swift_text(entry, "title", "            ") + ",")
        lines.append("            items: [")
        for item in entry["items"]:
            lines.append("                WhatsNewItem(")
            lines.append(f"                    id: {_swift_string(item['id'])},")
            symbol = (item.get("symbol") or {}).get("ios")
            lines.append(
                f"                    symbol: {_swift_string(symbol) if symbol else 'nil'},"
            )
            lines.append(_swift_text(item, "title", "                    ") + ",")
            lines.append(_swift_text(item, "body", "                    "))
            lines.append("                ),")
        lines += ["            ]", "        ),"]
    lines += ["    ]", "}", ""]
    return "\n".join(lines)


def _kotlin_text(node: dict, key: str) -> str:
    values = ", ".join(
        f"{lang} = {_swift_string(changelog_text(node, key, lang))}" for lang in CHANGELOG_LANGS
    )
    return f"WhatsNewText({values})"


def gen_kotlin_whats_new(doc: dict) -> str:
    lines = [
        kotlin_header(CHANGELOG_SOURCE),
        "",
        "package com.zhechengqi.tollcat.settings",
        "",
        "/** 更新说明的三语文本。中文是规范列，展示时按 locale 选。 */",
        "data class WhatsNewText(val zh: String, val en: String, val ja: String) {",
        "    fun resolve(language: String): String = when {",
        '        language == "en" || language.startsWith("en-") -> en',
        '        language == "ja" || language.startsWith("ja-") -> ja',
        "        else -> zh",
        "    }",
        "}",
        "",
        "/** 抽屉里的一条。`id` 稳定，改名等于换一条。 */",
        "data class WhatsNewItem(",
        "    val id: String,",
        "    val symbol: String?,",
        "    val title: WhatsNewText,",
        "    val body: WhatsNewText,",
        ")",
        "",
        "sealed interface WhatsNewHero {",
        "    data class Cat(val mood: String) : WhatsNewHero",
        "    data class Glyph(val provider: String) : WhatsNewHero",
        "    data class Shot(val name: String) : WhatsNewHero",
        "}",
        "",
        "data class WhatsNewEntry(",
        "    val version: String,",
        "    val platforms: Set<String>,",
        "    val showsDrawer: Boolean,",
        "    val hero: WhatsNewHero?,",
        "    val title: WhatsNewText,",
        "    val items: List<WhatsNewItem>,",
        ")",
        "",
        "/** 新的在上。编译期铺进来，不下发——理由见 shared/changelog.json 的注释。 */",
        "object WhatsNewCatalog {",
    ]
    if not doc["entries"]:
        lines += ["    val entries: List<WhatsNewEntry> = emptyList()", "}", ""]
        return "\n".join(lines)

    lines.append("    val entries: List<WhatsNewEntry> = listOf(")
    for entry in doc["entries"]:
        platforms = ", ".join(_swift_string(name) for name in changelog_ordered_platforms(entry))
        hero = entry.get("hero")
        if hero is None:
            hero_literal = "null"
        elif hero["kind"] == "cat":
            hero_literal = f"WhatsNewHero.Cat({_swift_string(hero['mood'])})"
        elif hero["kind"] == "glyph":
            hero_literal = f"WhatsNewHero.Glyph({_swift_string(hero['provider'])})"
        else:
            hero_literal = f"WhatsNewHero.Shot({_swift_string(hero['name'])})"
        lines += [
            "        WhatsNewEntry(",
            f"            version = {_swift_string(entry['version'])},",
            f"            platforms = setOf({platforms}),",
            f"            showsDrawer = {'true' if changelog_shows_drawer(entry) else 'false'},",
            f"            hero = {hero_literal},",
            f"            title = {_kotlin_text(entry, 'title')},",
            "            items = listOf(",
        ]
        for item in entry["items"]:
            symbol = (item.get("symbol") or {}).get("android")
            lines += [
                "                WhatsNewItem(",
                f"                    id = {_swift_string(item['id'])},",
                f"                    symbol = {_swift_string(symbol) if symbol else 'null'},",
                f"                    title = {_kotlin_text(item, 'title')},",
                f"                    body = {_kotlin_text(item, 'body')},",
                "                ),",
            ]
        lines += ["            ),", "        ),"]
    lines += ["    )", "}", ""]
    return "\n".join(lines)


def _csharp_text(node: dict, key: str) -> str:
    values = ", ".join(_swift_string(changelog_text(node, key, lang)) for lang in CHANGELOG_LANGS)
    return f"new WhatsNewText({values})"


def gen_csharp_whats_new(doc: dict) -> str:
    lines = [
        csharp_header(CHANGELOG_SOURCE),
        "",
        "using System.Collections.Generic;",
        "",
        "namespace TollCat.Generated;",
        "",
        "public sealed record WhatsNewText(string Zh, string En, string Ja)",
        "{",
        "    public string Resolve(string language) =>",
        '        language.StartsWith("en") ? En : language.StartsWith("ja") ? Ja : Zh;',
        "}",
        "",
        "public sealed record WhatsNewItem(",
        "    string Id,",
        "    string? Symbol,",
        "    WhatsNewText Title,",
        "    WhatsNewText Body);",
        "",
        "public sealed record WhatsNewEntry(",
        "    string Version,",
        "    IReadOnlyList<string> Platforms,",
        "    bool ShowsDrawer,",
        "    string? HeroKind,",
        "    string? HeroValue,",
        "    WhatsNewText Title,",
        "    IReadOnlyList<WhatsNewItem> Items);",
        "",
        "/// <summary>新的在上。P0 之前只生成，不接界面。</summary>",
        "public static class WhatsNewCatalog",
        "{",
    ]
    if not doc["entries"]:
        lines += [
            "    public static readonly IReadOnlyList<WhatsNewEntry> Entries = "
            "new List<WhatsNewEntry>();",
            "}",
            "",
        ]
        return "\n".join(lines)

    lines.append(
        "    public static readonly IReadOnlyList<WhatsNewEntry> Entries = new List<WhatsNewEntry>"
    )
    lines.append("    {")
    for entry in doc["entries"]:
        platforms = ", ".join(_swift_string(name) for name in changelog_ordered_platforms(entry))
        hero = entry.get("hero")
        if hero is None:
            kind_literal, value_literal = "null", "null"
        elif hero["kind"] == "cat":
            kind_literal, value_literal = '"cat"', _swift_string(hero["mood"])
        elif hero["kind"] == "glyph":
            kind_literal, value_literal = '"glyph"', _swift_string(hero["provider"])
        else:
            kind_literal, value_literal = '"shot"', _swift_string(hero["name"])
        lines += [
            "        new WhatsNewEntry(",
            f"            {_swift_string(entry['version'])},",
            f"            new[] {{ {platforms} }},",
            f"            {'true' if changelog_shows_drawer(entry) else 'false'},",
            f"            {kind_literal},",
            f"            {value_literal},",
            f"            {_csharp_text(entry, 'title')},",
            "            new List<WhatsNewItem>",
            "            {",
        ]
        for item in entry["items"]:
            symbol = (item.get("symbol") or {}).get("windows")
            lines += [
                "                new WhatsNewItem(",
                f"                    {_swift_string(item['id'])},",
                f"                    {_swift_string(symbol) if symbol else 'null'},",
                f"                    {_csharp_text(item, 'title')},",
                f"                    {_csharp_text(item, 'body')}),",
            ]
        lines += ["            }),"]
    lines += ["    };", "}", ""]
    return "\n".join(lines)


def outputs() -> dict[Path, str]:
    result: dict[Path, str] = {}
    providers = load_providers()
    result[ROOT / "Packages/MeterKit/Sources/MeterDesign/ProviderGlyphArtwork.swift"] = (
        gen_swift_glyph_artwork(providers)
    )
    result[ROOT / "Packages/MeterKit/Sources/MeterDesign/ProviderPalette.swift"] = (
        gen_swift_palette(providers)
    )
    result[
        ROOT
        / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/services/ProviderGlyphArtwork.kt"
    ] = gen_kotlin_glyph_artwork(providers)
    result[ROOT / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/ProviderColors.kt"] = (
        gen_kotlin_colors(providers)
    )
    result[ROOT / "site/src/providers.ts"] = gen_site_providers(providers)
    result[ROOT / "site/src/supportTiers.ts"] = gen_site_support_tiers(providers)
    result[ROOT / "site/src/catalogEntries.ts"] = gen_site_catalog_entries()
    cat = load_cat()
    verify_cat(cat)
    result[ROOT / "Packages/MeterKit/Sources/MeterDesign/CatArtwork.swift"] = (
        gen_swift_cat_artwork(cat)
    )
    result[ROOT / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/ui/cat/CatArtwork.kt"] = (
        gen_kotlin_cat_artwork(cat)
    )
    result[ROOT / "Android/native/Sources/MeterBridge/JNICopy.swift"] = gen_jni_copy()
    # Android / Windows 的桥资源要一份真文件：SwiftPM 会把 symlink 原样拷进
    # build 产物，到那儿就是断链。内容和 MeterPersistence 那份的一致性由本闸保证。
    # 工作树里仍是 symlink（check_catalog_sync 认），write_text 会写到目标文件。
    result[ROOT / "Android/native/Sources/MeterBridge/Resources/catalog.json"] = (
        ROOT / "Packages/MeterKit/Sources/MeterPersistence/Catalog/catalog.json"
    ).read_text(encoding="utf-8")
    contract = load_contract()
    verify_contract(contract)
    result[ROOT / "worker/src/contract.ts"] = gen_worker_contract(contract)
    result[ROOT / "Packages/MeterKit/Sources/MeterTips/TipFieldLimits.swift"] = (
        gen_swift_tip_limits(contract)
    )
    result[ROOT / "Packages/MeterKit/Sources/MeterFeedback/FeedbackFieldLimits.swift"] = (
        gen_swift_feedback_limits(contract)
    )
    result[ROOT / "Packages/MeterKit/Sources/MeterUsage/UsageFieldLimits.swift"] = (
        gen_swift_usage_limits(contract)
    )
    result[ROOT / "Packages/MeterKit/Sources/MeterUsage/UsageAnalyticsScreen.swift"] = (
        gen_swift_usage_screens(contract)
    )
    result[ROOT / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/UsageScreens.kt"] = (
        gen_kotlin_usage_screens(contract)
    )
    result[ROOT / "Windows/app/Generated/UsageScreens.cs"] = gen_csharp_usage_screens(contract)
    result[ROOT / "Windows/app/Generated/UsageFieldLimits.cs"] = gen_csharp_usage_limits(contract)
    result[ROOT / "Windows/app/Generated/ProviderGlyphArtwork.cs"] = gen_csharp_glyph_artwork(
        providers
    )
    result[ROOT / "Windows/app/Generated/ProviderPalette.cs"] = gen_csharp_palette(providers)
    result[ROOT / "Windows/app/Generated/CatArtwork.cs"] = gen_csharp_cat_artwork(cat)
    identity = parse_provider_identity()
    verify_provider_identity(identity, providers)
    verify_letter_reasons(providers)
    result[ROOT / "Packages/MeterKit/Sources/MeterCore/ProviderIdentity.swift"] = (
        gen_swift_provider_identity(identity)
    )
    ui_test_ids = load_ui_test_ids()
    verify_ui_test_ids(ui_test_ids)
    result[ROOT / "Packages/MeterKit/Sources/MeterDesign/UITestID.swift"] = (
        gen_swift_ui_test_ids(ui_test_ids)
    )
    result[ROOT / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/ui/UITestId.kt"] = (
        gen_kotlin_ui_test_ids(ui_test_ids)
    )
    module_size = load_module_size()
    verify_module_size(module_size)
    result[ROOT / "Packages/MeterKit/Sources/MeterDesign/ModuleSize.swift"] = (
        gen_swift_module_size(module_size)
    )
    widgets = load_widgets()
    verify_widgets(widgets)
    result[ROOT / "Packages/MeterKit/Sources/MeterModules/ModuleWidgetSizes.swift"] = (
        gen_swift_module_widget_sizes(widgets)
    )
    result[ROOT / "Widget/TollCatWidgetBundle.swift"] = gen_swift_widget_bundle(widgets)
    changelog = load_changelog()
    verify_changelog(changelog, providers)
    result[ROOT / "site/src/changelog.ts"] = gen_site_changelog(changelog)
    result[ROOT / "Packages/MeterKit/Sources/MeterFeatures/Settings/WhatsNewCatalog.swift"] = (
        gen_swift_whats_new(changelog)
    )
    result[
        ROOT / "Android/app/src/main/kotlin/com/zhechengqi/tollcat/settings/WhatsNewCatalog.kt"
    ] = gen_kotlin_whats_new(changelog)
    result[ROOT / "Windows/app/Generated/WhatsNewCatalog.cs"] = gen_csharp_whats_new(changelog)
    if changelog["entries"]:
        # 只描述「当前版本」的文案，文件名固定：没有版本号后缀，就不会留下过期副本。
        current = changelog["entries"][0]
        result[ROOT / "docs/release/notes.md"] = render_release_notes_md(current)
        for lang, asc_locale, play_locale in (
            ("zh", "zh-Hans", "zh-CN"),
            ("en", "en-US", "en-US"),
            ("ja", "ja", "ja-JP"),
        ):
            result[ROOT / f"docs/appstore/metadata/{asc_locale}/release_notes.txt"] = (
                render_store_notes(current, lang)
            )
            result[ROOT / f"Android/app/distribution/whatsnew/whatsnew-{play_locale}"] = (
                render_play_whatsnew(current, lang)
            )
            result[ROOT / f"docs/release/appcast-notes/{lang}.html"] = render_appcast_notes(
                current, lang
            )
    version = load_version()
    result[ROOT / "project-common.yml"] = patch_project_yml_version(version)
    result[ROOT / "Android/app/build.gradle.kts"] = patch_gradle_version(version)
    result[ROOT / "Windows/app/TollCat.csproj"] = patch_csproj_version(version)
    result[ROOT / "Windows/app/Package.appxmanifest"] = patch_appxmanifest_version(version)
    result[ROOT / "Windows/app/Packaging/TollCat.appinstaller"] = patch_appinstaller_version(version)
    result[ROOT / "Windows/winget/com.zhechengqi.tollcat.yaml"] = patch_winget_version(version)
    result[ROOT / "site/src/scripts/contact-form.js"] = patch_site_contact_form(contract)
    result[ROOT / "site/src/views/Contact.astro"] = patch_site_contact_view(contract)
    return result


def binary_outputs() -> dict[Path, bytes]:
    """按字节铺的生成物。目前只有 `hero.shot` 的位图——文本路径塞不进 PNG。"""
    return changelog_media_outputs(load_changelog())


def main() -> int:
    check = "--check" in sys.argv[1:]
    stale: list[str] = []
    for path, content in outputs().items():
        rel = path.relative_to(ROOT)
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                stale.append(str(rel))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            print(f"生成 {rel}")
    for path, blob in binary_outputs().items():
        rel = path.relative_to(ROOT)
        if check:
            if not path.exists() or path.read_bytes() != blob:
                stale.append(str(rel))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(blob)
            print(f"生成 {rel}")
    if check and stale:
        print("生成物和 shared/ 不一致（改了 shared 没跑生成器，或手改了生成物）：")
        for rel in stale:
            print(f"  {rel}")
        print("跑 python3 scripts/generate-shared.py 后重新提交。")
        return 1
    if check:
        print("generate-shared --check 通过")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
