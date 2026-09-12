import SwiftUI
import MeterDesign
import MeterPersistence

struct DeviceTransferImportView: View {
    @Bindable var model: DeviceTransferImportModel
    @State private var isPicking = false
    @FocusState private var focusedField: String?

    private static let codeFieldID = "transfer-code"

    var body: some View {
        MeterGroupedList {
            Section {
                Text(L("导入会替换这台设备上已有的接入、凭据和手动订阅。历史读数不会跟着过来，导入后会重新刷新。"))
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Button(L("选择文件")) {
                    isPicking = true
                }
                .accessibilityHint(L("选择一个 .tollcat 文件"))
                if let fileName = model.fileName {
                    Text(L("已选择 \(fileName)"))
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section {
                CredentialFieldRow(
                    title: String(localized: L("一次性码")),
                    fieldID: Self.codeFieldID,
                    text: $model.codeInput,
                    focusedField: $focusedField,
                    kind: .transferCode,
                    isEnabled: !model.isLocked,
                    onPaste: pasteCode,
                    onSubmit: submitCode
                )
            } footer: {
                footer
            }
        }
        .meterKeyboardDismiss {
            focusedField = nil
        }
        .meterPrimaryActionBar {
            Button {
                Task { await model.importSelected() }
            } label: {
                Text(L("导入"))
                    .frame(maxWidth: .infinity)
            }
            .meterPrimaryActionStyle()
            .disabled(!model.canImport)
        }
        .fileImporter(
            isPresented: $isPicking,
            allowedContentTypes: [TollcatUTType.utType],
            allowsMultipleSelection: false
        ) { result in
            model.handlePicked(result)
        }
    }

    /// 一次性码是从旧设备读过来的，多半就在剪贴板里。连接凭据那一栏怎么粘，这里就怎么粘：
    /// 首尾空白去掉，`TransferCode` 自己会认连字符和大小写。
    private func pasteCode() {
        guard let raw = SystemClipboard.string else { return }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        model.codeInput = value
    }

    private func submitCode() {
        focusedField = nil
        Task { await model.importSelected() }
    }

    @ViewBuilder
    private var footer: some View {
        switch model.banner {
        case .remainingAttempts(let remaining):
            Text(L("码不对，还可以试 \(remaining) 次"))
                .foregroundStyle(MeterColor.crit)
        case .expired:
            Text(L("这个文件已经过期，请在旧设备上重新导出"))
                .foregroundStyle(MeterColor.crit)
        case .invalidFile:
            Text(L("这个文件打不开"))
                .foregroundStyle(MeterColor.crit)
        case .invalidCode:
            Text(L("一次性码格式不对"))
                .foregroundStyle(MeterColor.crit)
        case .locked(let seconds):
            Text(L("试得太多次了，\(seconds) 秒后再试"))
                .foregroundStyle(MeterColor.crit)
        case .failed:
            Text(L("没能完成导入，请再试一次"))
                .foregroundStyle(MeterColor.crit)
        case .success:
            Text(L("导入成功，正在刷新账单"))
                .foregroundStyle(MeterColor.good)
        case .unsupportedSchema:
            Text(L("这个迁移包是旧版。导出设备升级 TollCat 后再导出。"))
                .foregroundStyle(MeterColor.crit)
        case nil:
            EmptyView()
        }
    }
}
