import SwiftUI
import MeterDesign

/// 落盘失败 / 演示数据的环境提示。它不是内容，不要做成一张卡。
struct PersistenceNoticeList: View {
    var status: PersistenceStatus
    var onDismissDemo: (() -> Void)?

    var body: some View {
        if !status.notices.isEmpty {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                ForEach(status.notices) { notice in
                    HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                        Text(notice.message)
                            .font(MeterFont.footnote)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                        if notice.isDismissible {
                            Button {
                                status.isDemoBannerDismissed = true
                                onDismissDemo?()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(MeterFont.caption.weight(.semibold))
                                    .foregroundStyle(Color.meterTertiaryLabel)
                                    .frame(width: MeterSpacing.minTap, height: MeterSpacing.minTap)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L("关闭演示数据提示"))
                        }
                    }
                }
            }
        }
    }
}

#Preview("Light") {
    List {
        Section {
            Text(L("本月合计"))
        } footer: {
            PersistenceNoticeList(
                status: PersistenceStatus(persistsToDisk: false, containsDemoData: true)
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            Text(L("本月合计"))
        } footer: {
            PersistenceNoticeList(
                status: PersistenceStatus(persistsToDisk: false, containsDemoData: true)
            )
        }
    }
    .preferredColorScheme(.dark)
}
