import SwiftUI

/// 品牌色圆角方块 + 单色 glyph。服务页 / 详情 / 向导 / Widget 共用。
///
/// 图标来自 Simple Icons（simpleicons.org，CC0 1.0），以 path 填色代替 template
/// 资源——效果相同，且本模块不必声明 asset catalog。拿不到官方 path 的 key
/// 回落到同一尺寸 tile 里的首字母，不手绘仿制 logo。
public struct ProviderGlyph: View {
    private let colorKey: String
    private let size: CGFloat
    private let accessibilityName: String?

    public init(
        colorKey: String,
        size: CGFloat = MeterSpacing.providerGlyph,
        accessibilityName: String? = nil
    ) {
        self.colorKey = colorKey
        self.size = size
        self.accessibilityName = accessibilityName
    }

    public var body: some View {
        let key = colorKey.lowercased()
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(MeterColor.provider(key))
            if let d = ProviderGlyphArtwork.pathData(for: key) {
                SVGPathShape(d: d)
                    .fill(
                        MeterColor.providerGlyphInk,
                        style: FillStyle(eoFill: ProviderGlyphArtwork.usesEvenOddFill(for: key))
                    )
                    .padding(glyphPadding)
            } else {
                Text(verbatim: ProviderGlyphArtwork.monogramLetter(for: key))
                    .font(monogramFont)
                    .foregroundStyle(MeterColor.providerGlyphInk)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .modifier(ProviderGlyphAccessibility(name: accessibilityName))
    }

    private var cornerRadius: CGFloat {
        MeterRadius.glyph * (size / MeterSpacing.providerGlyph)
    }

    private var glyphPadding: CGFloat { size * (1 - Self.fillRatio(for: colorKey)) / 2 }

    /// 跟着 tile 边长走，不是页面正文。64pt 确认抽屉里 `.body` 会缩成一粒。
    private var monogramFont: Font {
        let letter = ProviderGlyphArtwork.monogramLetter(for: colorKey)
        // I / J / T 中空太多，默认 0.64 在 28pt 上掉到 5% 墨以下。
        let ratio: CGFloat
        switch letter {
        case "I": ratio = Self.narrowStemMonogramRatio
        case "J", "T": ratio = Self.thinLetterMonogramRatio
        default: ratio = Self.monogramRatio
        }
        return .system(size: size * ratio, weight: .semibold, design: .rounded)
    }

    /// 单字要比细线 path 更满：0.52 在 28pt 上只有约 4% 墨，低于栅格下限。
    public static let monogramRatio: CGFloat = 0.64
    public static let thinLetterMonogramRatio: CGFloat = 0.76
    public static let narrowStemMonogramRatio: CGFloat = 0.92

    /// 占比数据在 shared/providers.json，跟 path 一起生成。
    public static func fillRatio(for colorKey: String) -> CGFloat {
        ProviderGlyphArtwork.fillRatio(for: colorKey)
    }
}

private struct ProviderGlyphAccessibility: ViewModifier {
    var name: String?

    func body(content: Content) -> some View {
        if let name, !name.isEmpty {
            content.accessibilityLabel(name)
        } else {
            content.accessibilityHidden(true)
        }
    }
}

#Preview("Light") {
    ProviderGlyphPreviewLibrary()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProviderGlyphPreviewLibrary()
        .preferredColorScheme(.dark)
}

private struct ProviderGlyphPreviewLibrary: View {
    private let columns = [
        GridItem(.adaptive(minimum: MeterSpacing.providerGlyph), spacing: MeterSpacing.sm),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: MeterSpacing.sm) {
            ForEach(ProviderGlyphPreviewKeys.all, id: \.self) { key in
                ProviderGlyph(colorKey: key)
            }
        }
        .padding(MeterSpacing.pageHorizontal)
        .frame(maxWidth: .infinity)
        .background(Color.meterGroupedBackground)
    }
}

private enum ProviderGlyphPreviewKeys {
    static let all = [
        "cloudflare", "aws", "openai", "anthropic", "vercel", "github", "neon", "fly",
        "openrouter", "deepseek", "moonshot", "moonshotai", "digitalocean", "twilio", "planetscale",
        "upstash", "elevenlabs", "railway", "stripe",
        "resend", "posthog", "clerk", "sentry",
        "vultr", "fastly", "atlas", "gitlab", "render", "expo", "qdrant", "revenuecat",
        "cursor", "heroku", "xai", "exa", "azure", "polar",
    ]
}
