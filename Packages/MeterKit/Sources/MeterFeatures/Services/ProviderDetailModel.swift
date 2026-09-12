import Foundation
import Observation
import SwiftData
import MeterCore
import MeterPersistence
import MeterProviders

@MainActor
@Observable
final class ProviderDetailModel {
    let providerID: ProviderID
    var dashboard: DashboardModel
    var isConfirmingDelete = false
    var isBackfillingHistory = false
    var historyBackfillCaption: LocalizedStringResource?
    var historyRange: ProviderHistoryRange
    /// 明细分组维度。只活在这一屏，不落库——换个分组不值得写偏好。
    var breakdownGrouping: SpendBreakdownGrouping = .category

    /// 派生缓存。`row` / `history` / `breakdown` / `chartContent` 都是
    /// 「重算一遍全量数据」级别的活，而 body 一次求值会问它们好几遍。
    ///
    /// 钥匙统一以 `dashboard.revision.scoped(to: providerID)` 打底：**只含这一家
    /// 那一格**，别家刷回来时它一个字都不变（见 `PresentationRevision`）。
    /// 这把钥匙以前是全局的一个数，于是全局刷新期间这十二个缓存跟着一起作废
    /// 十几遍——实测一次亮屏刷新让这一页重算 26 遍、占主线程 1620ms。
    ///
    /// **有第二个输入的必须写进钥匙**——`historyRange.granularity` /
    /// `breakdownGrouping` 不在版本里，漏掉的表现是「换了档位数字不变」。
    /// 7 天和 30 天是同一条日线、不同的看得见宽度，钥匙只记天/月，不记 7 还是 30。
    ///
    /// `@ObservationIgnored`——缓存不是状态，在 body 求值中写它不能触发失效。
    private typealias ScopeKey = ScopedPresentationRevision
    private typealias RangeKey = MemoKey<ScopedPresentationRevision, ProviderHistoryRange>
    private typealias GroupingKey = MemoKey<ScopedPresentationRevision, SpendBreakdownGrouping>
    private typealias ChartKey = ProviderDetailChartKey

    /// 这一页的钥匙。取一次，同一轮 body 求值里十几处共用。
    private var scope: ScopedPresentationRevision {
        dashboard.revision.scoped(to: providerID)
    }

    @ObservationIgnored private var usageAccountsMemo = Memo<ScopeKey, [ProviderConnectionState]>()
    @ObservationIgnored private var archivedAccountsMemo = Memo<ScopeKey, [ProviderConnectionState]>()
    @ObservationIgnored private var accountReadingsMemo = Memo<ScopeKey, ReadingSeries>()
    @ObservationIgnored private var rowMemo = Memo<ScopeKey, ServiceRowItem?>()
    @ObservationIgnored private var historyMemo = Memo<RangeKey, [ProviderDetailHistoryItem]>()
    @ObservationIgnored private var breakdownMemo = Memo<GroupingKey, SpendBreakdownContent>()
    @ObservationIgnored private var chartMemo = Memo<ChartKey, ProviderHistoryChartContent>()
    @ObservationIgnored private var pickerMemo = Memo<ScopeKey, Bool>()
    @ObservationIgnored private var usageAmountsMemo = Memo<ScopeKey, [AccountID: String]>()
    @ObservationIgnored private var subscriptionsMemo = Memo<ScopeKey, [ManualSubscriptionItem]>()
    @ObservationIgnored private var compositionCaptionMemo = Memo<ScopeKey, String?>()
    @ObservationIgnored private var monthToDateMemo = Memo<ScopeKey, MonthToDate?>()

    init(providerID: ProviderID, dashboard: DashboardModel) {
        self.providerID = providerID
        self.dashboard = dashboard
        #if DEBUG
        if let launched = FeatureLaunchArguments.historyRange {
            self.historyRange = launched
        } else {
            self.historyRange = dashboard.providerHistoryRange()
        }
        #else
        self.historyRange = dashboard.providerHistoryRange()
        #endif
    }

