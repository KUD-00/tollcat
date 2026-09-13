import SwiftUI
import SwiftData
import MeterCore
import MeterDesign
import MeterFormat
import MeterPersistence

struct ProviderDetailView: View {
    /// 详情 model 由这一页自己握着。服务页 / 仪表每次 body 都会 `ProviderDetailModel(...)`，
    /// 那份是一次性的；弹出状态如果跟那份走，目录刷新或从 Safari 回来就会把抽屉关掉。
    @State private var model: ProviderDetailModel
    @State private var isAddingSubscription = false
    /// 连接参考 / 手填用量必须钉在 View 上，理由同上。
    @State private var isPresentingUsageSetup = false
    @State private var usageSetupAttachesExisting = false
    @State private var isPresentingTypedUsage = false
    @State private var editingSubscription: ManualSubscriptionItem?
    @State private var subscriptionPendingDeletion: PersistentIdentifier?
    @State private var isConfirmingEnd = false
    /// 「花在哪了」在 iPhone / iPad 上走系统栈。启动参数和手指共用 `openBreakdown()`。
    @State private var isShowingBreakdown = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.moneyPresentation) private var moneyPresentation
    @Environment(\.macColumnStack) private var macColumnStack

    init(model: ProviderDetailModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model
        MeterGroupedList {
            if model.hasRecordedBilling {
                headerSection
            }
            usageSection
            // 多份账号也有历史/图表——按厂商并集画，和列表行同一粒度。
            if model.isConnected {
                historySection
            }
            subscriptionSection
            endedSubscriptionSection
            endedUsageSection
            dangerSection
        }
        .accessibilityIdentifier(UITestID.providerDetailList)
        .navigationDestination(isPresented: $isShowingBreakdown) {
            SpendBreakdownView(model: model)
        }
        .task {
            if FeatureLaunchArguments.openSpendBreakdown, model.showsBreakdown {
                openBreakdown()
            }
            if FeatureLaunchArguments.openSetup == model.providerID {
                presentUsageSetup(attachExisting: false)
            }
        }
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.large)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: model.dashboard.refreshSuccessToken)
        .confirmationDialog(
            L("删除这笔订阅？"),
            isPresented: isConfirmingSubscriptionDelete,
            titleVisibility: .visible
        ) {
            Button(L("删除"), role: .destructive) {
                if let id = subscriptionPendingDeletion {
                    model.removeSubscription(id: id)
                }
                subscriptionPendingDeletion = nil
            }
            Button(L("取消"), role: .cancel) {
                subscriptionPendingDeletion = nil
            }
        } message: {
            // 这条不是吓唬人：历史月份是拿当前订阅表现算的，删掉这一行，
            // 过去每个月的合计都会少掉这笔钱。不订了该填结束月，不是删。
            Text(L("过去每个月的合计都会少掉这笔钱。只是不订了的话，在这笔订阅里填一个结束月。"))
        }
        .sheet(isPresented: $isAddingSubscription) {
            SubscriptionEditorSheet(
                model: SubscriptionEditorModel(
                    dashboard: model.dashboard,
                    providerID: model.providerID,
                    accountID: model.soleUsageAccountID
                )
            )
        }
        .sheet(isPresented: $isPresentingUsageSetup) {
            UsageSetupSheet(
                model: SetupWizardModel(
                    mode: .create(model.providerID),
                    dashboard: model.dashboard,
                    attachingAccountID: model.inboxAttachAccountID(
                        attachExisting: usageSetupAttachesExisting
                    )
                ),
                onFinished: { isPresentingUsageSetup = false }
            )
        }
        .sheet(isPresented: $isPresentingTypedUsage) {
            ManualUsageEntrySheet(
                model: ManualUsageEntryModel(
                    providerID: model.providerID,
                    accountID: model.soleUsageAccountID,
                    dashboard: model.dashboard
                )
            )
        }
        .sheet(item: $editingSubscription) { item in
            SubscriptionEditorSheet(
                model: SubscriptionEditorModel(
                    dashboard: model.dashboard,
                    providerID: model.providerID,
                    accountID: model.soleUsageAccountID,
                    editing: item
                )
            )
        }
    }

    /// 固定订阅和按量计费在这一页**并列**，不是二选一。
    private var subscriptionSection: some View {
        Section {
            ForEach(model.activeSubscriptions) { item in
                subscriptionRow(item)
                    .swipeActions { deleteSwipeAction(item) }
            }
            Button(L("加一笔固定订阅")) {
                isAddingSubscription = true
            }
        } header: {
            Text(L("固定订阅"))
        } footer: {
            if model.activeSubscriptions.isEmpty, let footer = model.subscriptionExampleFooter {
                Text(footer)
            }
        }
    }

    /// 退掉之后的订阅住在这里。**它们仍然算在过去那几个月的账单里**——
    /// 这一节存在的理由就是让用户看得见「删除」和「结束」不是一回事。
    @ViewBuilder
    private var endedSubscriptionSection: some View {
        if !model.endedSubscriptions.isEmpty {
            Section {
                ForEach(model.endedSubscriptions) { item in
                    subscriptionRow(item)
                        .swipeActions { deleteSwipeAction(item) }
                }
            } header: {
                Text(L("历史订阅"))
            }
        }
    }

    /// 结束掉的用量身份。凭据已经删了，读回来的历史留着。
    @ViewBuilder
    private var endedUsageSection: some View {
        if !model.archivedUsageAccounts.isEmpty {
            Section {
                ForEach(model.archivedUsageAccounts, id: \.accountID) { account in
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        Text(usageTitle(account))
                            .foregroundStyle(Color.meterSecondaryLabel)
                        if let caption = endedCaption(account.archivedAt) {
                            Text(caption)
                                .font(MeterFont.footnote)
                                .foregroundStyle(Color.meterSecondaryLabel)
                        }
                    }
                }
            } header: {
                Text(L("历史用量"))
            } footer: {
                Text(L("凭据已经删掉，不再刷新。刷回来的历史读数留在本机。"))
            }
        }
    }

    /// 划出来的删除。
    ///
    /// **不能写 `role: .destructive`**：那会让 SwiftUI 立刻播一次删行动画，
    /// 而真正的删除还卡在确认弹窗后面——行先消失一下再弹回来，像出了 bug。
    /// 要红色就自己上 tint。
    private func deleteSwipeAction(_ item: ManualSubscriptionItem) -> some View {
        Button(L("删除")) {
            subscriptionPendingDeletion = item.id
        }
        .tint(MeterColor.crit)
    }

    private func subscriptionRow(_ item: ManualSubscriptionItem) -> some View {
        Button {
            editingSubscription = item
        } label: {
            LabeledContent {
                Text(item.amount.formatted(using: moneyPresentation))
                    .monospacedDigit()
                    .foregroundStyle(item.hasEnded ? Color.meterSecondaryLabel : Color.meterLabel)
            } label: {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(item.name)
                        .foregroundStyle(item.hasEnded ? Color.meterSecondaryLabel : Color.meterLabel)
                    Text(subscriptionCaption(item))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
            }
            .meterListRowHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityHint(L("编辑这笔订阅"))
    }

    /// 「已结束 · 2026年8月」。没有日期就只写「已结束」。
    private func endedCaption(_ date: Date?) -> String? {
        guard let date else { return nil }
        let month = MeterDateFormat.yearMonth(date, calendar: model.dashboard.clock.calendar)
        return String(localized: L("已结束 · \(month)"))
    }

    /// 订阅行的那一句。结束月填在未来的还在付，写「到 X 为止」。
    private func subscriptionEndCaption(_ item: ManualSubscriptionItem) -> String? {
        guard let endDate = item.endDate else { return nil }
        if item.hasEnded { return endedCaption(endDate) }
        let month = MeterDateFormat.yearMonth(endDate, calendar: model.dashboard.clock.calendar)
        return String(localized: L("到 \(month) 为止"))
    }

    @ViewBuilder
    private var usageSection: some View {
        if model.usageAccounts.isEmpty {
            Section {
                if model.supportsTypedUsage {
                    Button {
                        isPresentingTypedUsage = true
                    } label: {
                        Text(L("填入本月花费"))
                    }
                    if model.supportsInboxIngest {
                        Button {
                            presentUsageSetup(attachExisting: false)
                        } label: {
                            Text(L("用脚本自动上报"))
                        }
                    }
                } else if model.supportsUsageSetup {
                    Button {
                        presentUsageSetup(attachExisting: false)
                    } label: {
                        Text(L("连接\(model.displayName)账单"))
                    }
                    .accessibilityIdentifier(UITestID.providerDetailConnect)
                }
            } header: {
                Text(L("按量计费"))
            } footer: {
                if model.supportsTypedUsage, !model.supportsInboxIngest {
                    Text(L("没有公开账单接口。套餐月费记在下面的固定订阅。超额用量可以手填。"))
                }
            }
        } else if model.usageAccounts.count > 1 {
            Section {
                ForEach(model.usageAccounts, id: \.accountID) { account in
                    LabeledContent {
                        Text(usageAmount(for: account.accountID))
                            .monospacedDigit()
                            .foregroundStyle(Color.meterLabel)
                    } label: {
                        Text(usageTitle(account))
                    }
                }
                if model.showsCredentialManagement {
                    credentialManagementLink
                }
            } header: {
                Text(L("按量计费"))
            }
        }
    }

    /// 预览没把整份明细摊开才给入口：还有没列的组，或预览略过的 $0 行。
    /// 预览已经是全部真花钱的组、且每组只有一条时，点进去看到的和这里一样，
    /// 那一下点击是白费的。
    ///
    /// 样式跟仪表盘订阅卡的「查看更多」同一颗：tint、靠右、自己画箭头。
    /// 不走 `MeterColumnPushLink`——那是列表行，系统 chevron 钉在右缘、字在左缘。
    @ViewBuilder
    private func allBreakdownLink(_ content: SpendBreakdownContent) -> some View {
        if content.itemCount > content.previewGroups.count {
            Button(action: openBreakdown) {
                MeterInlineLinkLabel(Text(L("全部 \(content.itemCount) 项")))
            }
            .buttonStyle(.plain)
        }
    }

    /// 启动参数和手指走同一条推进：Mac 列内手工栈，其他平台系统栈。
    private func openBreakdown() {
        if let macColumnStack {
            macColumnStack.push(
                title: Text(L("花在哪了")),
                destination: SpendBreakdownView(model: model)
            )
        } else {
            isShowingBreakdown = true
        }
    }

    private var credentialManagementLink: some View {
        MeterColumnPushLink(title: Text(L("管理凭据"))) {
            CredentialManagementSheet(model: model)
        } label: {
            Text(L("管理凭据"))
        }
    }

    private var historyLink: some View {
        MeterColumnPushLink(title: Text(L("读数明细"))) {
            ProviderDetailHistoryView(model: model)
        } label: {
            Text(L("读数明细"))
        }
    }

    private func usageTitle(_ account: ProviderConnectionState) -> String {
        account.nickname
            ?? String(localized: L("按量计费"))
    }

    private func usageAmount(for accountID: AccountID) -> String {
        model.usageAmount(for: accountID) ?? "—"
    }

    /// 「月付 · ×3 席位」这类说明。1 份时不显示数量。
    private func subscriptionCaption(_ item: ManualSubscriptionItem) -> String {
        // 显式限定：这个文件 import 了 SwiftData，裸 `.yearly` 会被
        // `Calendar.RecurrenceRule.yearly` 抢走。
        let period = item.period == SubscriptionPeriod.annual
            ? String(localized: L("年付"))
            : String(localized: L("月付"))
        let base = item.quantity > 1
            ? String(localized: L("\(period) · ×\(item.quantity)"))
            : period
        guard let ended = subscriptionEndCaption(item) else { return base }
        return String(localized: L("\(base) · \(ended)"))
    }

    /// 「本月」大数字和它的注脚（花在哪了的前三组）同住一节——
    /// 明细是大数字的分解，不是另一个话题，单开一节反而把关系切断了。
    /// 不给概览条：条上没有名字，色点行本身已经既有名字又有比例感。
    /// 行是 `.compact` 单行，百分比和用量都留给「全部 N 项」那一页。
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                amountBlock
                if model.showsRefresh {
                    refreshRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if model.showsBreakdown {
                // 一次求值给多处用：`breakdown` 每次都会重新排序 + 格式化。
                let content = model.breakdown
                ForEach(Array(content.previewGroups.enumerated()), id: \.element.id) { index, group in
                    SpendBreakdownRow(
                        group: group,
                        color: MeterColor.composition(index: index),
                        style: .compact
                    )
                }
                allBreakdownLink(content)
            }

            if model.showsPaidRefreshToggle {
                Toggle(isOn: $model.includeInGlobalRefresh) {
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        Text(L("加入全局刷新"))
                        Text(L("每次刷新约 $0.01"))
                            .font(MeterFont.footnote)
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                }
                .accessibilityLabel(L("加入全局刷新"))
                .accessibilityHint(L("打开后，点仪表刷新也会请求这家。每次大约 1 美分"))
            }
        } footer: {
            // 全被免费额度抵掉的家里，金额列全是 $0.00，这一句是唯一有信息量的数字。
            if model.showsBreakdown, let discount = model.breakdown.discountCaption {
                Text(discount)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            if model.showsFreeQuotaHero, let percent = model.freeQuotaPercentText {
                Text(L("免费额度"))
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
                HStack(spacing: MeterSpacing.sm) {
                    Text(percent)
                        .meterAmountStyle()
                        .foregroundStyle(Color.meterLabel)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: model.row?.amountValue ?? 0))
                        .animation(.snappy, value: model.row?.amountValue)
                    glyph
                }
            } else if model.usesHeroAmount {
                Text(L("本月"))
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
                HStack(spacing: MeterSpacing.sm) {
                    Text(model.amountText)
                        .meterAmountStyle()
                        .foregroundStyle(Color.meterLabel)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: model.row?.amountValue ?? 0))
                        .animation(.snappy, value: model.row?.amountValue)
                    glyph
                }
            } else {
                HStack(spacing: MeterSpacing.sm) {
                    Text(model.amountText)
                        .font(MeterFont.title2)
                        .foregroundStyle(Color.meterLabel)
                    glyph
                }
            }
            // 和「上次刷新」同一档字号：这行说的是钱，不能比时间戳还小一号。
            // 颜色用主文字色而不是次级：它是两个金额，不是说明文字。
            if let composition = model.amountCompositionCaption {
                Text(composition)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterLabel)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(model.conversionRateCaptions, id: \.self) { caption in
                Text(caption)
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroSpokenLabel)
    }

    /// 金额右边那颗。导航栏标题只能是文字，所以品牌标识只能落在内容里。
    /// 不用 `.firstTextBaseline` 对齐：glyph 是个方块，没有基线，
    /// 按基线排会让它整体下坠，视觉上和数字脱节。
    private var glyph: some View {
        ProviderGlyph(colorKey: model.colorKey, size: MeterSpacing.providerGlyph)
    }

    private var heroSpokenLabel: String {
        var parts: [String] = []
        if model.showsFreeQuotaHero {
            parts.append(model.spokenAmount)
        } else if model.usesHeroAmount {
            parts.append(String(localized: L("本月，\(model.spokenAmount)")))
        } else {
            parts.append(model.spokenAmount)
        }
        if let composition = model.amountCompositionCaption {
            parts.append(composition)
        }
        parts.append(contentsOf: model.conversionRateCaptions)
        return parts.joined(separator: "，")
    }

    private var refreshRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
            refreshCaption
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await model.refreshThisProvider() }
            } label: {
                MeterRefreshGlyph(isRefreshing: model.isRefreshing)
                    .font(MeterFont.subheadline)
                    .padding(.vertical, MeterSpacing.xxs)
                    .frame(minWidth: MeterSpacing.minTap, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(model.isRefreshing)
            .accessibilityHidden(true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(refreshAccessibilityLabel)
        .accessibilityHint(model.showsPaidRefreshToggle ? L("每次大约 1 美分") : L("只刷新这一家"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            Task { await model.refreshThisProvider() }
        }
    }

    @ViewBuilder
    private var refreshCaption: some View {
        if let lastRefreshCaption = model.lastRefreshCaption {
            Text(L("上次刷新 \(lastRefreshCaption)"))
        } else {
            Text(L("还没有刷新"))
        }
    }

    private var refreshAccessibilityLabel: LocalizedStringResource {
        if let lastRefreshCaption = model.lastRefreshCaption {
            return L("上次刷新 \(lastRefreshCaption)，刷新")
        }
        return L("还没有刷新，刷新")
    }

    private func walletLine(_ wallet: ConvertedAmount) -> String {
        let amount = NSDecimalNumber(decimal: wallet.amount).stringValue
        return "\(wallet.currency) \(amount)"
    }

    private var historySection: some View {
        Section {
            if !model.walletBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    ForEach(model.walletBreakdown, id: \.currency) { wallet in
                        Text(verbatim: walletLine(wallet))
                            .font(MeterFont.body)
                            .foregroundStyle(Color.meterLabel)
                            .monospacedDigit()
                    }
                    Text(L("合计折成美元后计入余额。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                    if model.walletBreakdown.contains(where: \.isConverted) {
                        Text(L("这家按非美元结算。汇率随目录更新，和厂商实际结算的中间价会有出入。"))
                            .font(MeterFont.footnote)
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                }
                .accessibilityElement(children: .combine)
            } else if model.conversionNote != nil {
                Text(L("这家按非美元结算。汇率随目录更新，和厂商实际结算的中间价会有出入。"))
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            if model.dataSource == .inbox {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("你自己投递的读数"))
                    Text(L("这家没有公开账单接口，数字由你的脚本上报，不保证和官网后台一致。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
            }
            if model.dataSource == .manual {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("你填入的花费"))
                    Text(L("这家没有公开账单接口。数字是你填的，不保证和官网后台一致。"))
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
            }

            if model.showsHistoryRangePicker {
                Picker(selection: historyRangeBinding) {
                    ForEach(ProviderHistoryRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                } label: {
                    Text(L("历史范围"))
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(L("历史范围"))

                // 一次求值给多处用，和 `breakdownSection` 里的 `content` 同一个道理。
                let chartContent = model.chartContent
                if chartContent.showsChart {
                    ProviderHistoryChartView(
                        content: chartContent,
                        visibleDayCount: model.historyRange.visibleDayCount
                    )
                    .listRowSeparator(.hidden)
                }
            }
            if model.showsHistoryBackfill {
                historyBackfillRow
            }

            if let url = model.billingURL {
                SafariLink(L("在官网查看账单"), destination: url)
            }

            if model.showsTypedUsageEntry {
                Button {
                    isPresentingTypedUsage = true
                } label: {
                    Text(L("更新花费"))
                }
            }
            if model.showsInboxAttach {
                Button {
                    presentUsageSetup(attachExisting: true)
                } label: {
                    Text(L("用脚本自动上报"))
                }
            }
            if model.showsCredentialManagement {
                credentialManagementLink
            }
            historyLink
        } header: {
            Text(model.kindTitle)
        } footer: {
            if let footer = ProviderListingCopy.chartFooter(model.kind) {
                Text(footer)
            }
        }
    }

    private var historyBackfillRow: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            Button {
                Task { await model.backfillHistory() }
            } label: {
                Text(model.isBackfillingHistory ? L("正在拉取更多历史") : L("拉取更多历史"))
            }
            .disabled(model.isBackfillingHistory)
            .accessibilityHint(L("把这家能给的历史用量尽量拉回来，用来填图表。不是日常刷新。"))
            ListRowNote(text: L("把这家能给的历史用量尽量拉回来，用来填图表。不是日常刷新。"))
            if let historyBackfillCaption = model.historyBackfillCaption {
                ListRowNote(text: historyBackfillCaption)
            }
        }
    }

    private var historyRangeBinding: Binding<ProviderHistoryRange> {
        Binding(
            get: { model.historyRange },
            set: { model.setHistoryRange($0) }
        )
    }

    /// 两条路，写清楚区别：**结束**留住历史，**清空**连历史一起抹掉。
    ///
    /// 以前这里只有「清空」一条路，于是「我不用这家了」只能走破坏性操作，
    /// 而过去几个月真花过的钱会跟着从账本里消失。
    private var dangerSection: some View {
        Section {
            if !model.isEnded, model.hasRecordedBilling {
                Button(L("结束\(model.displayName)")) {
                    isConfirmingEnd = true
                }
                .confirmationDialog(
                    L("结束\(model.displayName)？"),
                    isPresented: $isConfirmingEnd,
                    titleVisibility: .visible
                ) {
                    Button(L("结束")) {
                        endProvider()
                    }
                    Button(L("取消"), role: .cancel) {}
                } message: {
                    Text(L("从下个月起不再计入。已经付过的月份照旧算数，用量凭据会删掉。"))
                }
            }
            Button(L("清空本机\(model.displayName)相关账单数据"), role: .destructive) {
                model.isConfirmingDelete = true
            }
            .confirmationDialog(
                L("清空本机\(model.displayName)相关账单数据？"),
                isPresented: $model.isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button(L("清空"), role: .destructive) {
                    deleteConnection()
                }
                Button(L("取消"), role: .cancel) {}
            } message: {
                Text(L("历史读数、订阅、凭据全部删掉，过去几个月的合计会跟着变。不可撤销。"))
            }
        } footer: {
            Text(L("不用了就「结束」——历史留着。「清空」是连过去的账一起抹掉。"))
        }
    }

    private var isConfirmingSubscriptionDelete: Binding<Bool> {
        Binding(
            get: { subscriptionPendingDeletion != nil },
            set: { if !$0 { subscriptionPendingDeletion = nil } }
        )
    }

    private func presentUsageSetup(attachExisting: Bool) {
        usageSetupAttachesExisting = attachExisting
        isPresentingUsageSetup = true
    }

    /// 结束之后这一页仍然有用（历史订阅、历史用量都在上面），所以不离开。
    private func endProvider() {
        Task {
            try? await model.endProvider()
        }
    }

    private func deleteConnection() {
        Task {
            do {
                try await model.deleteConnection()
                leaveDetail()
            } catch {
                return
            }
        }
    }

    /// 手机从栈上 pop。宽壳详情是分栏 root，`dismiss` 没东西可关——选中由
    /// `ServicesModel.reload` 清掉，详情列回到「选择一项服务」。
    /// Mac 列内推进来的详情（历史服务、仪表盘）走手工栈。
    private func leaveDetail() {
        if let macColumnStack, macColumnStack.canPop {
            macColumnStack.pop()
        } else {
            dismiss()
        }
    }
}

#Preview("Light") {
    NavigationStack {
        ProviderDetailView(model: .preview(.cloudflare))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ProviderDetailView(model: .preview(.aws))
    }
    .preferredColorScheme(.dark)
}

#Preview("Prepaid") {
    NavigationStack {
        ProviderDetailView(model: .preview(.openai))
    }
}

#Preview("Free tier") {
    NavigationStack {
        ProviderDetailView(model: .preview(.vercel))
    }
    .preferredColorScheme(.light)
}

#Preview("Free tier Dark") {
    NavigationStack {
        ProviderDetailView(model: .preview(.vercel))
    }
    .preferredColorScheme(.dark)
}

#Preview("Two accounts") {
    NavigationStack {
        ProviderDetailView(
            model: ProviderDetailModel(
                providerID: .cloudflare,
                dashboard: .previewTwoCloudflare
            )
        )
    }
}

#Preview("XXL") {
    NavigationStack {
        ProviderDetailView(model: .preview(.openai))
    }
    .dynamicTypeSize(.accessibility3)
}

#Preview("Converted CNY") {
    NavigationStack {
        ProviderDetailView(model: .previewConvertedCNY())
    }
    .preferredColorScheme(.light)
}

#Preview("Converted CNY · Yen") {
    NavigationStack {
        ProviderDetailView(model: .previewConvertedCNY(displayCurrency: "JPY"))
    }
    .preferredColorScheme(.dark)
}
