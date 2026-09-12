import Foundation
import Observation
import SwiftData
import SwiftUI
import MeterCore
import MeterInbox
import MeterPersistence
import MeterProviders
import MeterModules

/// 仪表的唯一状态。始终保留上次成功的数据；`isRefreshing` 只驱动工具栏，不驱动内容分支。
///
/// 干活的另有其人：SwiftData 读写在 `DashboardStore`，偏好在 `DashboardPreferences`，
/// 信箱账号在 `InboxAccount`，内容组装在 `DashboardContentsBuilder`，
/// 猫在 `CatPresenter`，刷新编排在 `RefreshCoordinator`。这里只握状态和先后次序。
@MainActor
@Observable
public final class DashboardModel {
    /// 每块内容各存一个属性，不是合成一个结构体挂在这里：
    /// `@Observable` 按属性追踪，合在一起时任何一次重算都会让读任何一块内容的视图
    /// 一起失效。而且 `apply(_:)` 只写「值真的变了」的那块——不写就等于把上一份
    /// 数组 / 字符串的存储原样留给视图，SwiftUI 一比就知道没变，整棵子树连 body
    /// 都不用重跑（Charts 的版式最吃这一下）。
    public private(set) var monthToDate: MonthToDate?
    public private(set) var monthToDateContent: MonthToDateModuleContent?
    public private(set) var compositionContent: CompositionModuleContent?
    public private(set) var comparisonContent: ComparisonModuleContent?
    public private(set) var trendContent: TrendModuleContent?
    public private(set) var anomalyContent: AnomalyModuleContent?
    public private(set) var balanceAlertContent: BalanceAlertModuleContent?
    public private(set) var upcomingChargesContent: UpcomingChargesModuleContent?
    public private(set) var freeQuotaContent: FreeQuotaModuleContent?
    public private(set) var servicesContent: ServicesModuleContent?
    public private(set) var subscriptionsContent: SubscriptionsModuleContent?
    public private(set) var heatmapContent: HeatmapModuleContent?
    public private(set) var categoriesContent: CategoriesModuleContent?
    public private(set) var superlativesContent: SuperlativesModuleContent?
    public private(set) var budgetContent: BudgetModuleContent?

    // 刷新那一组状态住在 `RefreshPipeline`，这里只转发——视图和测试照旧从模型上读。
    var isRefreshing: Bool { refreshPipeline.isRefreshing }
    /// 付费账号刷新、以及 `refresh(accountID:)` 的那一行。
    var refreshingAccountIDs: Set<AccountID> { refreshPipeline.refreshingAccountIDs }
    var refreshSuccessToken: Int { refreshPipeline.refreshSuccessToken }
    /// 接入 / 删订阅之后服务页要重读，不靠 onAppear。
    private(set) var persistenceToken = 0
    /// 「什么变了」。详情页 / 服务页的派生缓存钥匙都从这里取，见 `PresentationRevision`。
    ///
    /// 它以前是一个 `Int`（`presentationToken`），每次重算加一。那让"别家刷回来一条"
    /// 和"这一页的数字变了"变成同一件事，正在看的那一页于是跟着全量重算十几遍。
    private(set) var revision = PresentationRevision()
    var providerMarks: [AccountID: ProviderDataMark] { refreshPipeline.providerMarks }
    /// 全局刷新全部失败时的行内说明。有旧数据就留着，不弹 alert。
    var refreshFailureCaption: String? { refreshPipeline.refreshFailureCaption }
    private(set) var catMood: CatMood = .sleeping
    private(set) var catSpeech: String = ""
    var shouldPresentAddProvider = false
    /// 「壳」记着的那几件事（开场、指南、更新说明、藏猫、菜单栏）。
    /// **它们和账单一个字的关系都没有**，所以自己一个 model，见 `AppShellPreferences`。
    /// 这里只把它递出去，不再逐个转发——转发等于把职责又搬回来一半。
    public let shell: AppShellPreferences
    /// 仪表盘的取景框。改它只重算展示，不重新取数——筛选是看法，不是刷新。
    public private(set) var filter: DashboardFilter = .unfiltered
    /// 展示货币。改它只重算字，不重新取数、不改账本。
    private(set) var moneyPresentation: MoneyPresentation = .usd
    /// 当前用的目录（打包 / 缓存 / 刚拉下来的）。向导和套餐跟这份走。
    private(set) var catalog: Catalog
    /// 目录换了就加一，服务页不用自己猜该不该重读。
    private(set) var catalogRevision = 0
    let catalogResolver: CatalogResolver

    var isEmpty: Bool {
        monthToDate == nil
    }

    /// 取景框解析出来的整月窗口。「有数据以来」有多长要看手上最老的那笔数据。
    ///
    /// 算好的那一份挂在 `monthToDate.window` 上；这里是给**还没算**的地方用的
    /// （页面标题、工具栏无障碍值、筛选面板的草稿预览）。两条路解析出的是同一个
    /// 窗口，因为解析只有 `DashboardPeriod.window(now:calendar:earliestMonthsBack:)`
    /// 这一处实现。
    var filterWindow: MonthWindow {
        window(for: filter)
    }

    /// 仪表节头 / 宽壳卡小标题。绝大多数等于模块名；「之最」跟着取景框改。
    func moduleTitle(for id: DashboardModuleID) -> String {
        if id == .superlatives {
            return DashboardFilterSummary.superlativesTitle(
                period: filter.period,
                window: filterWindow,
                asOf: filter.anchor(now: clock.now, calendar: clock.calendar),
                calendar: clock.calendar
            )
        }
        return String(localized: id.title)
    }

    func window(for filter: DashboardFilter) -> MonthWindow {
        let scoped = ledger.scoped(to: filter)
        return filter.window(
            now: clock.now,
            calendar: clock.calendar,
            earliestMonthsBack: LedgerProjection.earliestMonthsBack(
                rollups: scoped.rollups,
                subscriptions: scoped.subscriptions,
                now: clock.now,
                calendar: clock.calendar
            )
        )
    }

    /// 菜单栏和 Widget 同一口径：本月、全部账号，只跟订阅开关。
    var widgetScopedMonthToDate: MonthToDate? {
        guard !ledger.isEmpty else { return nil }
        return compute(
            ledger,
            clock.now,
            clock.calendar,
            DashboardFilter(includesSubscriptions: filter.includesSubscriptions)
        )
    }

    /// 服务 tab（列表行 + 详情页）的口径：本月、全部账号、**永远含订阅**。
    ///
    /// 那两页回答的是「这家这个月要付多少」——是这家的账单事实，不是首屏的取景。
    /// 跟着仪表盘那颗「含订阅 / 仅从量」走的话，同一家的钱会按用户在别处的选择变个数；
    /// 而详情页上「按量计费」和「固定订阅」本来就是并列的两节，那个数必须把两样都算进去。
    /// 月份和排除名单同理不跟：从仪表盘排掉一家不等于这家不用付钱，
    /// 而详情页要看更早的月份，用的是它自己那排 7/30/12。
    var serviceScopedMonthToDate: MonthToDate? {
        guard !ledger.isEmpty else { return nil }
        return compute(ledger, clock.now, clock.calendar, .unfiltered)
    }

