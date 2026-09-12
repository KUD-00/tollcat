import SwiftUI

/// 教程里的 1 / 2 / 3。圆角方形，浅灰底浅灰边。和整段步骤文字垂直居中。
public struct StepIndexBadge: View {
    public var number: Int

    public init(_ number: Int) {
        self.number = number
    }

    public var body: some View {
        Text(verbatim: "\(number)")
            .font(MeterFont.body.weight(.semibold))
            .foregroundStyle(Color.meterLabel)
            .frame(width: MeterSpacing.stepIndex, height: MeterSpacing.stepIndex)
            .background {
                RoundedRectangle(cornerRadius: MeterRadius.stepBadge, style: .continuous)
                    .fill(Color.meterTertiarySystemFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: MeterRadius.stepBadge, style: .continuous)
                            .strokeBorder(Color.meterSystemGray4, lineWidth: 1)
                    }
            }
            .accessibilityHidden(true)
    }
}

#Preview("Light") {
    StepIndexBadgePreviewLibrary()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    StepIndexBadgePreviewLibrary()
        .preferredColorScheme(.dark)
}

private struct StepIndexBadgePreviewLibrary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.md) {
            HStack(alignment: .center, spacing: MeterSpacing.stepIndexGap) {
                StepIndexBadge(1)
                Text(verbatim: "打开 Cloudflare 控制台的 API Tokens 页面，点 Create Token。选 Custom token，只勾 Account · Billing · Read。")
                    .font(MeterFont.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: MeterSpacing.sm) {
                ForEach(1..<5, id: \.self) { number in
                    StepIndexBadge(number)
                }
            }
        }
        .padding(MeterSpacing.pageHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.meterGroupedBackground)
    }
}
