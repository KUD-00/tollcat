#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 一块模块的实验室页：宽壳卡四档宽度、手机列表、有小组件再看真实尺寸。
///
/// 尺寸写死，模块自己不许量。数据默认用当前账本，缺了才用设计稿。
struct DeveloperDashboardLabModuleView: View {
    var id: DashboardModuleID
    var dashboard: DashboardModel
    @State private var source: DashboardLabDataSource

    init(id: DashboardModuleID, dashboard: DashboardModel) {
        self.id = id
        self.dashboard = dashboard
        _source = State(initialValue: dashboard.has(id) ? .live : .fixture)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MeterSpacing.lg) {
                intro
                if showsEmpty {
                    ContentUnavailableView {
                        Label(id.title, systemImage: id.systemImage)
                    } description: {
                        Text(L("这块现在没有数据"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, MeterSpacing.xl)
                } else {
                    switch source {
                    case .live:
                        DeveloperDashboardLabSamples(
                            id: id,
                            contents: dashboard,
                            presentation: dashboard.moneyPresentation
                        )
                    case .fixture:
                        DeveloperDashboardLabSamples(
                            id: id,
                            contents: DashboardLabFixtures.contents,
                            presentation: .usd
                        )
                    }
                }
            }
            .padding(.horizontal, MeterSpacing.pageHorizontal)
            .padding(.top, MeterSpacing.sm)
            .padding(.bottom, MeterSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.meterGroupedBackground)
        .navigationTitle(id.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker(L("数据"), selection: $source) {
                    ForEach(DashboardLabDataSource.allCases, id: \.self) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var showsEmpty: Bool {
        switch source {
        case .live: !dashboard.has(id)
        case .fixture: false
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(id.summary)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            if id.isRetired {
                Text(L("已下架，默认不进仪表盘。"))
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if source == .fixture, !dashboard.has(id) {
                Text(L("当前账本没有这块，下面用设计稿数字。"))
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperDashboardLabModuleView(id: .budget, dashboard: .preview)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperDashboardLabModuleView(id: .heatmap, dashboard: .preview)
    }
    .preferredColorScheme(.dark)
}
#endif
