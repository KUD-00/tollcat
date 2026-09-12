import SwiftUI

/// 会离开 App 的链接。标题右侧跟系统 safari 符号，表示在浏览器打开。
///
/// 教程步骤句子里的行内链接把符号贴在可点字前面；列表行没有那句上下文，
/// 符号跟在标题右边，才一眼看得出这行会跳走。
public struct SafariLink: View {
    private let title: LocalizedStringResource
    private let destination: URL

    public init(_ title: LocalizedStringResource, destination: URL) {
        self.title = title
        self.destination = destination
    }

    public var body: some View {
        Link(destination: destination) {
            HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xxs) {
                Text(title)
                Image(systemName: "safari")
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHint(L("在 Safari 打开"))
    }
}

#Preview("Light") {
    List {
        SafariLink(
            LocalizedStringResource(stringLiteral: "在官网查看账单"),
            destination: URL(string: "https://example.invalid/billing")!
        )
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        SafariLink(
            LocalizedStringResource(stringLiteral: "在官网查看账单"),
            destination: URL(string: "https://example.invalid/billing")!
        )
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.dark)
}