    var usageAccounts: [ProviderConnectionState] {
        usageAccountsMemo(scope) {
            dashboard.connectionStates()
                .filter { $0.providerID == providerID && $0.isLive }
                .sorted { $0.sortIndex < $1.sortIndex }
        }
    }

    /// 已经结束的用量身份。凭据没了、不再刷新，但它刷回来的历史还在。
    var archivedUsageAccounts: [ProviderConnectionState] {
        archivedAccountsMemo(scope) {
            dashboard.connectionStates()
                .filter { $0.providerID == providerID && $0.isArchived }
                .sorted { $0.sortIndex < $1.sortIndex }
        }
    }

    /// 这一页的本月账单。含订阅、本月、不排除任何账号——**不跟仪表盘的取景框**，
    /// 理由见 `DashboardModel.serviceScopedMonthToDate`。
    ///
    /// 全量重算一遍，所以和 `row` / `breakdown` 一样按这一页的版本缓存。
    private var monthToDate: MonthToDate? {
        monthToDateMemo(scope) { dashboard.serviceScopedMonthToDate }
    }

    /// 订阅/手填默认挂到唯一那份账号；多份时挂厂商（nil），编辑器里可改。
    /// 这不是页面主轴——历史/构成/刷新一律走 `usageAccounts` 并集。
    var soleUsageAccountID: AccountID? {
        usageAccounts.count == 1 ? usageAccounts.first?.accountID : nil
    }

    var descriptor: ProviderDescriptor? {
        ProviderCatalog.descriptor(id: providerID)
    }

    var displayName: String {
        descriptor?.displayName ?? providerID.rawValue
    }

    var colorKey: String {
        descriptor?.colorKey ?? providerID.rawValue
    }

    var isConnected: Bool {
        !usageAccounts.isEmpty
    }

    var billingURL: URL? {
        descriptor?.billingURL
    }

    var kind: ProviderKind {
        descriptor?.kind ?? .usage
    }

    var kindTitle: String {
        ProviderListingCopy.kindTitle(kind)
    }

    /// `subscriptionItems()` 每次都开 context 全表 fetch，body 一轮要读三遍，也得缓存。
    var subscriptions: [ManualSubscriptionItem] {
        subscriptionsMemo(scope) {
            dashboard.subscriptionItems().filter { $0.providerID == providerID }
        }
    }

    /// 还在付的订阅。列表主区只列这些。**填了未来结束月的仍然算在付**——
    /// 这个月取消、服务用到 11 月底，那笔钱还得付。
    var activeSubscriptions: [ManualSubscriptionItem] {
        subscriptions.filter { !$0.hasEnded }
    }

    /// 已经退掉的订阅。单开一节「历史订阅」，不和还在付的混在一起——
    /// 混着列会让「这个月要付多少」变成一道加法题。
    var endedSubscriptions: [ManualSubscriptionItem] {
        subscriptions
            .filter(\.hasEnded)
            .sorted { ($0.endDate ?? .distantPast) > ($1.endDate ?? .distantPast) }
    }

    var hasRecordedBilling: Bool {
        !usageAccounts.isEmpty || !activeSubscriptions.isEmpty
    }

    /// 这家已经整个结束了：没有在跑的用量身份，也没有还在付的订阅，
    /// 但确实留下过账单记录。服务页据此把它挪进「历史服务」。
    var isEnded: Bool {
        usageAccounts.isEmpty
            && activeSubscriptions.isEmpty
            && (!archivedUsageAccounts.isEmpty || !endedSubscriptions.isEmpty)
    }

    var subscriptionExampleFooter: String? {
        let plans = dashboard.catalog.plans.filter { $0.providerID == providerID }
        guard let plan = plans.first else { return nil }
        return String(localized: L("例如 \(examplePlanName(plan.name)) 等固定订阅费用服务"))
    }

    /// 目录档位名有时仍带厂商前缀；这家详情页上再写一遍就叠了。
    private func examplePlanName(_ name: String) -> String {
        let vendor = displayName
        guard name.hasPrefix(vendor) else { return name }
        let trimmed = name.dropFirst(vendor.count).trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? name : trimmed
    }

