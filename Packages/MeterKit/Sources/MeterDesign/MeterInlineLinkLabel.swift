import SwiftUI

/// 自己画箭头的行内入口（「查看更多 ›」「全部 N 项 ›」）。
///
/// 系统 List / Mac 列的 chevron 钉在行右缘、三级灰，字在左缘，一行两头各挂一个。
/// 字和箭头同色、贴在一起、一起靠右，才读成一颗按钮。
///
/// 必须撑满容器宽：`VStack(alignment: .leading)` 里的 HStack 若不吃掉提议宽度，
/// `Spacer` 会收成 0，整颗链接缩成字那么宽——iOS 上又小又难点。
public struct MeterInlineLinkLabel: View {
    private let title: Text

    public init(_ title: Text) {
        self.title = title
    }

    public var body: some View {
        HStack(spacing: MeterSpacing.xxs) {
            Spacer(minLength: 0)
            title
            Image(systemName: "chevron.right")
                .accessibilityHidden(true)
        }
        .font(MeterFont.subheadline.weight(.semibold))
        .foregroundStyle(Color.accentColor)
        .meterListRowHitTarget()
    }
}

#Preview("Light") {
    List {
        Text("Workers")
        MeterInlineLinkLabel(Text("全部 21 项"))
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Text("Workers")
        MeterInlineLinkLabel(Text("全部 21 项"))
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.dark)
}
