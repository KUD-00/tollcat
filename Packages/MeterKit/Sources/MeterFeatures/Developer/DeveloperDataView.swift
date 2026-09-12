#if DEBUG
import SwiftUI
import MeterDesign

struct DeveloperDataView: View {
    var dashboard: DashboardModel
    var persistenceStatus: PersistenceStatus
    @State private var exportCaption: String?
    @State private var errorMessage: String?
    @State private var ledgerStats: (rows: Int, inSync: Bool, isReadPath: Bool)?
    @State private var ledgerIssues: [String]?
    @State private var isCheckingLedger = false

    var body: some View {
        MeterGroupedList {
            Section {
                Toggle(isOn: demoModeBinding) {
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        Text(L("演示模式"))
                        Text(L("空库启动时填入示例账单。对正式使用没有意义。"))
                            .font(MeterFont.footnote)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityLabel(L("演示模式"))
                .accessibilityHint(L("打开后，空库会写入示例账单"))

                Button(L("种子演示数据")) {
                    seed()
                }
                Button(L("清空全部"), role: .destructive) {
                    clear()
                }
                Button(L("导出到控制台")) {
                    export()
                }
                .accessibilityHint(L("把当前 Snapshot 打成 JSON，复制到剪贴板"))
                if let exportCaption {
                    Text(exportCaption)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(MeterFont.footnote)
                        .foregroundStyle(MeterColor.crit)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } footer: {
                Text(L("演示模式只给开发用。种子只在空库写入；已有账单时先清空。「导出到控制台」把 Snapshot 打成 JSON，复制到剪贴板；连着 Xcode Run 时也会出现在控制台。"))
            }

            ledgerSection

            Section {
                Button(L("重放 onboarding")) {
                    dashboard.shell.replayOnboarding()
                }
                .accessibilityHint(L("下次回到根界面会再走一遍首次引导"))

                Button(L("重看使用指南")) {
                    dashboard.shell.resetUsageGuides()
                }
                .accessibilityHint(L("下次冷启动会再弹还没看过的一篇"))
            } header: {
                Text(L("猫猫"))
            }
        }
        .navigationTitle(L("数据操作"))
        .navigationBarTitleDisplayMode(.inline)
        .task { ledgerStats = dashboard.ledgerStats() }
    }

    /// 物化账本那一节。
    ///
    /// 「跑一次对账」是这套东西唯一的凭据：账本是快照日志的一份压平，两条路
    /// 必须逐项相同。**一致时也要说话**——只在出错时才显示的检查，等于没人知道
    /// 它有没有跑过。
    @ViewBuilder
    private var ledgerSection: some View {
        Section {
            LabeledContent(L("账本行数")) {
                Text(verbatim: "\(ledgerStats?.rows ?? 0)")
            }
            LabeledContent(L("和快照")) {
                Text(ledgerStats?.inSync == true ? L("对得上") : L("待重折"))
                    .foregroundStyle(
                        ledgerStats?.inSync == true ? Color.meterSecondaryLabel : MeterColor.warn
                    )
            }
            LabeledContent(L("这次重算读的是")) {
                Text(ledgerStats?.isReadPath == true ? L("账本") : L("全部快照"))
                    .foregroundStyle(
                        ledgerStats?.isReadPath == true ? MeterColor.good : Color.meterSecondaryLabel
                    )
            }
            Button(L("跑一次对账")) {
                Task {
                    isCheckingLedger = true
                    ledgerIssues = await dashboard.runLedgerSelfCheck()
                    isCheckingLedger = false
                }
            }
            .disabled(isCheckingLedger)
            Button(L("重建账本")) {
                Task {
                    let rows = await dashboard.rebuildLedger()
                    ledgerStats = dashboard.ledgerStats()
                    ledgerIssues = nil
                    exportCaption = String(localized: L("重折了 \(rows) 行"))
                }
            }
            if let ledgerIssues {
                if ledgerIssues.isEmpty {
                    Text(L("一致。账本和全量重算逐项相同。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(MeterColor.good)
                } else {
                    ForEach(ledgerIssues, id: \.self) { issue in
                        Text(issue)
                            .font(MeterFont.footnote)
                            .foregroundStyle(MeterColor.crit)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } header: {
            Text(L("物化账本"))
        } footer: {
            Text(L("账本是快照日志按（账号 × 月）压平的一份缓存，读仪表盘时不必再扫全部快照。它随时可以整份丢掉重建——但重建结果必须和全量重算逐项相同，「跑一次对账」守的就是这条。"))
        }
    }

    private var demoModeBinding: Binding<Bool> {
        Binding(
            get: { dashboard.isDemoModeEnabled() },
            set: { enabled in
                do {
                    try dashboard.setDemoModeEnabled(enabled)
                    persistenceStatus.containsDemoData = dashboard.containsDemoData()
                    errorMessage = enabled && !dashboard.containsDemoData()
                        ? String(localized: L("库里已有数据，先清空再种子"))
                        : nil
                    exportCaption = nil
                } catch {
                    errorMessage = String(localized: L("没能写入演示数据"))
                }
            }
        )
    }

    private func seed() {
        do {
            try dashboard.setDemoModeEnabled(true)
            persistenceStatus.containsDemoData = dashboard.containsDemoData()
            errorMessage = dashboard.containsDemoData() ? nil : String(localized: L("库里已有数据，先清空再种子"))
            exportCaption = nil
        } catch {
            errorMessage = String(localized: L("没能写入演示数据"))
        }
    }

    private func clear() {
        do {
            try dashboard.clearAllData()
            persistenceStatus.containsDemoData = false
            persistenceStatus.isDemoBannerDismissed = false
            errorMessage = nil
            exportCaption = String(localized: L("已清空"))
        } catch {
            errorMessage = String(localized: L("没能清干净，请再试一次"))
        }
    }

    private func export() {
        let dump = DeveloperStoreDump.json(from: dashboard)
        SystemClipboard.copy(dump)
        print(dump)
        let count = dashboard.debugReadingCount
        TollCatLog.event("store", "exported \(count) snapshots")
        exportCaption = String(localized: L("已复制 \(count) 条 Snapshot 到剪贴板"))
        errorMessage = nil
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperDataView(dashboard: .preview, persistenceStatus: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperDataView(dashboard: .preview, persistenceStatus: .preview)
    }
    .preferredColorScheme(.dark)
}
#endif
