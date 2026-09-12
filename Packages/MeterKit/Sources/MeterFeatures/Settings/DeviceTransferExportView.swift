import SwiftUI
import MeterDesign
import MeterPersistence

struct DeviceTransferExportView: View {
    @Bindable var model: DeviceTransferExportModel

    var body: some View {
        MeterGroupedList {
            Section {
                Text(L("这个文件是加密的。把它隔空投送、存到文件或用邮件发到新设备都可以——安全性靠文件本身，不靠通道。"))
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            switch model.phase {
            case .preparing:
                EmptyView()
            case .ready(let snapshot):
                Section {
                    Text(snapshot.displayCode)
                        .font(MeterFont.transferCode)
                        .monospacedDigit()
                        .foregroundStyle(Color.meterLabel)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .listRowBackground(Color.clear)
                        .accessibilityLabel(L("一次性码 \(snapshot.displayCode)"))
                        .speechSpellsOutCharacters()
                } header: {
                    Text(L("一次性码"))
                } footer: {
                    Text(L("一次性码只在这里显示。离开这一页就没了，也不会复制到剪贴板。"))
                }

                Section {
                    LabeledContent(L("有效期")) {
                        Text(L("\(TransferLifetime.hourCount) 小时"))
                            .monospacedDigit()
                    }
                } footer: {
                    Text(L("请在 \(snapshot.deadlineCaption) 之前导入。过期只缩小误发的窗口，挡不住已经拿到文件的人离线试码。"))
                }
            case .failed(let message):
                Section {
                    Text(message)
                        .foregroundStyle(MeterColor.crit)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .meterPrimaryActionBar(isVisible: model.shareItem != nil) {
            if let item = model.shareItem {
                ShareLink(
                    item: item,
                    preview: SharePreview(Text(L("转移到新设备")))
                ) {
                    Text(L("分享文件"))
                        .frame(maxWidth: .infinity)
                }
                .meterPrimaryActionStyle()
                .accessibilityHint(L("用系统分享送出加密文件"))
            }
        }
        .task {
            model.prepareIfNeeded()
        }
    }
}