    /// 已经结束的接入。折算侧靠它把「结束月之后不再计入」这条闸落到位；
    /// 从 `connections` 推，不另存一份。
    private var endedAccounts: [AccountID: Date] {
        DashboardContentsBuilder.endedAccounts(in: connections)
    }

    /// 版式里开着的模块，按用户排的顺序；没数据的自动掉队。
    var visibleModuleIDs: [DashboardModuleID] {
        DashboardModuleID.resolvedOrder(from: layout).filter { availableModuleIDs.contains($0) }
    }

    /// 仪表盘版式（开着哪些模块、顺序、钉出的账号、预算）。
    /// 落盘在偏好里，本地镜像一份给 body 读。
    public private(set) var layout: DashboardLayout = .default

    /// 钉在侧栏底部的那一块：版式里选了、开着、有数据才算。宽壳的侧栏画它，主区跳过它。
    var sidebarModuleID: DashboardModuleID? {
        guard let raw = layout.sidebarModule, let id = DashboardModuleID(rawValue: raw), id.canSitInSidebar,
              visibleModuleIDs.contains(id)
        else { return nil }
        return id
    }

    /// 侧栏那张卡里点了一条，要仪表盘去开的路线。仪表盘看到就开、开完清掉。
    private(set) var requestedRoute: DashboardRoute?

    func requestOpen(_ route: DashboardRoute) {
        requestedRoute = route
    }

    func consumeRequestedRoute() {
        requestedRoute = nil
    }

    public private(set) var clock: MeterClock
    private var providers: [ProviderID: any BillingProvider]
    let httpClient: any HTTPClient
    private let container: ModelContainer
    /// 设置页打赏记录和仪表共用一个 SwiftData 容器，避免再开一份 store。
    var storeContainer: ModelContainer { container }
    private let credentials: any CredentialStore
    /// 读数信箱的账号面。设置页和接入交接页直接注入它，不必抓整个 model。
    let inbox: InboxAccount
    private let store: DashboardStore
    /// 物化账本的编排：什么时候折、折完那份还算不算数。见 `LedgerSync`。
    /// 折叠本身在 `LedgerCache`（输入封闭，能单独测）；这里只经过它。
    private let ledgerSync: LedgerSync
    /// 原始读数在内存里的那一份。刷新落盘之后追加，不回库里重读——
    /// 详情页那 46ms 的读盘解 blob 于是只在头一次发生。见 `ReadingCache`。
    private let readingCache: ReadingCache
    /// 环境提示的归属方。这里只**报告事实**（读失败了没有），要不要画、画成什么
    /// 由它决定——展示层不该从仪表模型里再翻出一个 error 标志各画各的。
    let persistenceStatus: PersistenceStatus
    private let preferences: DashboardPreferences
    /// 刷新管线：取数、落盘、新鲜度标记、成败记账。见 `RefreshPipeline`。
    private let refreshPipeline: RefreshPipeline
    private let catPresenter: CatPresenter
    private let compute: MonthToDateCompute
    let rateSource: SharedExchangeRates
    /// 接入列表的内存副本，`loadFromPersistence()` 时刷新。
    /// 它被 body 里的计算属性反复读，每次都开 context 全表 fetch 太贵。
    private(set) var connections: [ProviderConnectionState] = []
    private var vendorMemberships: [ProviderMembership] = []
    /// 读模型的内存副本（账本行上限 12 × 账号数，此刻状态每账号一行，读一次不心疼）。
    /// **仪表盘那一屏的全部输入就是它**——展示路径拿不到快照日志。
    ///
    /// **这里没有快照日志的内存副本。**以前 `DashboardModel` 攥着整份 `[Snapshot]`：
    /// 每次写库全表重读、每条解三个 JSON blob、指纹也从这份数组算——内存和代价都
    /// 正比于刷新次数，而账本这一层存在的理由恰恰是把代价和刷新次数脱钩。日志留在库里
    /// （`SnapshotLog`），折账本、算指纹、取原始读数都按范围去问，谁都不需要整份。
    private(set) var ledger = LedgerView()
    private(set) var subscriptions: [MonthlySubscription] = []
    /// 「什么时候把重算好的内容换上屏」。节流、补算、代号都在它里面，见 `PresentationRebuilder`。
    ///
    /// `lazy` 是为了让闭包捕获得到 `self`；`@ObservationIgnored` 是因为它不是展示状态，
    /// 而且 `@Observable` 不认 `lazy`。
    @ObservationIgnored
    private lazy var rebuilder = PresentationRebuilder { [weak self] in
        await self?.rebuildPresentationOffMain()
    }
    /// 过了午夜、或者飞到另一个时区就喊一声。见 `ClockChangeObserver`。
    private var clockChanges: ClockChangeObserver?
    #if DEBUG
    /// 开发页「刷新日志」顶上那一行。不进正式包。
    var lastRefreshSummary: String { refreshPipeline.lastRefreshSummary }
    #endif