    /// 结束这家：不再计入本月，历史一个字不动。
    ///
    /// 没有对应的「恢复」：又用回来了就重新接一次用量、重新加一笔订阅——
    /// 那是新的一段，不是把旧的那段续上。凭据在结束时也已经删了。
    func endProvider() async throws {
        try await dashboard.archiveMembership(providerID)
    }

    /// 真删。**会改写历史**——只给「录错了」用。不订了请在编辑页填结束月。
    func removeSubscription(id: PersistentIdentifier) {
        try? dashboard.removeSubscription(id: id)
    }

    var conversionNote: ConvertedAmount? {
        if !walletBreakdown.isEmpty { return nil }
        return latestSnapshot?
            .converted
            .flatMap { $0.isConverted ? $0 : nil }
    }

    /// 两个及以上原币槽才摊开。单槽走 `conversionNote`，避免和余额重复。
    var walletBreakdown: [ConvertedAmount] {
        guard let wallets = latestSnapshot?.wallets, wallets.count >= 2 else { return [] }
        return wallets
    }

    /// 大数字下面那行「（按量 $11.05 + 订阅 $5.00）」。同时有两块钱的家才出。
/// 括号跟着语言走：中日全角，英文半角——和汇率那行同一条规矩。
    ///
    /// **只从 fact 读**，和 `ServiceRowBuilder.subscriptionBreakdown` 同一个理由：
    /// 大数字加起来的就是这些 fact，另算一遍就会和它对不上。这一页的 fact 永远含订阅
    /// （见上面的 `monthToDate`），所以这行的两半加起来正好是大数字，没有第二种措辞。
    ///
    /// 两边都得有钱才出：只有一块时，那一块就是大数字本身，再写一遍是废话。
    var amountCompositionCaption: String? {
        compositionCaptionMemo(scope) { makeAmountCompositionCaption() }
    }

    private func makeAmountCompositionCaption() -> String? {
        // 免费额度那一屏的主角是百分比，不是这两块钱加起来的。
        guard !showsFreeQuotaHero else { return nil }
        var usage = Money.zero
        var subscription = Money.zero
        let accountIDs = Set(usageAccounts.map(\.accountID))
        for fact in monthToDate?.facts ?? [] {
            guard fact.providerID == providerID, let amount = fact.amountUSD else { continue }
            // 无主订阅的 fact 没有 accountID，照厂商归到这一页；和服务列表行同一条规则。
            if let id = fact.accountID, !accountIDs.contains(id) { continue }
            switch fact.type {
            case .monthToDateUsage, .prepaidConsumption:
                usage += amount
            case .subscriptionIncluded:
                subscription += amount
            case .subscriptionSuperseded, .freeQuota, .fetchFailed:
                continue
            }
        }
        guard usage > .zero, subscription > .zero else { return nil }
        let presentation = dashboard.moneyPresentation
        return String(
            localized: L(
                "（按量 \(usage.formatted(using: presentation)) + 订阅 \(subscription.formatted(using: presentation))）"
            )
        )
    }

    /// 大数字下面那行「（1 CNY = $0.1404）」。右边跟显示货币走，不是永远美元。
    var conversionRateCaptions: [String] {
        conversionRateNotes.compactMap { note in
            guard let rate = dashboard.moneyPresentation.unitRateString(from: note) else {
                return nil
            }
            return String(localized: L("（1 \(note.currency) = \(rate)）"))
        }
    }

    /// 有换过币的原币才出。空槽、原币就是显示货币，都不占这一行。
    private var conversionRateNotes: [ConvertedAmount] {
        let notes: [ConvertedAmount]
        if !walletBreakdown.isEmpty {
            var seen = Set<String>()
            notes = walletBreakdown.filter { wallet in
                guard wallet.isConverted, wallet.amount != 0 || wallet.usd != 0 else {
                    return false
                }
                return seen.insert(wallet.currency).inserted
            }
        } else if let note = conversionNote, note.amount != 0 || note.usd != 0 {
            notes = [note]
        } else {
            notes = []
        }
        return notes.filter { dashboard.moneyPresentation.unitRateString(from: $0) != nil }
    }

