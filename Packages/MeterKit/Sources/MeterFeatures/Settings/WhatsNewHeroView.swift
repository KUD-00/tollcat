import CoreGraphics
import ImageIO
import SwiftUI
import MeterDesign

/// 抽屉顶上那张图。三档各自走已有的渲染，这里只做分派。
struct WhatsNewHeroView: View {
    var hero: WhatsNewHero

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch hero {
        case let .cat(mood):
            CatView(mood: mood, size: MeterSpacing.catUsageGuide)
        case let .glyph(provider):
            ProviderGlyph(colorKey: provider, size: MeterSpacing.catUsageGuide)
        case let .shot(name):
            shot(named: name)
        }
    }

    @ViewBuilder
    private func shot(named name: String) -> some View {
        // `Image("…", bundle: .module)` 找不到它：那条路只查 asset catalog，而这是
        // SPM `.process` 原样拷进 bundle 的散装 PNG。和 BrandMark 同一条线，走 ImageIO。
        if let bitmap = Self.bitmap(name: name, theme: colorScheme == .dark ? "dark" : "light") {
            Image(decorative: bitmap, scale: 3)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: MeterRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: MeterRadius.card, style: .continuous)
                        .strokeBorder(Color.meterSeparator, lineWidth: 1)
                }
                .accessibilityHidden(true)
        }
        // 位图丢了就什么都不画：这一条的标题和正文本身已经说明白了，
        // 不要为了占位开一个灰洞。
    }

    private static func bitmap(name: String, theme: String) -> CGImage? {
        guard
            let url = Bundle.module.url(
                forResource: "\(name)-\(theme)@3x",
                withExtension: "png",
                subdirectory: "WhatsNew"
            ) ?? Bundle.module.url(forResource: "\(name)-\(theme)@3x", withExtension: "png"),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

#Preview("猫") {
    WhatsNewHeroView(hero: .cat(.saved))
        .padding()
        .background(Color.meterGroupedBackground)
}

#Preview("服务图标") {
    WhatsNewHeroView(hero: .glyph("cloudflare"))
        .padding()
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
