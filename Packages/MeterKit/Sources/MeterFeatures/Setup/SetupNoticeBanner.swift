import SwiftUI
import MeterDesign

struct SetupNoticeBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(MeterFont.body)
            .foregroundStyle(MeterColor.warn)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(message)
    }
}

#Preview("Light") {
    List {
        Section {
            SetupNoticeBanner(
                message: String(localized: L("个人账号用不了 Usage & Cost Admin API。要先在 Console 建组织，再签发 Admin API Key，否则这家只能手工录入订阅。"))
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            SetupNoticeBanner(message: String(localized: L("AWS Cost Explorer 每刷新一次大约 $0.01，不会加入全局刷新。")))
        }
    }
    .preferredColorScheme(.dark)
}