    private var latestSnapshot: Snapshot? {
        accountReadings.last
    }

    var dataSource: SnapshotSource {
        if let latest = accountReadings.last {
            return latest.source
        }
        return usageAccounts.contains(where: \.usesInbox) ? .inbox : .api
    }

    var supportsInboxIngest: Bool {
        descriptor?.supportsInboxIngest == true
    }

    /// 有 REST / 信箱 / 要花钱取数 / 待核实的凭据向导。纯固定订阅的家没有这条路。
    var supportsUsageSetup: Bool {
        if supportsInboxIngest { return true }
        if let id = descriptor?.id, ProviderAssembly.liveRESTProviderIDs.contains(id) {
            return true
        }
        if descriptor?.costsMoneyToRefresh == true { return true }
        if descriptor?.kind != .subscription,
           descriptor?.accessStatus == .pendingVerification {
            return true
        }
        return false
    }

    var supportsTypedUsage: Bool {
        supportsInboxIngest || descriptor?.kind == .subscription
    }

    var showsTypedUsageEntry: Bool {
        supportsTypedUsage && usageAccounts.count <= 1
    }

    /// 「用脚本自动上报」接到已有手填身份；「再接一笔」必须是新账号。
    /// 只有恰好一份且它还没走信箱时才有「接到已有」这条路。
    func inboxAttachAccountID(attachExisting: Bool) -> AccountID? {
        guard attachExisting,
              supportsTypedUsage,
              usageAccounts.count == 1,
              let only = usageAccounts.first,
              !only.usesInbox else {
            return nil
        }
        return only.accountID
    }

    /// 详情里「用脚本自动上报」的行内入口，条件同上。
    var showsInboxAttach: Bool {
        supportsInboxIngest
            && usageAccounts.count == 1
            && usageAccounts.first?.usesInbox != true
    }

    var showsRefresh: Bool {
        guard isConnected else { return false }
        // 任何一份走信箱就给刷新——两份信箱账号不能比一份的按钮还少。
        if usageAccounts.contains(where: \.usesInbox) { return true }
        if let id = descriptor?.id, ProviderAssembly.liveRESTProviderIDs.contains(id) {
            return true
        }
        return false
    }

    /// 已有用量身份，并且还能重填或再接一份。Cursor 那种纯手填超额不进这里。
    var showsCredentialManagement: Bool {
        !usageAccounts.isEmpty && (supportsUsageSetup || showsRotateCredentials)
    }

    var showsRotateCredentials: Bool {
        usageAccounts.contains { canRotate($0) }
    }

    var credentialItems: [CredentialManagementItem] {
        usageAccounts.enumerated().map { offset, account in
            CredentialManagementItem(
                accountID: account.accountID,
                title: credentialTitle(account, index: offset + 1),
                caption: credentialCaption(account),
                canRotate: canRotate(account)
            )
        }
    }

    func canRotate(_ account: ProviderConnectionState) -> Bool {
        if account.usesInbox { return true }
        if let id = descriptor?.id, ProviderAssembly.liveRESTProviderIDs.contains(id) {
            return true
        }
        if descriptor?.costsMoneyToRefresh == true { return true }
        return false
    }

    func deleteUsageAccount(_ accountID: AccountID) async {
        try? await dashboard.removeConnection(accountID: accountID)
    }

    /// 一份时跟详情用量节同一句；多份没昵称才写成「账号 1」。
    private func credentialTitle(_ account: ProviderConnectionState, index: Int) -> String {
        if let nickname = trimmed(account.nickname) { return nickname }
        if usageAccounts.count == 1 {
            return String(localized: L("按量计费"))
        }
        return String(localized: L("账号 \(index)"))
    }

