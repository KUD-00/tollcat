#if DEBUG
import SwiftUI
import MeterDesign
import MeterProviders

struct DeveloperRefreshLogView: View {
    var dashboard: DashboardModel
    @State private var exchanges: [HTTPExchange] = []
    @State private var copyCaption: String?
    @State private var query = ""

    var body: some View {
        MeterGroupedList {
            Section {
                Button(L("复制全部日志")) {
                    copyAllLogs()
                }
                if let copyCaption {
                    Text(copyCaption)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
                Button {
                    Task {
                        await dashboard.refresh()
                        reload()
                    }
                } label: {
                    Label {
                        Text(L("刷新全部用量"))
                    } icon: {
                        MeterRefreshGlyph(isRefreshing: dashboard.isRefreshing)
                    }
                }
                .meterRefreshing(dashboard.isRefreshing)
                Button(L("清空记录"), role: .destructive) {
                    inspector?.clear()
                    DeveloperDebugLog.clear()
                    reload()
                }
                if !dashboard.lastRefreshSummary.isEmpty {
                    Text(verbatim: dashboard.lastRefreshSummary)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                }
            } footer: {
                Text(L("复制刷新事件、HTTP 往返和当前 Snapshot。密钥已经打码。"))
            }

            if exchanges.isEmpty {
                Section {
                    Text(L("还没有出站请求。去仪表或服务页点刷新，再回到这里。"))
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if DeveloperRefreshLogSearch.showsEmptySearch(exchanges: exchanges, query: query) {
                ContentUnavailableView.search(text: query)
            } else {
                Section {
                    ForEach(Array(filteredExchanges.reversed())) { exchange in
                        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                            Text(verbatim: exchange.summary)
                                .font(MeterFont.footnote)
                                .foregroundStyle(Color.meterSecondaryLabel)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                            CopyBox(
                                exchange.body.isEmpty
                                    ? String(localized: L("空响应"))
                                    : exchange.body,
                                onCopy: {
                                    SystemClipboard.copy(
                                        exchange.body.isEmpty ? exchange.summary : exchange.body
                                    )
                                }
                            )
                        }
                        .accessibilityElement(children: .combine)
                    }
                } header: {
                    Text(L("HTTP 往返"))
                }
            }
        }
        // 常显搜索栏已经留了呼吸空间。insetGrouped 默认还会再垫约 35pt 顶距。
        .contentMargins(.top, MeterSpacing.xs, for: .scrollContent)
        // 默认 `.automatic` 在 iOS 26 会把搜索栏收到屏幕底部。
        // 进调试日志就是来找一条往返的，进页就该钉在导航栏下面。
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(L("搜索日志"))
        )
        // 搜的是 URL 和 JSON，不要被自动更正改掉。
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .navigationTitle(L("调试日志"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
    }

    private var filteredExchanges: [HTTPExchange] {
        DeveloperRefreshLogSearch.filtered(exchanges: exchanges, query: query)
    }

    private var inspector: InspectingHTTPClient? {
        dashboard.httpClient as? InspectingHTTPClient
    }

    private func reload() {
        exchanges = inspector?.exchanges ?? []
        copyCaption = nil
    }

    private func copyAllLogs() {
        let text = DeveloperDebugLog.exportText(dashboard: dashboard, exchanges: exchanges)
        SystemClipboard.copy(text)
        copyCaption = String(localized: L("已复制全部调试日志"))
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperRefreshLogView(dashboard: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperRefreshLogView(dashboard: .preview)
    }
    .preferredColorScheme(.dark)
}
#endif
