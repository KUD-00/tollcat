import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// 语义色走系统；品牌色只给 28pt `ProviderGlyph` tile。
public enum MeterColor {
    public static let good = Color.green
    public static let warn = Color.orange
    public static let crit = Color.red

    /// 构成：可区分的系统色相。小尺寸上同色相深浅分不清。
    /// 前 5 名各用一色；第 5 名之后的「其他」用 `compositionOther`。
    public static func composition(index: Int) -> Color {
        guard index >= 0, index < compositionStops.count else {
            return compositionOther
        }
        return compositionStops[index]
    }

    public static let compositionOther = Color.gray

    /// 构成图「前 N 名各占一色、之后并成其他」的那个 N。
    /// Widget 和大盘都读这里，别再各写死一个 5。
    public static var compositionNamedLimit: Int { compositionStops.count }

    /// TollCat 身体。定稿冷灰，不跟语义色走。
    /// 深色只抬亮度：同一只灰压在 grouped 卡面上要认得出剪影，
    /// 又不能亮到把白眼吃掉。不要改成 `Color.secondary`。
    public static let catBody = Color(light: catBodyLight, dark: catBodyDark)

    static let catBodyLight = Color(hex: 0x6E747B)
    static let catBodyDark = Color(hex: 0x858C93)

    static func catBody(for scheme: ColorScheme) -> Color {
        scheme == .dark ? catBodyDark : catBodyLight
    }

    /// 眼、嘴、眼镜。压在 `catBody` 上，深浅都是白。
    public static let catInk = Color.white

    /// 打赏三档的插画色。糖、咖啡、披萨该是什么颜色就是什么颜色，不跟强调色走——
    /// 三张画都染成同一只强调色的话，就只剩形状能分辨。只有 `TipTreatArtwork` 读这里。
    struct TipTreatPalette {
        var candy: Color
        var candyWrapper: Color
        var cupPaper: Color
        var cupSleeve: Color
        var cupLid: Color
        var cheese: Color
        var crust: Color
        var crustEdge: Color
        var pepperoni: Color
    }

    static func tipTreat(for scheme: ColorScheme) -> TipTreatPalette {
        scheme == .dark ? tipTreatDark : tipTreatLight
    }

    private static let tipTreatLight = TipTreatPalette(
        candy: Color(hex: 0xE0526A),
        candyWrapper: Color(hex: 0xF2A0AE),
        cupPaper: Color(hex: 0xD9B48D),
        cupSleeve: Color(hex: 0x8B5E3C),
        cupLid: Color(hex: 0x4A3A30),
        cheese: Color(hex: 0xEFB63C),
        crust: Color(hex: 0xD79A5B),
        crustEdge: Color(hex: 0xB57C43),
        pepperoni: Color(hex: 0xC0392B)
    )

    private static let tipTreatDark = TipTreatPalette(
        candy: Color(hex: 0xEC7387),
        candyWrapper: Color(hex: 0xF5B5C0),
        cupPaper: Color(hex: 0xC79C74),
        cupSleeve: Color(hex: 0xA06F49),
        cupLid: Color(hex: 0x5E4A3D),
        cheese: Color(hex: 0xE7B34B),
        crust: Color(hex: 0xC98E52),
        crustEdge: Color(hex: 0xA8743F),
        pepperoni: Color(hex: 0xD2503F)
    )

    /// 服务的标识色。参数是字符串 key，避免本模块认识领域类型。
    /// 色表在 shared/providers.json（生成物是 `ProviderPalette`），三端同一份。
    /// 只用于 `ProviderGlyph` 的 28pt tile，不进图表和大面积。
    public static func provider(_ key: String) -> Color {
        ProviderPalette.color(for: key)
    }

    /// 压在 `provider` tile 上的 glyph。浅色品牌色够深，白字过 3:1；
    /// 深色色板把品牌色提亮之后白字掉到 2.1–2.6，改用近黑才能读。
    public static let providerGlyphInk = Color(light: Color.white, dark: Color(hex: 0x0E1116))

    private static let compositionStops: [Color] = [
        .indigo,
        .teal,
        .orange,
        .pink,
        .purple,
    ]
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: Color(hex: light), dark: Color(hex: dark))
    }

    /// 品牌 tile 的 light / dark 两套色。系统语义色不用走这里。
    ///
    /// SwiftUI 到现在也没有 `Color(light:dark:)`。Asset Catalog 之外，
    /// 程序化动态色只能走动态 `UIColor` / `NSColor`。
    init(light: Color, dark: Color) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
        #else
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
    }
}