    public init(
        providers: [ProviderID: any BillingProvider],
        container: ModelContainer,
        credentials: any CredentialStore,
        clock: MeterClock,
        inboxClient: InboxClient = .live(),
        exchangeRates: ExchangeRates? = nil,
        catalogResolver: CatalogResolver? = nil,
        rateSource: SharedExchangeRates? = nil,
        httpClient: any HTTPClient = LiveHTTPTransport.make(),
        persistenceStatus: PersistenceStatus? = nil,
        compute: @escaping MonthToDateCompute = { view, now, calendar, filter in
            // 读物化账本。「哪条读数算数」「这个月该记多少」在折叠时就判过了，
            // 这里只是把行按取景框筛一筛、加起来。
            LedgerProjection.compute(
                rollups: view.rollups,
                subscriptions: view.subscriptions,
                now: now,
                calendar: calendar,
                filter: filter
            )
        }
    ) {
        self.providers = providers
        self.httpClient = httpClient
        self.persistenceStatus = persistenceStatus
            ?? PersistenceStatus(storage: .disk, containsDemoData: false)
        self.container = container
        self.credentials = credentials
        self.inbox = InboxAccount(client: inboxClient, credentials: credentials)
        self.store = DashboardStore(container: container, credentials: credentials)
        self.ledgerSync = LedgerSync(container: container)
        self.readingCache = ReadingCache()
        self.refreshPipeline = RefreshPipeline(
            container: container,
            credentials: credentials,
            providers: providers,
            inboxClient: inboxClient
        )
        self.catPresenter = CatPresenter()
        self.clock = clock
        let resolver = catalogResolver ?? .bundledOnly()
        self.catalogResolver = resolver
        let resolved = resolver.current()
        self.catalog = resolved.localized(for: CatalogDisplay.language)
        let shared = rateSource ?? SharedExchangeRates(exchangeRates ?? resolved.exchangeRates)
        if let exchangeRates {
            shared.current = exchangeRates
        }
        self.rateSource = shared
        let preferencesStore = DashboardPreferences(container: container)
        self.preferences = preferencesStore
        let stored = preferencesStore.current
        self.compute = compute
        self.shell = AppShellPreferences(preferences: preferencesStore)
        self.filter = stored.dashboardFilter
        self.layout = stored.dashboardLayout
        self.moneyPresentation = MoneyPresentation(
            currencyCode: FeatureLaunchArguments.displayCurrency ?? stored.displayCurrency,
            rates: shared.current
        )
        #if DEBUG
        if let modules = FeatureLaunchArguments.dashboardModules {
            self.layout.order = modules
        }
        if let sidebar = FeatureLaunchArguments.sidebarModule {
            self.layout.sidebarModule = sidebar
        }
        // 「我的服务」和「预算线」的内容来自版式里的钉选和预算，不是快照。
        // 演示种子两样都没有，所以截图要它们有东西就得在这儿给。
        if let count = FeatureLaunchArguments.pinnedAccountCount, count > 0 {
            self.layout.pinnedAccounts = Array(
                ((try? store.connectionStates(calendar: clock.calendar)) ?? [])
                    .map(\.accountID)
                    .prefix(count)
            )
        }
        if let budget = FeatureLaunchArguments.monthlyBudgetUSD, budget > 0 {
            self.layout.monthlyBudgetUSD = budget
        }
        #endif
        // 首屏读的是账本（120 来行），不是快照日志——库多大都一样快。
        // 账本对不上时小库当场重折，大库先给库里那份、后台折完再换（见 `LedgerCache.load`）。
        refreshPipeline.attach(host: self)
        loadFromPersistence()
        applyLaunchArgumentFilterIfNeeded()
        // 「今天」和「本月」都会在没有任何用户操作的情况下变掉（午夜、换时区）。
        // 账本的指纹认这两样，所以喊一声就够——该不该重折它自己会判。
        clockChanges = ClockChangeObserver { [weak self] in
            guard let self else { return }
            self.rebuildPresentation()
            Task { @MainActor [weak self] in
                await self?.syncLedger()
            }
        }
    }

    func providerHistoryRange() -> ProviderHistoryRange {
        preferences.current.providerHistoryRange
    }

    func setProviderHistoryRange(_ range: ProviderHistoryRange) {
        preferences.update { $0.providerHistoryRange = range }
    }

    public func includeInGlobalRefresh(for accountID: AccountID) -> Bool {
        connections.first(where: { $0.accountID == accountID })?.includeInGlobalRefresh
            ?? false
    }

    public func setIncludeInGlobalRefresh(_ enabled: Bool, for accountID: AccountID) {
        do {
            try store.setIncludeInGlobalRefresh(enabled, for: accountID)
            persistenceStatus.didFailToWrite = false
        } catch {
            // 没写进去就说出来：`loadFromPersistence()` 会把开关读回旧值，
            // 用户看到它自己弹回去而不知道为什么。
            TollCatLog.event("store", "includeInGlobalRefresh write failed \(error)")
            persistenceStatus.didFailToWrite = true
        }
        loadFromPersistence()
    }

    func accountIDForOpenProviderDetail() -> AccountID? {
        guard let providerID = FeatureLaunchArguments.openProviderDetail else { return nil }
        return connections
            .filter { $0.providerID == providerID && $0.isLive }
            .sorted { $0.sortIndex < $1.sortIndex }
            .first?
            .accountID
    }

    public func setClock(_ clock: MeterClock) {
        self.clock = clock
        rebuildPresentation()
    }

    func billingProvider(for id: ProviderID) -> (any BillingProvider)? {
        providers[id]
    }

    public func dismissDemoBanner() {
        preferences.update { $0.isDemoBannerDismissed = true }
    }

    public func setDemoModeEnabled(_ enabled: Bool) throws {
        preferences.update { $0.isDemoModeEnabled = enabled }
        if enabled {
            try DashboardFixtureSeeder.seedBlocking(
                into: container,
                credentials: credentials,
                clock: clock
            )
            preferences.reload()
            loadFromPersistence()
            WidgetTimelineReloader.reloadAfterStoreWrite()
        }
    }

