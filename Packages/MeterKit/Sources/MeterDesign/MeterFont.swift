import SwiftUI

/// 语义字号。金额对齐用 `.monospacedDigit()`，不要换 mono 字族。
public enum MeterFont {
    public static let largeTitle = Font.largeTitle
    public static let title = Font.title
    public static let title2 = Font.title2
    public static let body = Font.body
    public static let bodyEmphasized = Font.body.weight(.semibold)
    #if os(macOS)
    // macOS 的内建样式把底部压扁了：footnote / caption / caption2 全是 10pt，
    // 而 10pt 正好是 HIG 给 Mac 的最低线。iOS 上这几档是 13 / 12 / 11，
    // 按 iOS 比例分配出来的注解和说明到 Mac 上就整体落到底线，三档塌成一档。
    // 这里按系统设置的读法重排：正文 13、次要 12、说明 11、三级标注 10。
    // 其它平台不动——只有这一处知道平台，视图仍然只认语义名。
    public static let subheadline = Font.callout
    public static let footnote = Font.subheadline
    public static let caption = Font.subheadline
    public static let caption2 = Font.footnote
    #else
    public static let subheadline = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let caption2 = Font.caption2
    #endif

    /// 仪表页和 Widget 大号的主角金额。全产品允许写死 size 的那一处。
    public static let amount = Font.system(size: 34, weight: .bold)

    /// 要逐字核对的一次性码。这是系统 mono 的合法用途，不是把 UI 换成等宽。
    public static let transferCode = Font.system(.largeTitle, design: .monospaced).weight(.semibold)

    /// 导入页的码输入框，和导出页同一套字形，方便对照。
    public static let transferCodeField = Font.system(.body, design: .monospaced)
}

public extension View {
    func meterAmountStyle() -> some View {
        font(MeterFont.amount)
            .monospacedDigit()
    }

    func meterInlineAmountStyle() -> some View {
        font(MeterFont.body)
            .monospacedDigit()
    }
}
