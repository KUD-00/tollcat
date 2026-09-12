import SwiftUI

/// 可复制的权限名 / JSON。点击后只回调，不自己碰剪贴板。
/// 内容区用 mono：这是在展示代码，也是全 App 唯一允许的 mono 字族。
public struct CopyBox: View {
    private let text: String
    private let copyTitle: String
    private let onCopy: () -> Void

    public init(
        _ text: String,
        copyTitle: String? = nil,
        onCopy: @escaping () -> Void
    ) {
        self.text = text
        self.copyTitle = copyTitle ?? String(localized: L("复制"))
        self.onCopy = onCopy
    }

    public var body: some View {
        HStack(alignment: .top, spacing: MeterSpacing.sm) {
            Text(text)
                .font(.body.monospaced())
                .foregroundStyle(Color.meterLabel)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(copyTitle, action: onCopy)
                .font(MeterFont.subheadline)
                .frame(minWidth: MeterSpacing.minTap, minHeight: MeterSpacing.minTap)
                .contentShape(Rectangle())
                .accessibilityLabel(copyTitle)
        }
    }
}

#Preview("Light") {
    List {
        Section {
            CopyBox("Account · Billing · Read", onCopy: {})
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            CopyBox(
                """
                {
                  "Version": "2012-10-17",
                  "Statement": [
                    { "Effect": "Allow", "Action": "ce:GetCostAndUsage", "Resource": "*" }
                  ]
                }
                """,
                onCopy: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
