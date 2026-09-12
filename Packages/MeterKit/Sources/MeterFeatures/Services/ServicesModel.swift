import Foundation
import Observation
import MeterCore
import MeterPersistence
import MeterProviders

/// 服务页状态。刷新和写入都走 `DashboardModel`，避免两套快照各算各的。
@MainActor
@Observable
final class ServicesModel {
    private(set) var rows: [ServiceRowItem] = []
    private(set) var manualSubscriptions: [ManualSubscriptionItem] = []
    var sort: ServiceListSort = .kind

    var connectedRows: [ServiceRowItem] {
        rows.filter { $0.isConnected && !$0.isEnded }
    }

    /// 已经结束的服务。单开一节挪到最下面——它们不再花钱，但过去几个月的账里
    /// 有它们，删掉才是真的把历史抹了。
    var endedRows: [ServiceRowItem] {
        rows.filter(\.isEnded)
    }

    /// 有东西可以进「历史服务」那一页。没有就不出那一行。
    var hasPastRecords: Bool {
        !endedRows.isEmpty || !endedManualSubscriptions.isEmpty
    }

    /// 已经退掉的独立手动订阅（没有进服务列表的那种）。
    var endedManualSubscriptions: [ManualSubscriptionItem] {
        manualSubscriptions.filter(\.hasEnded)
    }

    /// 还在付的独立手动订阅。
    var activeManualSubscriptions: [ManualSubscriptionItem] {
        manualSubscriptions.filter { !$0.hasEnded }
    }

    var arrangedSections: [ServiceListSection] {
        ServiceListArrangement.sections(from: connectedRows, sort: sort)
    }

    /// 分组排序下多于一组才画小标题。一组标题是废话。
    var usesSectionTitles: Bool {
        switch sort {
        case .kind: Set(connectedRows.map(\.kind)).count > 1
        case .category: Set(connectedRows.map(\.category)).count > 1
        case .price: false
        }
    }

    var isFullyEmpty: Bool {
        dashboard.memberships().isEmpty && manualSubscriptions.isEmpty && catalogNotices.isEmpty
    }

    var selectedProviderID: ProviderID?
    private(set) var catalogNotices: [Notice] = []
    private(set) var catalog: Catalog
    /// 添加服务和接入向导。iPad 列表 / 详情是两份 View，靠这个同步，不要各弹一张抽屉。
    var setupPath: [ServicesRoute] = []

    var dashboard: DashboardModel

    var isRefreshing: Bool { dashboard.isRefreshing }
    var refreshSuccessToken: Int { dashboard.refreshSuccessToken }

    private let catalogSource: any CatalogSource

    init(dashboard: DashboardModel, catalogSource: (any CatalogSource)? = nil) {
        self.dashboard = dashboard
        self.catalogSource = catalogSource ?? dashboard.catalogResolver
        self.catalog = Catalog(
            schemaVersion: CatalogCodec.supportedSchemaVersion,
            updatedAt: .distantPast,
            guides: [:],
            plans: [],
            notices: []
        )
        reload()
    }

    func loadCatalog() async {
        do {
            catalog = try await catalogSource.load().localized(for: CatalogDisplay.language)
        } catch {
            catalog = Catalog(
                schemaVersion: CatalogCodec.supportedSchemaVersion,
                updatedAt: .distantPast,
                guides: [:],
                plans: [],
                notices: []
            )
        }
        catalogNotices = catalog.notices.filter { $0.providerID == nil }
        reload()
    }

    /// 上一次 `reload()` 的输入指纹。onAppear、persistenceToken、refreshSuccessToken、
    /// 关抽屉、清导航栈都各挂了一个 reload——一次交互常常连响好几下，
    /// 而输入没变时全量重建就是白做。展示输入收口在 `dashboard.revision`；
    /// 再搭一个分钟桶，让「3 分钟前」这类相对时间字样回到页面时最多旧一分钟。
    ///
    /// 这一页列的是**所有**厂商，所以钥匙要整份版本，不是某一家那一格。
    @ObservationIgnored private var lastReloadStamp: (revision: PresentationRevision, minute: Int)?

    func reload() {
        let stamp = (
            revision: dashboard.revision,
            minute: Int(dashboard.clock.now.timeIntervalSinceReferenceDate / 60)
        )
        if let last = lastReloadStamp, last == stamp { return }
        lastReloadStamp = stamp
        rows = ServiceRowBuilder.rows(
            memberships: dashboard.memberships(),
            connections: dashboard.connectionStates(),
            latest: dashboard.ledger.latestByAccount(),
            // 列表行和详情页同一个口径，不跟仪表盘的取景框——
            // 见 `DashboardModel.serviceScopedMonthToDate`。
            monthToDate: dashboard.serviceScopedMonthToDate,
            marks: dashboard.providerMarks,
            subscriptions: dashboard.subscriptions,
            now: dashboard.clock.now,
            calendar: dashboard.clock.calendar,
            presentation: dashboard.moneyPresentation
        )
        let members = Set(dashboard.memberships().map(\.providerID))
        manualSubscriptions = dashboard.subscriptionItems().filter { item in
            guard let providerID = item.providerID else { return true }
            return !members.contains(providerID)
        }
    }

    func refreshAll() async {
        await dashboard.refresh()
        reload()
    }

    /// 真删。**会改写历史**——这笔钱从过去每一个月里一起消失。
    /// 只给「录错了」用；不订了在编辑页填一个结束月。
    func deleteSubscription(_ item: ManualSubscriptionItem) {
        try? dashboard.removeSubscription(id: item.id)
        reload()
    }

    static var preview: ServicesModel {
        ServicesModel(dashboard: .preview)
    }

    static var previewEmpty: ServicesModel {
        ServicesModel(dashboard: .previewEmpty)
    }

    static var previewStale: ServicesModel {
        let dashboard = DashboardModel.preview
        if let id = dashboard.connectionStates().first(where: { $0.providerID == .cloudflare })?.accountID {
            dashboard.markStaleForPreview(id)
        }
        return ServicesModel(dashboard: dashboard)
    }

    static var previewTwoCloudflare: ServicesModel {
        ServicesModel(dashboard: .previewTwoCloudflare)
    }
}
