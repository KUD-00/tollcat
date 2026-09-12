#if DEBUG
import SwiftUI
import MeterDesign

struct DeveloperBuildInfoView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                LabeledContent(L("版本")) {
                    Text(DeveloperBuildInfo.versionCaption)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                }
                if let modified = DeveloperBuildInfo.executableModifiedAt {
                    LabeledContent(L("构建时间")) {
                        Text(Self.dateText(modified))
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .monospacedDigit()
                    }
                }
                if let commit = DeveloperBuildInfo.gitCommit {
                    LabeledContent("Git") {
                        Text(commit)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .monospacedDigit()
                    }
                }
            } footer: {
                Text(L("没有注入构建脚本。Git commit 拿不到就只显示版本号。"))
            }
        }
        .navigationTitle(L("构建信息"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperBuildInfoView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperBuildInfoView()
    }
    .preferredColorScheme(.dark)
}
#endif