    public func seedDemoData() async throws {
        try await DashboardFixtureSeeder.seed(
            into: container,
            credentials: credentials,
            clock: clock
        )
        preferences.reload()
        loadFromPersistence()
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    /// 刚清完全部数据：空态换一句「已经清掉了」，加回第一家之后关掉。
    private(set) var didClearAllData = false

    public func clearAllData() throws {
        try StoreReset.clearAll(container: container, credentials: credentials)
        didClearAllData = true
        refreshPipeline.clearFailureCaption()
        moneyPresentation = MoneyPresentation(
            currencyCode: ExchangeRates.usdCode,
            rates: rateSource.current
        )
        loadFromPersistence()
        preferences.reload()
        shell.reload()
        let stored = preferences.current
        layout = stored.dashboardLayout
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    func requestAddProvider() {
        shouldPresentAddProvider = true
    }

    func refreshesUsageOnActivate() -> Bool {
        preferences.current.refreshesUsageOnActivate
    }

    func setRefreshesUsageOnActivate(_ enabled: Bool) {
        preferences.update { $0.refreshesUsageOnActivate = enabled }
    }

    var availableDisplayCurrencies: [String] {
        rateSource.current.displayCodes
    }

    func setDisplayCurrency(_ code: String) {
        preferences.update { $0.displayCurrency = code }
        moneyPresentation = MoneyPresentation(currencyCode: code, rates: rateSource.current)
        rebuildPresentation()
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    func reloadMoneyPresentationFromStore() {
        preferences.reload()
        moneyPresentation = MoneyPresentation(
            currencyCode: preferences.current.displayCurrency,
            rates: rateSource.current
        )
        rebuildPresentation()
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    /// 启动时后台拉一次。失败静默，打包副本和上次缓存都还在。
    func refreshCatalog() async {
        let catalog = await catalogResolver.refresh()
        applyResolvedCatalog(catalog)
    }

    func applyResolvedCatalog(_ catalog: Catalog) {
        // 拉下来的和手里那份同一版就什么都不做。照样重算一遍 13 块内容，
        // 屏幕上不会有任何变化，却正好把冷启动的进场动画掐在中间。
        guard catalog.updatedAt != self.catalog.updatedAt else { return }
        self.catalog = catalog.localized(for: CatalogDisplay.language)
        rateSource.current = catalog.exchangeRates
        moneyPresentation = MoneyPresentation(
            currencyCode: moneyPresentation.currencyCode,
            rates: rateSource.current
        )
        catalogRevision += 1
        rebuildPresentation()
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    /// 冷启动和从后台回到前台共用。花钱的服务不进，和点刷新按钮同一条规则。
    /// 亮屏 / 冷启动时的自动刷新。**只取还不新鲜的那几家**，见
    /// `RefreshCoordinator.autoRefreshTargets`。常态下这里一个目标都没有，
    /// 于是一次网络请求、一次重算都不发生——用户锁屏再解锁不该是一轮全量取数。
    func refreshUsageIfNeededOnActivate() async {
        let ids = RefreshCoordinator.autoRefreshTargets(
            connections: connections,
            now: clock.now,
            freshness: UsageRefreshOnActivate.freshness
        )
        guard UsageRefreshOnActivate.shouldRefresh(
            isEnabled: preferences.current.refreshesUsageOnActivate,
            hasCompletedOnboarding: shell.hasCompletedOnboarding,
            isAlreadyRefreshing: isRefreshing,
            hasRefreshableProviders: !ids.isEmpty
        ) else { return }
        await refreshPipeline.run(ids: ids, lock: .global, connections: connections)
    }

    public func isDemoModeEnabled() -> Bool {
        preferences.current.isDemoModeEnabled
    }

    public func containsDemoData() -> Bool {
        DemoSeedPolicy.storeContainsDemoData(container)
    }

    public func refresh() async {
        await refreshPipeline.run(
            ids: RefreshCoordinator.refreshTargets(
                connections: connections,
                includePaid: false,
                now: clock.now
            ),
            lock: .global,
            connections: connections
        )
    }

    /// `costsMoneyToRefresh` 的家不进全局刷新，只能走这里。
    /// 对方按天限流的家，间隔内已成功的也不打——再打拿不到更新的数。
    public func refresh(accountID: AccountID) async {
        let ids = RefreshCoordinator.refreshTargets(
            connections: connections.filter { $0.accountID == accountID },
            includePaid: true,
            now: clock.now
        )
        guard !ids.isEmpty else { return }
        await refreshPipeline.run(ids: ids, lock: .account(accountID), connections: connections)
    }

    /// 接入之后、详情页「拉取更多历史」。走和刷新同一把账号锁，见 `RefreshPipeline.backfill`。
    @discardableResult
    func backfillHistory(accountID: AccountID) async -> Bool {
        await refreshPipeline.backfill(accountID: accountID, connections: connections)
    }

    func exportDeviceTransfer(now: Date = Date()) throws -> TransferExport {
        try DeviceTransfer.makeExport(
            container: container,
            credentials: credentials,
            now: now,
            calendar: clock.calendar
        )
    }

    func applyImportedDeviceTransfer(
        fileBytes: Data,
        code: TransferCode,
        now: Date = Date()
    ) throws {
        try DeviceTransfer.applyImport(
            fileBytes: fileBytes,
            code: code,
            container: container,
            credentials: credentials,
            now: now,
            calendar: clock.calendar
        )
        preferences.reload()
        shell.reload()
        let stored = preferences.current
        // 版式跟着迁移包来；先换版式再重读，重算一次就用新的钉账号和预算。
        layout = stored.dashboardLayout
        loadFromPersistence()
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    /// 分享卡要的构成段。直接从 content 取，不看模块可见性。
    var compositionSegmentsForShare: [CompositionSegment] {
        compositionContent?.segments ?? []
    }

    // MARK: - 库写入（读写在 DashboardStore，这里补展示侧的尾巴）

    func applyInboxConnection(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String?,
        identityHint: String?,
        ingestKeyID: String,
        credentialReference: String
    ) throws {
        try store.applyInboxConnection(
            accountID: accountID,
            providerID: providerID,
            nickname: nickname,
            identityHint: identityHint,
            ingestKeyID: ingestKeyID,
            credentialReference: credentialReference
        )
        logConnectionWrite(accountID: accountID, providerID: providerID, nickname: nickname)
        didWrite()
    }

    func attachInbox(accountID: AccountID, ingestKeyID: String) throws {
        try store.attachInbox(accountID: accountID, ingestKeyID: ingestKeyID)
        logConnectionWrite(
            accountID: accountID,
            providerID: connections.first { $0.accountID == accountID }?.providerID ?? ProviderID(""),
            nickname: nil
        )
        didWrite()
    }

    func applyManualUsage(
        providerID: ProviderID,
        amount: Money,
        to accountID: AccountID?,
        period: Date? = nil
    ) throws {
        let calendar = clock.calendar
        let now = clock.now
        let parts = calendar.dateComponents([.year, .month], from: period ?? now)
        let id = try store.applyManualUsage(
            providerID: providerID,
            amount: amount,
            to: accountID,
            periodYear: parts.year ?? 0,
            periodMonth: parts.month ?? 0,
            now: now,
            calendar: calendar
        )
        logConnectionWrite(accountID: id, providerID: providerID, nickname: nil)
        didWrite()
    }

    func storedFields(for accountID: AccountID) -> [String: String] {
        guard let state = connections.first(where: { $0.accountID == accountID }),
              let raw = try? credentials.read(reference: state.credentialReference) else {
            return [:]
        }
        return (try? StoredCredentialFields.decode(raw)) ?? [:]
    }

    func connectionStates() -> [ProviderConnectionState] {
        connections
    }

    func memberships() -> [ProviderMembership] {
        vendorMemberships
    }

    func addMembership(_ providerID: ProviderID) throws {
        try store.addMembership(providerID)
        didClearAllData = false
        didWrite()
    }

    /// 结束这家：不再计入本月，历史一个字不动。服务页会把它挪进「历史服务」。
    func archiveMembership(_ providerID: ProviderID) async throws {
        try await revokeInboxKeys(providerID: providerID)
        // 结束：快照一条不动，变的是 `endedAccounts`——而它在账本指纹里，
        // 所以账本照样会重折。
        try store.archiveMembership(providerID, at: clock.now, calendar: clock.calendar)
        didWrite()
    }

    /// 清空本机这家的全部账单数据，历史一起走。不可撤销。
    func purgeMembership(_ providerID: ProviderID) async throws {
        try await revokeInboxKeys(providerID: providerID)
        try store.purgeMembershipRecords(providerID)
        didWrite()
    }

    private func revokeInboxKeys(providerID: ProviderID) async throws {
        let states = connections.filter { $0.providerID == providerID }
        for state in states {
            if let keyID = state.inboxIngestKeyID, !keyID.isEmpty {
                do {
                    try await inbox.revokeKey(id: keyID)
                } catch {
                    TollCatLog.event("inbox", "revoke ingest key failed \(keyID) \(error)")
                }
            }
        }
    }

    /// 读失败不是「没有订阅」：如实亮 `didFailToRead`，只是这一处没有上一份可以留。
    func subscriptionItems() -> [ManualSubscriptionItem] {
        do {
            return try store.subscriptionItems(now: clock.now, calendar: clock.calendar)
        } catch {
            persistenceStatus.didFailToRead = true
            return []
        }
    }

    func applyConnection(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String?,
        identityHint: String?,
        remoteIdentityFingerprint: String?,
        fields: [String: String],
        snapshots incoming: [Snapshot],
        mode: ConnectionWriteMode
    ) throws {
        try store.applyConnection(
            accountID: accountID,
            providerID: providerID,
            nickname: nickname,
            identityHint: identityHint,
            remoteIdentityFingerprint: remoteIdentityFingerprint,
            fields: fields,
            snapshots: incoming,
            mode: mode,
            calendar: clock.calendar
        )
        logConnectionWrite(accountID: accountID, providerID: providerID, nickname: nickname)
        didWrite()
    }

    func updateAccountNickname(_ nickname: String?, for accountID: AccountID) throws {
        try store.updateAccountNickname(nickname, for: accountID)
        loadFromPersistence()
    }

    func collidingConnection(
        providerID: ProviderID,
        fingerprint: String?,
        fields: [String: String],
        excluding accountID: AccountID?
    ) -> ProviderConnectionState? {
        let others = connections.filter {
            $0.providerID == providerID && $0.accountID != accountID
        }
        if let fingerprint {
            return others.first { $0.remoteIdentityFingerprint == fingerprint }
        }
        for other in others {
            let stored = storedFields(for: other.accountID)
            if AccountFingerprint.secretsCollide(fields, stored) {
                return other
            }
        }
        return nil
    }

    /// 结束一份用量身份。凭据删掉、不再刷新，但这一份刷出来的历史留着——
    /// 删行会让它的快照变成孤儿，过去几个月的数字跟着塌。
    func removeConnection(accountID: AccountID) async throws {
        guard let state = connections.first(where: { $0.accountID == accountID }) else { return }
        if let keyID = state.inboxIngestKeyID, !keyID.isEmpty {
            do {
                try await inbox.revokeKey(id: keyID)
            } catch {
                TollCatLog.event("inbox", "revoke ingest key failed \(keyID) \(error)")
            }
        }
        try store.archiveConnectionRecord(accountID: accountID, at: clock.now, calendar: clock.calendar)
        didWrite()
    }

    func applySubscription(_ subscription: MonthlySubscription) throws {
        try store.applySubscription(subscription, calendar: clock.calendar)
        didWrite()
    }

    func updateSubscription(id: PersistentIdentifier, _ subscription: MonthlySubscription) throws {
        try store.updateSubscription(id: id, subscription, calendar: clock.calendar)
        didWrite()
    }

    /// 真删，会改写历史。界面上只该是「录错了」那条路。
    func removeSubscription(id: PersistentIdentifier) throws {
        try store.removeSubscription(id: id)
        didWrite()
    }

    func markStaleForPreview(_ id: AccountID) {
        refreshPipeline.markStale(id)
        rebuildPresentation()
    }


    // MARK: - 版式

    /// 换版式：只重算展示（钉出的账号、预算会改内容），不重新取数。
    func setLayout(_ newValue: DashboardLayout) {
        guard newValue != layout else { return }
        layout = newValue
        preferences.update { $0.dashboardLayout = newValue }
        rebuildPresentation()
    }

    /// 开着的模块按新顺序（不含本月合计）。
    func setModuleOrder(_ order: [DashboardModuleID]) {
        var next = layout
        next.order = order.filter { !$0.isPinned }.map(\.rawValue)
        setLayout(next)
    }

    func setModule(_ id: DashboardModuleID, enabled: Bool) {
        guard !id.isPinned else { return }
        var enabledIDs = DashboardModuleID.resolvedOrder(from: layout).filter { !$0.isPinned }
        if enabled, !enabledIDs.contains(id) {
            enabledIDs.append(id)
        } else if !enabled {
            enabledIDs.removeAll { $0 == id }
        }
        setModuleOrder(enabledIDs)
    }

    func setPinnedAccounts(_ accounts: [AccountID]) {
        var next = layout
        next.pinnedAccounts = accounts
        setLayout(next)
    }

    func setMonthlyBudget(_ usd: Decimal?) {
        var next = layout
        next.monthlyBudgetUSD = usd
        setLayout(next)
    }

    func setSidebarModule(_ id: DashboardModuleID?) {
        var next = layout
        next.sidebarModule = id?.rawValue
        setLayout(next)
    }

    /// 库里写完东西之后的固定尾巴：仪表重读 + Widget 重画。
    ///
    /// 重读的是接入 / 成员 / 订阅 / 账本——都是小表。快照日志不在这里，
    /// 也不在任何地方被整份读出来。
    private func didWrite() {
        // **改写和删除只能走这一条路。** 读数缓存只会「多一条」，
        // 手填改了金额、删了一家、导入了另一台机器的库，它都认不出来。
        readingCache.invalidate()
        loadFromPersistence()
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    private func loadFromPersistence() {
        do {
            connections = try store.connectionStates(calendar: clock.calendar)
            vendorMemberships = try store.memberships()
            subscriptions = try store.fetchSubscriptions(calendar: clock.calendar)
            // **账本也在这个 do 里。**它以前不在：账本两张表读失败被吞成一份空的
            // `LedgerView`，仪表当场进空态写着「还没有账单」，而 `didFailToRead`
            // 仍然是 false。规则本来就写对了，只是没写到自己新建的那一层上。
            ledgerSync.noteStoreWrite()
            ledger = try ledgerSync.load(ledgerInputs)
        } catch {
            // **读失败不是「没有数据」。**
            //
            // 清成空数组会连着两件事一起做错：屏幕当场报 $0（SPEC 明令禁止），
            // 而紧接着那次同步会拿这份空的去重折，把磁盘上的账本一并抹掉——
            // 一次临时的读失败于是变成一次不可逆的数据损失。
            //
            // 所以这里什么都不动：手里那份哪怕是旧的也留着，账本这一趟不碰，
            // 只把「读不出来」如实说出去。`DashboardStore` 的读一律 `throws`，
            // 所以任何一张表读失败都会落到这里，而不是在下面一层被吞成空数组。
            persistenceStatus.didFailToRead = true
            persistenceToken += 1
            rebuildPresentation()
            return
        }
        persistenceStatus.didFailToRead = false
        // 有读数的账号一律先当「新鲜」：刷新失败的标记只在刷新路径上打，不在这里。
        refreshPipeline.resetMarks(currentAccounts: ledger.latest.map(\.accountID))
        persistenceToken += 1
        rebuildPresentation()
        // 同步收在这一处，而不是散在九个调用点上。**这条曾经漏掉过**：
        // 只在启动时同步一次的话，演示种子 / 迁移导入 / 清库都是先写库再
        // `loadFromPersistence()`，那之后没有人再去折，账本永远停在 0 行。
        Task { @MainActor [weak self] in
            await self?.syncLedger()
        }
    }

    // MARK: - 物化账本

    /// **门上明确开的那个口**：几个账号的原始读数。
    ///
    /// 详情页那几张图展示的就是「这家自己报过什么」——原始观测，不是折算结果。
    /// 账本回答不了它（账本是压平之后的账），所以这里给的是真读数。
    ///
    /// 但**范围由门决定**：调用方说要哪一段，不是拿到全部自己挑。
    /// 「哪条读数算数」这条规则于是仍然只有一个出处。范围直接落成一条带
    /// predicate 的查询——没有哪一步需要先把整份日志读进内存再筛。
    ///
    /// `since` **没有默认值**：门开着但谁都不说范围的话，「范围由门决定」
    /// 就只是一句注释。要全史请走 DEBUG 的 `debugAllReadings()`，它有名字。
    func readings(for accountIDs: Set<AccountID>, since: Date?) -> ReadingSeries {
        let interval = since.map { DateInterval(start: $0, end: clock.now) }
        let readings: [Snapshot]
        if let since {
            // 有起点的才进缓存：无起点是「全史」，只有 DEBUG 的 dump 走那条路。
            readings = readingCache.readings(accountIDs: accountIDs, since: since) {
                ledgerSync.readings(accountIDs: accountIDs, since: since, calendar: clock.calendar)
            }
        } else {
            readings = ledgerSync.readings(accountIDs: accountIDs, since: nil, calendar: clock.calendar)
        }
        return ReadingSeries(accountIDs: accountIDs, interval: interval, readings: readings)
    }

    #if DEBUG
    /// 整份日志，只给开发页的 dump 和试验台——它们就是要看原始记录。不进正式包。
    func debugAllReadings() -> [Snapshot] {
        ledgerSync.allReadings(calendar: clock.calendar)
    }

    var debugReadingCount: Int {
        ledgerSync.snapshotCount()
    }
    #endif

    /// 某个账号某个月已经手填过的金额。抽屉预填那一栏用它。
    ///
    /// 直接问手填那张表，不绕快照——手填花费本来就是自己一张表，
    /// 从它折出来的快照只是给折算用的副产物。
    func manualUsageAmount(accountID: AccountID, period: Date) -> Money? {
        let components = clock.calendar.dateComponents([.year, .month], from: period)
        guard let year = components.year, let month = components.month else { return nil }
        let context = ModelContext(container)
        let records = (try? ManualUsageStore.all(in: context)) ?? []
        return records
            .first {
                $0.accountIDRaw == accountID.rawValue.uuidString
                    && $0.periodYear == year
                    && $0.periodMonth == month
            }
            .map { Money(usd: $0.amountUSD) }
    }

    /// 折账本要的那一套输入。**一次凑齐**——散着传迟早有一处漏掉，
    /// 而漏掉的表现是账本和重算差一笔钱，不是崩溃。
    private var ledgerInputs: LedgerCache.Inputs {
        LedgerCache.Inputs(
            // 还在用的账号（含结束的：历史要留）。真删的不在——它们的快照是孤儿。
            accountIDs: Set(connections.filter(\.isEnabled).map(\.accountID)),
            subscriptions: subscriptions,
            endedAccounts: endedAccounts,
            now: clock.now,
            calendar: clock.calendar
        )
    }

    /// 账本和库里的读数对不上就整份重折，然后把读模型换成库里那份。
    ///
    /// **判「作不作数」和补折都在这里**，不在 `load`：那两件事一个要全表扫快照
    /// 算指纹、一个要解几千个 blob，代价正比于刷新总次数。首屏先给库里那份
    /// （最坏是旧一天），这一趟折完再换。
    func syncLedger() async {
        do {
            // 回 nil = 不用换（已经对得上，或者期间库又变过了）。见 `LedgerSync`。
            guard let loaded = try await ledgerSync.sync(ledgerInputs) else { return }
            ledger = loaded
            rebuildPresentation()
            // **换了账本就得喊 Widget。**主屏那格读的是库里的账本行；
            // `didWrite` 那一刻折还没做完，它读到的是折叠前的行。不喊的话
            // App 内数字对了、主屏一直停在旧数字，直到下一次写库或刷新。
            WidgetTimelineReloader.reloadAfterStoreWrite()
        } catch {
            reportLedgerFailure(error)
        }
        // 压缩排在同步**之后**：先折后删（SPEC 12.5）。这一趟失败不影响任何数字，
        // 所以不亮读失败标志，只记一行日志。
        do {
            // 压缩是**删除**。内存里那份读数只认得「多了一条」，删掉的它自己
            // 发现不了——不扔的话，历史曲线上还画着已经不在库里的点。
            if try await ledgerSync.compactIfDue(ledgerInputs) > 0 {
                readingCache.invalidate()
            }
        } catch {
            TollCatLog.event("ledger", "compact failed \(error)")
        }
    }

    /// 落了一条新快照之后的增量维护：只重折**这个账号**，别的账号不碰。
    private func applyToLedger(_ snapshot: Snapshot) async {
        do {
            guard let loaded = try await ledgerSync.apply(snapshot, ledgerInputs) else { return }
            ledger = loaded
        } catch {
            reportLedgerFailure(error)
        }
    }

    /// 整份重建，不看对不对得上。开发页那个按钮走它。
    @discardableResult
    func rebuildLedger() async -> Int {
        do {
            let written = try await ledgerSync.rebuild(ledgerInputs)
            ledger = try ledgerSync.load(ledgerInputs)
            rebuildPresentation()
            return written
        } catch {
            reportLedgerFailure(error)
            return 0
        }
    }

    /// 账本这一路失败了：**手里那份留着**，只把「读不出来」如实说出去。
    /// 换成空的会让屏幕报「还没有账单」，而磁盘上的数据一条不少。
    private func reportLedgerFailure(_ error: any Error) {
        TollCatLog.event("ledger", "sync failed \(error)")
        persistenceStatus.didFailToRead = true
        rebuildPresentation()
    }

    #if DEBUG
    /// 开发页那一节要的三个数。不进正式包。
    func ledgerStats() -> (rows: Int, inSync: Bool, isReadPath: Bool) {
        // 读不出来时 -1 行：0 是「真的一行都没有」，开发页得分得出来。
        guard let stats = try? ledgerSync.stats(ledgerInputs) else {
            return (-1, false, !ledger.rollups.isEmpty)
        }
        return (stats.rows, stats.inSync, !ledger.rollups.isEmpty)
    }

    /// 拿库里那份账本和全量重算逐项对一遍，几种取景框各来一次。
    ///
    /// **这是整个物化账本方案能不能信的凭据。**返回空数组才叫一致；
    /// 任何一行都意味着屏幕上某个数字会因为"从哪条路读的"而不同。
    func runLedgerSelfCheck() async -> [String] {
        let excluded = connections.filter(\.isEnabled).first.map { Set([$0.accountID]) } ?? []
        return await ledgerSync.selfCheck(ledgerInputs, excludedAccounts: excluded)
    }
    #endif

    /// 同步重算。交互路径（改取景框 / 改版式 / 库里写完）走它——那些调用方紧接着
    /// 就读 content，异步化会让「改完立刻读」的行为跟着变。
    private func rebuildPresentation() {
        #if DEBUG
        let buildStarted = ContinuousClock.now
        #endif
        _ = rebuilder.beginBuild()
        let built = DashboardContentsBuilder.make(contentInputs())
        #if DEBUG
        logRebuild(since: buildStarted, offMain: false)
        #endif
        // **`global` 只在这条同步路径上加。** 走到这里的都是交互 / 写库路径：
        // 加接入、手填、改订阅、换货币、换取景框、目录换代、历史回填。它们本来就该
        // 让每一屏重算，而且都是一次点击一次，不在热路径上。
        //
        // 刷新那条路（`rebuildPresentationOffMain`）**不加这一格**——它只动
        // `providers` 里自己那一家，见 `refreshDidPersist`。
        revision.noteGlobalChange()
        apply(built.contents, runways: built.runways)
    }

    /// 刷新路径的重算：13 块内容全是纯值计算，搬到后台线程算，算完回主线程赋值。
    /// 主线程于是只剩「赋值 + 重画变了的那几块」，进场动画不会再被一次次掐住。
    private func rebuildPresentationOffMain() async {
        #if DEBUG
        let buildStarted = ContinuousClock.now
        #endif
        let token = rebuilder.beginBuild()
        let inputs = contentInputs()
        let built = await Task.detached(priority: .userInitiated) {
            DashboardContentsBuilder.make(inputs)
        }.value
        // 等这一下的期间又请求过重算（下一家回来了、或者用户改了取景框）：这份已经过期。
        // 丢掉不补也没关系——那次重算自己会上屏，节流那边的「还欠一次」也还立着。
        guard rebuilder.isCurrent(token) else { return }
        #if DEBUG
        logRebuild(since: buildStarted, offMain: true)
        #endif
        apply(built.contents, runways: built.runways)
    }

    private func contentInputs() -> DashboardContentInputs {
        DashboardContentInputs(
            view: ledger,
            filter: filter,
            now: clock.now,
            calendar: clock.calendar,
            presentation: moneyPresentation,
            connections: connections,
            providerMarks: providerMarks,
            layout: layout,
            compute: compute
        )
    }

    private func apply(_ built: DashboardContents, runways: [PrepaidRunway]) {
        apply(built)
        rebuilder.didBuild()
        applyCatPresentation(runways: runways)
    }

    #if DEBUG
    private func logRebuild(since started: ContinuousClock.Instant, offMain: Bool) {
        let elapsedMs = Int((ContinuousClock.now - started) / .milliseconds(1))
        let where_ = offMain ? "offmain" : "main"
        TollCatLog.event("dashboard", "rebuild \(where_) \(elapsedMs)ms rows=\(ledger.rollups.count)")
    }
    #endif

    /// 逐块赋值。写进 `@Observable` 的属性就等于让读它的视图失效，所以只写变了的那块。
    /// 刷新时通常只有一两家的数字动，热力图、订阅、目录分组那几块内容一模一样。
    private func apply(_ built: DashboardContents) {
        if monthToDate != built.monthToDate { monthToDate = built.monthToDate }
        if monthToDateContent != built.monthToDateContent { monthToDateContent = built.monthToDateContent }
        if compositionContent != built.compositionContent { compositionContent = built.compositionContent }
        if comparisonContent != built.comparisonContent { comparisonContent = built.comparisonContent }
        if trendContent != built.trendContent { trendContent = built.trendContent }
        if anomalyContent != built.anomalyContent { anomalyContent = built.anomalyContent }
        if balanceAlertContent != built.balanceAlertContent { balanceAlertContent = built.balanceAlertContent }
        if upcomingChargesContent != built.upcomingChargesContent { upcomingChargesContent = built.upcomingChargesContent }
        if freeQuotaContent != built.freeQuotaContent { freeQuotaContent = built.freeQuotaContent }
        if servicesContent != built.servicesContent { servicesContent = built.servicesContent }
        if subscriptionsContent != built.subscriptionsContent { subscriptionsContent = built.subscriptionsContent }
        if heatmapContent != built.heatmapContent { heatmapContent = built.heatmapContent }
        if categoriesContent != built.categoriesContent { categoriesContent = built.categoriesContent }
        if superlativesContent != built.superlativesContent { superlativesContent = built.superlativesContent }
        if budgetContent != built.budgetContent { budgetContent = built.budgetContent }
    }


    // MARK: - 取景框

    /// 换取景框：只重算展示，不重新取数。
    ///
    /// 排除名单会先按当前接入列表剪一遍——留着已删服务的 id 会变成哑弹，
    /// 重新接入之后它莫名不在总数里，而筛选面板上没有那一行可以取消。
    func setFilter(_ newValue: DashboardFilter) {
        let connected = Set(connections.filter(\.isEnabled).map(\.accountID))
        let pruned = newValue.pruned(to: connected)
        guard pruned != filter else { return }
        filter = pruned
        preferences.update { $0.dashboardFilter = pruned }
        // **取景框改动不再同步重算。**
        //
        // 换个看法本来就不该等：`filter` 这一行赋值已经让界面上的选中态、标题、
        // 限定语立刻跟上，剩下的十几块内容搬到后台算完再整体换掉。
        // 连点几颗 chip 时，`PresentationRebuilder` 的代号会把中途那几份作废，只有最后一次上屏。
        //
        // （以前这里是同步的，理由是"调用方紧接着要读 content"。真去数了一遍：
        // 生产上两个调用方——筛选面板按完就关、订阅口径那颗切换靠 @Observable 重画——
        // 都不读；详情页那几条测试读的是 `serviceScopedMonthToDate`，它压根不看取景框。）
        Task { @MainActor [weak self] in
            await self?.rebuildPresentationOffMain()
        }
        // Widget 跟落盘的订阅口径走，偏好写完得喊它重读。
        WidgetTimelineReloader.reloadAfterStoreWrite()
    }

    /// 首屏大数字旁那颗口径切换。走 `setFilter`，和筛选抽屉是同一份状态——
    /// 两处永远说同一个口径，也一起落盘。
    func setIncludesSubscriptions(_ includesSubscriptions: Bool) {
        var next = filter
        next.includesSubscriptions = includesSubscriptions
        setFilter(next)
    }

    /// 截图和验收用的覆盖值。**不落盘**——调试钩子不该改用户的真实偏好。
    /// `-filter-exclude=` 仍是厂商 raw key，落到当前已接的全部 AccountID。
    private func applyLaunchArgumentFilterIfNeeded() {
        let monthsBack = FeatureLaunchArguments.filterMonthsBack
        let excludedKeys = FeatureLaunchArguments.filterExcludedProviderKeys
        let dropsSubscriptions = FeatureLaunchArguments.filterDropsSubscriptions
        guard monthsBack != nil || !excludedKeys.isEmpty || dropsSubscriptions else { return }
        let providers = Set(excludedKeys.map(ProviderID.init(rawValue:)))
        let excludedAccounts = Set(
            connections
                .filter { $0.isLive && providers.contains($0.providerID) }
                .map(\.accountID)
        )
        filter = DashboardFilter(
            monthsBack: monthsBack ?? 0,
            includesSubscriptions: !dropsSubscriptions,
            excludedAccounts: excludedAccounts
        )
        rebuildPresentation()
    }

    // MARK: - 猫

    /// 重算路径带着现成的跑道进来；单独拧猫的开关时走无参版自己算一次。
    private func applyCatPresentation(runways: [PrepaidRunway]) {
        let hasAnyProvider = !vendorMemberships.isEmpty
            || connections.contains(where: \.isLive)
        let hasStale = providerMarks.values.contains { $0 == .stale || $0 == .failed }
            || (monthToDate?.facts.contains { $0.type == .fetchFailed } ?? false)
        catPresenter.present(
            CatPresenter.Input(
                monthToDate: monthToDate,
                hasAnyProvider: hasAnyProvider,
                hasStaleData: hasStale,
                runways: runways,
                presentation: moneyPresentation
            )
        ) { [weak self] mood, speech in
            guard let self else { return }
            self.catMood = mood
            self.catSpeech = speech
        }
    }

    private func applyCatPresentation() {
        let scoped = ledger.scoped(to: filter)
        let runways = filter.showsPresentTenseModules
            ? PrepaidRunwayCalculator.compute(
                latest: scoped.latest,
                rollups: scoped.rollups,
                now: clock.now,
                calendar: clock.calendar
            )
            : []
        applyCatPresentation(runways: runways)
    }

    private func logConnectionWrite(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String?
    ) {
        #if DEBUG
        TollCatLog.event(
            "store",
            "connection \(accountID.rawValue.uuidString) \(providerID.rawValue) nickname=\(nickname ?? "")"
        )
        #else
        TollCatLog.event(
            "store",
            "connection \(accountID.rawValue.uuidString) \(providerID.rawValue)"
        )
        #endif
    }
}

/// 刷新管线要宿主配合的几步。都是模型自己的状态：账本增量、connections 盖章、展示重算。
extension DashboardModel: RefreshPipelineHost {
    var refreshCalendar: Calendar { clock.calendar }

    func refreshDidPersist(_ snapshot: Snapshot, for id: AccountID) async {
        ledgerSync.noteStoreWrite()
        await applyToLedger(snapshot)
        // 内存里那份跟着追加一条，不回库里重读整段——和账本只重折这一个账号同一招。
        readingCache.append(snapshot)
        // **只动这一家那一格。** 别家的详情页钥匙不变，它们的缓存继续命中。
        revision.noteReading(for: snapshot.providerID)
        guard snapshot.hasBillableMetrics else { return }
        // 刷新不走 loadFromPersistence：那会把失败标记洗成 current。
        // 盖章必须写回内存里的 connections，否则服务页还拿着上次的时间。
        connections = connections.map { state in
            guard state.accountID == id else { return state }
            var next = state
            next.lastSuccessfulRefreshAt = snapshot.fetchedAt
            return next
        }
    }

    /// 这家的新鲜度标记变了。**成功、陈旧、失败都要喊。**
    ///
    /// 漏掉失败那一路的表现很隐蔽：刷新失败时 `providerMarks` 变了、行上该亮
    /// 「陈旧」，但钥匙没动，详情页的 `row` 缓存继续命中，那一页于是永远不亮标记。
    func refreshDidMark(_ id: AccountID) {
        guard let providerID = connections.first(where: { $0.accountID == id })?.providerID else {
            return
        }
        revision.noteReading(for: providerID)
    }

    func refreshHasBillableReading(_ id: AccountID) -> Bool {
        ledgerSync.hasBillableReading(accountID: id)
    }

    /// 账本里有这家的「此刻」行，就说明它曾经读到过数。
    func refreshHasAnyReading(_ id: AccountID) -> Bool {
        ledger.latest.contains { $0.accountID == id }
    }

    func refreshWillStart() {
        rebuilder.noteRefreshWillStart()
    }

    func refreshRebuildThrottled() async {
        await rebuilder.requestThrottled()
    }

    func refreshFlushPendingRebuild() async {
        await rebuilder.flush()
    }

    func refreshRebuildNow() {
        rebuildPresentation()
    }
}

extension DashboardModel {
    public static var preview: DashboardModel {
        makePreview(seedFixtures: true)
    }

    public static var previewEmpty: DashboardModel {
        makePreview(seedFixtures: false)
    }

    /// DESIGN-BAR 用的同厂商两行。不进演示种子。
    public static var previewTwoCloudflare: DashboardModel {
        let model = makePreview(seedFixtures: true)
        let connections = model.connectionStates()
        guard let first = connections.first(where: { $0.providerID == .cloudflare }) else {
            return model
        }
        try? model.updateAccountNickname(String(localized: L("工作")), for: first.accountID)
        let second = AccountID(rawValue: UUID())
        // 演示种子只铺当月，一个月的范围足够拿到最新那条。
        var snapshot = model.readings(
            for: [first.accountID],
            since: model.clock.calendar.date(byAdding: .month, value: -1, to: model.clock.now)
        ).last
        snapshot?.accountID = second
        snapshot?.currentSpendUSD = Money(roundedUSD: 3.20)
        try? model.applyConnection(
            accountID: second,
            providerID: .cloudflare,
            nickname: String(localized: L("个人")),
            identityHint: nil,
            remoteIdentityFingerprint: "preview-cf-personal",
            fields: [
                CredentialField.apiToken.rawValue: "demo-token-2",
                CredentialField.accountID.rawValue: "demo-account-2",
            ],
            snapshots: snapshot.map { [$0] } ?? [],
            mode: .create
        )
        return model
    }

    public static func makePreview(
        seedFixtures: Bool,
        clock: MeterClock = .design
    ) -> DashboardModel {
        let container = try! PersistenceContainer.makeContainer(inMemory: true)
        let credentials = InMemoryCredentialStore()
        let httpClient = StubHTTPClient()
        let catalogResolver = CatalogResolver.bundledOnly()
        let rateSource = SharedExchangeRates(catalogResolver.current().exchangeRates)
        let providers = ProviderAssembly.make(
            now: { clock.now },
            calendar: clock.calendar,
            httpClient: httpClient,
            rateSource: rateSource
        )
        if seedFixtures {
            try! DashboardFixtureSeeder.seedBlocking(
                into: container,
                credentials: credentials,
                clock: clock
            )
        }
        let model = DashboardModel(
            providers: providers,
            container: container,
            credentials: credentials,
            clock: clock,
            catalogResolver: catalogResolver,
            rateSource: rateSource,
            httpClient: httpClient
        )
        model.shell.completeOnboarding()
        return model
    }
}

#Preview("DashboardModel · Light") {
    @Previewable @State var model = DashboardModel.preview
    DashboardView(model: model)
        .preferredColorScheme(.light)
}

#Preview("DashboardModel · Dark") {
    @Previewable @State var model = DashboardModel.preview
    DashboardView(model: model)
        .preferredColorScheme(.dark)
}

#Preview("DashboardModel · Empty") {
    @Previewable @State var model = DashboardModel.previewEmpty
    DashboardView(model: model)
}

/// 模型是主线程上的界面状态，`DashboardContents` 是可以跨线程的值。
/// 两边都实现 `DashboardModuleContents`，「有哪些模块可摆」才只有一份判断——
/// 这一份是主线程隔离的那个实现（`@MainActor` 一致性）。
extension DashboardModel: @MainActor DashboardModuleContents {}