    private func credentialCaption(_ account: ProviderConnectionState) -> String {
        if let lastRefreshCaption = lastRefreshCaption(for: account) {
            return String(localized: L("上次刷新 \(lastRefreshCaption)"))
        }
        if account.usesInbox {
            return String(localized: L("读数信箱"))
        }
        return String(localized: L("还没有刷新"))
    }

    private func lastRefreshCaption(for account: ProviderConnectionState) -> String? {
        caption(
            stamped: account.lastSuccessfulRefreshAt,
            // 「多久没刷了」问的是**此刻**：那一行有最新一次读数的时刻。
            fetchedDates: dashboard.ledger.latestByAccount()[account.accountID]
                .map { [$0.fetchedAt] } ?? []
        )
    }

    private func trimmed(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var showsPaidRefreshToggle: Bool {
        descriptor?.costsMoneyToRefresh == true && !usageAccounts.isEmpty
    }

    var showsHistoryBackfill: Bool {
        !usageAccounts.isEmpty
            && dataSource != .inbox
            && dataSource != .manual
            && (descriptor?.historyLookbackMonths ?? 0) > 0
    }

    /// 厂商级开关：读「每一份都开着」，写则写到每一份账号，不问 singleton。
    var includeInGlobalRefresh: Bool {
        get {
            !usageAccounts.isEmpty && usageAccounts.allSatisfy {
                dashboard.includeInGlobalRefresh(for: $0.accountID)
            }
        }
        set {
            for account in usageAccounts {
                dashboard.setIncludeInGlobalRefresh(newValue, for: account.accountID)
            }
        }
    }

    var isRefreshing: Bool {
        usageAccounts.contains { dashboard.refreshingAccountIDs.contains($0.accountID) }
    }

    var row: ServiceRowItem? {
        rowMemo(scope) {
            ServiceRowBuilder.rows(
                memberships: dashboard.memberships(),
                connections: dashboard.connectionStates(),
                latest: dashboard.ledger.latestByAccount(),
                monthToDate: monthToDate,
                marks: dashboard.providerMarks,
                subscriptions: dashboard.subscriptions,
                now: dashboard.clock.now,
                calendar: dashboard.clock.calendar,
                presentation: dashboard.moneyPresentation
            ).first { $0.id == providerID }
        }
    }

    var amountText: String {
        row?.value ?? "—"
    }

    var spokenAmount: String {
        row?.spokenValue ?? String(localized: L("暂无读数"))
    }

    var usesHeroAmount: Bool {
        row?.usesSecondaryValue == false
    }

    /// 列表行把「免费额度」放右边、百分比放副标题；详情页反过来：
    /// 额度是标签，百分比才是这一页要回答的数字。
    var showsFreeQuotaHero: Bool {
        row?.kind == .freeTier && row?.usesSecondaryValue == true
    }

    var freeQuotaPercentText: String? {
        guard showsFreeQuotaHero, let row else { return nil }
        return "\(Int((row.amountValue * 100).rounded()))%"
    }

    /// 厂商级说明：所有账号里最近那次成功。
    var lastRefreshCaption: String? {
        caption(
            stamps: usageAccounts.compactMap(\.lastSuccessfulRefreshAt),
            fetchedDates: accountReadings.map(\.fetchedAt)
        )
    }

    /// 盖章和快照可能有一个落后。界面永远拿更近的那次成功。
    private func caption(stamped: Date?, fetchedDates: [Date]) -> String? {
        caption(stamps: [stamped].compactMap { $0 }, fetchedDates: fetchedDates)
    }

    private func caption(stamps: [Date], fetchedDates: [Date]) -> String? {
        guard let lastSuccess = (stamps + fetchedDates).max() else { return nil }
        return ServiceRelativeTime.caption(
            from: lastSuccess,
            now: dashboard.clock.now,
            calendar: dashboard.clock.calendar
        )
    }

    var history: [ProviderDetailHistoryItem] {
        historyMemo(RangeKey(scope, historyRange)) {
            let window = ProviderHistoryChartBuilder.window(
                range: historyRange,
                now: dashboard.clock.now,
                calendar: dashboard.clock.calendar
            )
            return ProviderDetailHistoryBuilder.items(
                from: accountReadings,
                now: dashboard.clock.now,
                calendar: dashboard.clock.calendar,
                presentation: dashboard.moneyPresentation
            )
            .filter { $0.fetchedAt >= window.start }
        }
    }

    /// 明细取**最新一条带明细的快照**，不合并历次。
    ///
    /// 和 `SnapshotDailyMap` 那条道理一样：明细是「这一刻这家的构成」这条读数，
    /// 不是每次刷新再记一笔。把历次加起来，刷新八十次就把 $10 加成 $800。
    /// 历史窗口那次刷新不写明细（见 `GitHubBillingProvider.lines(for:from:)`），
    /// 所以这里会自然落到上一条当月的明细上。
    var breakdown: SpendBreakdownContent {
        breakdownMemo(GroupingKey(scope, breakdownGrouping)) {
            SpendBreakdownBuilder.make(
                lines: latestLines,
                grouping: breakdownGrouping,
                presentation: dashboard.moneyPresentation
            )
        }
    }

    /// 判空不走 `breakdown`：那一趟要排序 + 格式化整份明细，
    /// 只为回答"有没有"太贵，而这是每次 body 求值都要问一遍的。
    var showsBreakdown: Bool {
        latestLines != nil
    }

    private var latestLines: [SpendLine]? {
        accountReadings
            .last { $0.lines?.isEmpty == false }?
            .lines
    }

    private func makeChart(_ range: ProviderHistoryRange) -> ProviderHistoryChartContent {
        ProviderHistoryChartBuilder.make(
            kind: descriptor?.kind ?? .usage,
            readings: accountReadings,
            range: range,
            now: dashboard.clock.now,
            calendar: dashboard.clock.calendar,
            spanLookback: range.visibleDayCount != nil
        )
    }

    var chartContent: ProviderHistoryChartContent {
        chartMemo(ChartKey(scope: scope, granularity: historyRange.granularity)) {
            makeChart(historyRange)
        }
    }

    /// 三个范围里只要有一个能画出点，范围切换才有意义。
    ///
    /// **先看手上这张。** 它本来就要建，而且画得出点的话答案就已经是"出"了——
    /// 另外两档一次都不用建。这一步以前是无条件把三档各建一遍**只为回答一个是非题**，
    /// 实测一次冷重算里 58ms 花在那上面，而绝大多数时候当前这档本来就有点。
    ///
    /// 判据一个字没改：仍然是"有没有任何一档画得出点"。省掉的是问法，不是答案。
    var showsHistoryRangePicker: Bool {
        if chartContent.hasPlot { return true }
        // 当前这档是空的才走到这里，说明这家读数本来就少，建图很快。
        //
        // 问的是「**任何**一档画得出点吗」——和当前停在哪一档无关，所以钥匙里
        // 只有 scope，没有 `historyRange`。把当前那档排除掉会让答案依赖档位，
        // 而钥匙里没有它：切一次档就会拿到上一档算出来的答案。
        return pickerMemo(scope) {
            ProviderHistoryRange.allCases.contains { makeChart($0).hasPlot }
        }
    }

    /// 多账号 section 的每行金额。事实过滤 + 求和是 O(全部事实)，
    /// 一次算好整张表，别让 body 的 ForEach 逐行重来。
    func usageAmount(for accountID: AccountID) -> String? {
        usageAmountsMemo(scope) {
            var totals: [AccountID: Money] = [:]
            for fact in monthToDate?.facts ?? [] {
                guard let id = fact.accountID,
                      fact.type == .monthToDateUsage
                        || fact.type == .prepaidConsumption
                        || fact.type == .subscriptionIncluded,
                      let amount = fact.amountUSD else { continue }
                totals[id, default: .zero] = totals[id, default: .zero] + amount
            }
            return totals.compactMapValues { amount in
                amount > .zero ? amount.formatted(using: dashboard.moneyPresentation) : nil
            }
        }[accountID]
    }

    /// 这家全部用量账号的**原始读数**并集——和服务列表行同一粒度。
    /// 用可空 singleton 会把「两份账号」过滤成空，历史/构成整段消失。
    ///
    /// 走门上那个明确开的口（`DashboardModel.readings(for:)`）：这一页展示的是
    /// 「这家自己报过什么」，账本回答不了，但**范围仍然由门决定**。
    /// 这一页要的原始读数。**范围写死在这里**：详情页最长就是 12 个月。
    ///
    /// 以前这里不传 `since`，于是每次版本变（这家刷新回来一次、
    /// 改一次取景框）都要把这家**全部**历史解一遍三个 blob——代价正比于
    /// 这个账号刷过多少回，而屏幕上最多只画得下 12 个月。
    ///
    /// 再往前多留一个月：预充值那条线要拿「月初之前最后一次余额」当锚点，
    /// 窗口起点那一天之前的最后一条读数必须还在。
    private var accountReadings: ReadingSeries {
        accountReadingsMemo(scope) {
            let window = ProviderHistoryChartBuilder.window(
                range: .months12,
                now: dashboard.clock.now,
                calendar: dashboard.clock.calendar
            )
            let since = dashboard.clock.calendar.date(byAdding: .month, value: -1, to: window.start)
                ?? window.start
            return dashboard.readings(for: Set(usageAccounts.map(\.accountID)), since: since)
        }
    }

    func setHistoryRange(_ range: ProviderHistoryRange) {
        historyRange = range
        dashboard.setProviderHistoryRange(range)
    }

    func refreshThisProvider() async {
        for account in usageAccounts {
            await dashboard.refresh(accountID: account.accountID)
        }
    }

    func backfillHistory() async {
        guard showsHistoryBackfill, !isBackfillingHistory else { return }
        isBackfillingHistory = true
        defer { isBackfillingHistory = false }
        var wrote = false
        for account in usageAccounts {
            if await dashboard.backfillHistory(accountID: account.accountID) {
                wrote = true
            }
        }
        historyBackfillCaption = wrote
            ? L("已写入更长的历史")
            : L("这次没拉到更多历史")
    }

    /// 清空本机这家的全部账单数据，历史一起走。不可撤销。
    func deleteConnection() async throws {
        try await dashboard.purgeMembership(providerID)
    }

    static func preview(_ providerID: ProviderID = .cloudflare) -> ProviderDetailModel {
        ProviderDetailModel(providerID: providerID, dashboard: .preview)
    }

    /// 国内站人民币折进账本之后，详情页大数字下面要能看见汇率。
    static func previewConvertedCNY(displayCurrency: String = ExchangeRates.usdCode) -> ProviderDetailModel {
        let dashboard = DashboardModel.makePreview(seedFixtures: false)
        dashboard.setDisplayCurrency(displayCurrency)
        let clock = dashboard.clock
        let calendar = clock.calendar
        let accountID = AccountID.fixture(for: .moonshot)
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 59)
        )!
        let converted = ConvertedAmount(
            currency: "CNY",
            amount: 15,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "2.11")!
        )
        let snapshot = Snapshot(
            providerID: .moonshot,
            accountID: accountID,
            kind: .prepaid,
            fetchedAt: clock.now,
            periodStart: start,
            periodEnd: end,
            balanceUSD: Money(usd: Decimal(string: "2.11")!),
            converted: converted
        )
        try? dashboard.applyConnection(
            accountID: accountID,
            providerID: .moonshot,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "preview-moonshot-cny",
            fields: [CredentialField.apiKey.rawValue: "sk-preview"],
            snapshots: [snapshot],
            mode: .create
        )
        return ProviderDetailModel(providerID: .moonshot, dashboard: dashboard)
    }
}

/// 图的钥匙按天/月，不按 7 还是 30。两条日线是同一段数据。
private struct ProviderDetailChartKey: Equatable {
    var scope: ScopedPresentationRevision
    var granularity: HistoryGranularity
}
