import SwiftUI

/// 分享卡自己的一套颜色。**写死，不跟分享者的深色模式走**——这张图会被转发到
/// 任何地方，收到的人不该看到一张黑卡。卡的骨架（`ShareCardView`）和塞进卡里的
/// 模块容器（`MeterFeatures` 那边）都读这一份，两处不许各写一个 hex。
public enum ShareCardPalette {
    /// 正文墨色。
    public static let ink = Color(hex: 0x111318)
    /// 次要说明。
    public static let secondaryInk = Color(hex: 0x6E747B)
    /// 更弱的脚注。
    public static let tertiaryInk = Color(hex: 0x8E8E93)
    /// 卡面。
    public static let card = Color(hex: 0xFFFFFF)
    /// 卡的页底色，和 iOS `systemGroupedBackground` 的浅色同一块。
    public static let page = Color(hex: 0xF2F2F7)
    /// 品牌色（tint）。
    public static let brand = Color(hex: 0x5856D6)
}
