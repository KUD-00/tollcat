import SwiftUI
import MeterDesign
import MeterInbox

/// 设置 → 读数信箱。
struct InboxSettingsView: View {
    @Bindable var model: InboxSettingsModel
    @State private var keyPendingRevocation: String?

    var body: some View {
        Group {
            if model.hasInbox {
                populated
            } else {
                InboxEmptyView()
            }
        }
        .navigationTitle(L("读数信箱"))
        .navigationBarTitleDisplayMode(.large)
        .task { await model.load() }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.copyToken)
    }

    private var populated: some View {
        MeterGroupedList {
            if let fresh = model.freshKey {
                freshKeySection(fresh)
            }
            keysSection
            mailboxSection
            dangerSection
            if let failure = model.failure {
                failureSection(failure)
            }
        }
        .confirmationDialog(
            L("吊销这把投递 key？"),
            isPresented: isConfirmingKeyRevocation,
            titleVisibility: .visible
        ) {
            Button(L("吊销"), role: .destructive) {
                if let id = keyPendingRevocation {
                    Task { await model.revokeKey(id: id) }
                }
                keyPendingRevocation = nil
            }
            Button(L("取消"), role: .cancel) {
                keyPendingRevocation = nil
            }
        } message: {
            Text(L("用这把投递 key 的脚本会立刻失效，其它的不受影响。"))
        }
    }

    private var isConfirmingKeyRevocation: Binding<Bool> {
        Binding(
            get: { keyPendingRevocation != nil },
            set: { if !$0 { keyPendingRevocation = nil } }
        )
    }

    private func freshKeySection(_ key: IssuedIngestKey) -> some View {
        Section {
            CopyBox(key.secret, copyTitle: String(localized: L("复制"))) {
                model.copyFreshKey()
            }
            Button(L("我存好了")) {
                model.dismissFreshKey()
            }
        } header: {
            Text(L("新的投递 key"))
        } footer: {
            Text(L("只显示这一次。旧的投递 key 还能继续用，等你把脚本改完再来吊销它。"))
        }
    }

    private var keysSection: some View {
        Section {
            if model.keys.isEmpty, !model.isLoading {
                Text(L("还没有投递 key"))
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            ForEach(model.keys) { key in
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(key.label ?? String(localized: L("未命名")))
                    Text(lastUsedCaption(key))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
                .swipeActions {
                    Button(L("吊销"), role: .destructive) {
                        keyPendingRevocation = key.id
                    }
                }
            }
            Button(L("签一把新的")) {
                Task { await model.mintKey() }
            }
            .disabled(model.isLoading)
        } header: {
            Text(L("投递 key"))
        } footer: {
            Text(L("一个脚本一把。某一把泄露了只吊销它，其它脚本不受影响。"))
        }
    }

    private var mailboxSection: some View {
        Section {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                LabeledContent(String(localized: L("信箱"))) {
                    Text(model.mailbox ?? "—")
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                ListRowNote(text: L("信箱里只有金额，没有你任何服务的账号或密钥。"))
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(L("删除信箱"), role: .destructive) {
                model.isConfirmingDelete = true
            }
            // 挂在按钮上而不是 List 上：iOS 26 把确认框锚定到所附着的视图，
            // 挂在容器上会固定弹在屏幕顶部。
            .confirmationDialog(
                L("删除读数信箱？"),
                isPresented: $model.isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button(L("删除信箱"), role: .destructive) {
                    Task { await model.deleteInbox() }
                }
                Button(L("取消"), role: .cancel) {}
            } message: {
                Text(deleteWarning)
            }
        }
    }

    private func failureSection(_ failure: InboxError) -> some View {
        Section {
            Text(explanation(failure))
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
        }
    }

    private var deleteWarning: LocalizedStringResource {
        let affected = model.affectedProviders
        if affected.isEmpty {
            return L("服务器上的读数会一起删掉。已经存到本机的历史留着。")
        }
        return L("\(affected.joined(separator: "、")) 会立刻停止更新，你的投递脚本也会全部失效。已经存到本机的历史留着。")
    }

    private func lastUsedCaption(_ key: IngestKeyInfo) -> LocalizedStringResource {
        guard let lastUsed = key.lastUsedAt else {
            return L("还没投递过")
        }
        let text = MeterDateFormat.monthAndDay(lastUsed, calendar: model.calendar)
        return L("最近投递 \(text)")
    }

    private func explanation(_ failure: InboxError) -> LocalizedStringResource {
        switch failure.code {
        case .unauthorized:
            L("这个信箱在服务器上已经不存在了。删掉它，接入时会重新建一个。")
        case .rateLimited:
            L("操作太频繁了，等一会儿再试。")
        case .unreachable, .malformedResponse:
            L("连不上服务器。已经接入的其它服务不受影响。")
        }
    }
}

#Preview("Light · 有信箱") {
    NavigationStack {
        InboxSettingsView(model: .preview())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark · 有信箱") {
    NavigationStack {
        InboxSettingsView(model: .preview())
    }
    .preferredColorScheme(.dark)
}

#Preview("Light · 还没有信箱") {
    NavigationStack {
        InboxSettingsView(model: .preview(hasInbox: false))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark · 还没有信箱") {
    NavigationStack {
        InboxSettingsView(model: .preview(hasInbox: false))
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    NavigationStack {
        InboxSettingsView(model: .preview())
    }
    .dynamicTypeSize(.accessibility3)
}
