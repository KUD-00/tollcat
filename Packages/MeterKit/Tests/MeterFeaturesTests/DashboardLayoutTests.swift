import Foundation
import Testing
import MeterCore
import MeterDesign
@testable import MeterFeatures
@testable import MeterModules

@Suite("仪表盘版式：开关、排序、分节")
struct DashboardLayoutTests {
    /// widget 的模块选单读的是 `defaultOrder`（`DashboardModuleQuery.suggestedEntities`）。
    /// 加了模块只改 `allCases` 不改这里，主屏上就选不到它——而且不会有任何编译错误。
    @Test("版式顺序覆盖全部模块")
    func defaultOrderCoversEveryModule() {
        #expect(Set(DashboardModuleID.defaultOrder) == Set(DashboardModuleID.allCases))
        #expect(DashboardModuleID.defaultOrder.count == DashboardModuleID.allCases.count)
    }

    /// widget 不许自己维护一份模块清单：它只认 `DashboardModuleID` 和
    /// `DashboardModuleFactory`，画什么由那一个 switch 说了算。
    /// 判据粗糙但拦得住渐变——第二个模块名一出现在 Widget/ 里就红。
    /// 尺寸清单是产品判断，钉在这里免得日后随手放宽：
    /// 判据是**装不装得下**，以及**更大的一档有没有多说一件事**。
    @Test("小组件的尺寸清单")
    func widgetSizesAreDeliberate() {
        // 2×2 只给「一眼扫过」的那几块。
        let small = Set(DashboardModuleID.allCases.filter { $0.widgetSizes.contains(.small) })
        #expect(small == [.monthToDate, .heatmap, .budget])
        // 4×4 只给「更大真的能多说一件事」的：列表多几行、图例排得开。
        let large = Set(DashboardModuleID.allCases.filter { $0.widgetSizes.contains(.large) })
        #expect(large == [.services, .subscriptions, .categories])
        // 4×2 给「一句话放得下」的那几块。
        let medium = Set(DashboardModuleID.allCases.filter { $0.widgetSizes.contains(.medium) })
        #expect(medium == [.monthToDate, .composition, .services, .subscriptions, .budget])
        #expect(DashboardModuleID.widgetModules.count == 7)
    }

    @Test("widget 不自带模块清单")
    func widgetDoesNotKeepItsOwnModuleList() throws {
        let files = try GuardrailSourceScan.swiftFiles(under: ["Widget"])
        #expect(!files.isEmpty)
        var mentioned: Set<String> = []
        var usesFactory = false
        for file in files {
            let raw = try String(contentsOf: file, encoding: .utf8)
            // 生成物例外：一块模块一个 kind 的 `TollCatWidgetBundle.swift` 本来就该点名，
            // 但它从 `shared/widgets.json` 生成，漂不了。
            if raw.hasPrefix("// GENERATED") { continue }
            let masked = GuardrailSourceScan.maskCommentsAndStrings(raw)
            // 路由认两个名字：直接调 factory，或者经 `WidgetModuleTile`（在 MeterModules 里，
            // 内部就是这个 factory；商店宣传图上的小组件渲的是同一份视图）。
            if masked.contains("DashboardModuleFactory") || masked.contains("WidgetModuleTile") {
                usesFactory = true
            }
            for id in DashboardModuleID.allCases {
                // 裸的 `.monthToDate` 才算枚举 case；`store.subscriptions` 这种属性访问不算。
                let pattern = "(?<![A-Za-z0-9_)\\]])\\.\(id.rawValue)\\b"
                let qualified = masked.contains("DashboardModuleID.\(id.rawValue)")
                let bare = masked.range(of: pattern, options: .regularExpression) != nil
                if qualified || bare { mentioned.insert(id.rawValue) }
            }
        }
        #expect(usesFactory, "widget 没走 DashboardModuleFactory / WidgetModuleTile")
        #expect(
            mentioned.count <= 1,
            "Widget/ 里出现了多个模块名：\(mentioned.sorted())。清单只许有一份"
        )
    }

    @Test("默认版式开着的那几块，本月合计永远第一，下架的一块不出现")
    func defaultLayoutOpensTheDefaultModules() {
        let order = DashboardModuleID.resolvedOrder(from: .default)
        #expect(order.first == .monthToDate)
        #expect(order == [.monthToDate, .composition, .anomaly, .balanceAlert, .freeQuota])
        #expect(!order.contains(.services))
        #expect(!order.contains(.upcomingCharges))
    }

    /// 下架不是把 case 删掉：旧版式里存着它的 id，widget 清单也要求每块模块表态。
    /// 判据在 `DashboardModuleThresholds.showsUpcomingCharges` 一处。
    @Test("下架的模块存过也不出现")
    func retiredModulesNeverResolve() {
        let layout = DashboardLayout(order: ["upcomingCharges", "budget"])
        #expect(DashboardModuleID.resolvedOrder(from: layout) == [.monthToDate, .budget])
        #expect(!DashboardModuleID.editableOrder(from: layout).contains(.upcomingCharges))
    }

    /// 构成画在英雄区，排哪儿都在那儿——所以清单里它也永远紧跟本月合计，
    /// 编辑面照着清单画，才不会给一个拖了不动的手柄。
    @Test("用户排的顺序照搬，本月合计和构成在最上面")
    func storedOrderWinsAndFixedSlotsStayOnTop() {
        let layout = DashboardLayout(order: ["heatmap", "monthToDate", "composition", "budget"])
        let order = DashboardModuleID.resolvedOrder(from: layout)
        #expect(order == [.monthToDate, .composition, .heatmap, .budget])
    }

    @Test("不认识的模块 id 跳过，不整份作废")
    func unknownIDsAreDropped() {
        // "changes" 是删掉的模块，旧库 / 旧迁移包里可能还有——按未知 id 跳过。
        let layout = DashboardLayout(order: ["composition", "someFutureModule", "changes", "budget"])
        #expect(DashboardModuleID.resolvedOrder(from: layout) == [.monthToDate, .composition, .budget])
    }

    @Test("编辑面：开着的按版式顺序在前，关着的按默认顺序在后，没有本月合计和下架的")
    func editableOrderListsEnabledThenDisabled() {
        let layout = DashboardLayout(order: ["budget", "composition"])
        let editable = DashboardModuleID.editableOrder(from: layout)
        #expect(editable.prefix(2) == [.composition, .budget])
        #expect(!editable.contains(.monthToDate))
        let retired = Set(DashboardModuleID.allCases.filter(\.isRetired))
        #expect(Set(editable) == Set(DashboardModuleID.allCases).subtracting([.monthToDate]).subtracting(retired))
    }

    @Test("手机分节：相邻的「需要注意」并成一节，其他模块各自一节")
    func sectionsMergeAdjacentAttentionModules() {
        let visible: [DashboardModuleID] = [.monthToDate, .composition, .anomaly, .balanceAlert, .heatmap, .freeQuota, .budget]
        let sections = DashboardModuleRegion.sections(from: visible)
        #expect(sections.map(\.ids) == [[.anomaly, .balanceAlert], [.heatmap], [.freeQuota], [.budget]])
        #expect(sections[0].isAttention)
        #expect(!sections[1].isAttention)
    }

    @Test("版式落盘再读回原样，金额不走 Double")
    func layoutRoundTripsThroughJSON() throws {
        let account = AccountID.fixture(for: .aws)
        let layout = DashboardLayout(order: ["services", "budget"], pinnedAccounts: [account], monthlyBudgetUSD: Decimal(string: "12.30")!)
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(DashboardLayout.self, from: data)
        #expect(decoded == layout)
        #expect(decoded.monthlyBudgetUSD == Decimal(string: "12.30"))
        // 旧包没有版式字段：解成默认，不报错。
        let legacy = try JSONDecoder().decode(DashboardLayout.self, from: Data("{}".utf8))
        #expect(legacy == .default)
    }

    @Test("侧栏钉一块：只能钉一格宽的，本月合计和构成不行")
    func sidebarSlotOnlyTakesSingleWidthModules() {
        #expect(DashboardModuleID.services.canSitInSidebar)
        #expect(DashboardModuleID.subscriptions.canSitInSidebar)
        #expect(!DashboardModuleID.monthToDate.canSitInSidebar)
        #expect(!DashboardModuleID.composition.canSitInSidebar)
    }

    @Test("钉了侧栏模块就把列拉到上限，内容宽才能到 regular")
    func sidebarColumnExpandsWhenModulePinned() {
        let idle = MeterSpacing.sidebarColumnWidth(hasPinnedModule: false)
        #expect(idle.min == MeterSpacing.sidebarColumnMin)
        #expect(idle.ideal == MeterSpacing.sidebarColumn)
        #expect(idle.max == MeterSpacing.sidebarColumnMax)

        let pinned = MeterSpacing.sidebarColumnWidth(hasPinnedModule: true)
        #expect(pinned.min == pinned.max)
        #expect(pinned.ideal == pinned.max)
        #expect(pinned.max == MeterSpacing.sidebarColumnMax)

        let contentWidth = pinned.max - (MeterSpacing.sm + MeterSpacing.md) * 2
        #expect(ModuleWidth.bucket(forContentWidth: contentWidth) >= .regular)
        let idleContent = idle.ideal - (MeterSpacing.sm + MeterSpacing.md) * 2
        #expect(ModuleWidth.bucket(forContentWidth: idleContent) == .compact)
    }

    @Test("侧栏那块也落盘、也随迁移包走")
    func sidebarSlotRoundTrips() throws {
        let layout = DashboardLayout(order: ["subscriptions"], sidebarModule: "subscriptions")
        let decoded = try JSONDecoder().decode(DashboardLayout.self, from: JSONEncoder().encode(layout))
        #expect(decoded.sidebarModule == "subscriptions")
        // 空字符串当成没钉。
        #expect(DashboardLayout(sidebarModule: "").sidebarModule == nil)
    }

    @Test("版式归一：重复的 id 只留第一个，预算 ≤ 0 当没设")
    func layoutNormalizes() {
        let layout = DashboardLayout(order: ["budget", "budget", "", "heatmap"], monthlyBudgetUSD: 0)
        #expect(layout.order == ["budget", "heatmap"])
        #expect(layout.monthlyBudgetUSD == nil)
    }

    @Test("按类别构成：同类相加，段色取花最多那家，百分比凑整到 100")
    func categoriesAggregateByCatalogCategory() {
        let composition = CompositionModuleContent(
            segments: [
                CompositionSegment(accountID: AccountID.fixture(for: .aws), providerID: .aws, displayName: "AWS", colorKey: "aws", amount: Money(usd: 30), fraction: 0.5, percent: 50),
                CompositionSegment(accountID: AccountID.fixture(for: .vercel), providerID: .vercel, displayName: "Vercel", colorKey: "vercel", amount: Money(usd: 10), fraction: 0.17, percent: 17),
                CompositionSegment(accountID: AccountID.fixture(for: .openai), providerID: .openai, displayName: "OpenAI", colorKey: "openai", amount: Money(usd: 20), fraction: 0.33, percent: 33),
            ],
            totalText: "$60.00",
            spokenTotal: "60 美元",
            destination: nil
        )
        let content = CategoriesBuilder.make(composition: composition, presentation: .usd)
        let slices = try! #require(content).slices
        #expect(slices.map(\.category) == [.hosting, .aiInference])
        #expect(slices[0].colorKey == "aws")
        #expect(slices[0].memberNames == ["AWS", "Vercel"])
        #expect(slices.map(\.percent).reduce(0, +) == 100)
    }

    @Test("预算线：没设预算不建；超出时写超出多少")
    func budgetBuilderRespectsAbsenceAndOverrun() {
        let monthToDate = MonthToDate(
            totalUSD: Money(roundedUSD: 91.30),
            projectedMonthEndUSD: Money(usd: 120),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [],
            variableUSD: Money(roundedUSD: 91.30),
            projectedVariableUSD: Money(usd: 120)
        )
        #expect(BudgetBuilder.make(monthToDate: monthToDate, budgetUSD: nil, presentation: .usd) == nil)
        let over = BudgetBuilder.make(monthToDate: monthToDate, budgetUSD: 80, presentation: .usd)
        #expect(over?.isOver == true)
        #expect(over?.caption.contains("$11.30") == true)
    }
}

/// 深链的来回。widget 写出去、App 认回来是两段代码，中间只有字符串——
/// 漂了的症状是「点了没反应」，没有编译期信号，只能靠这条把每个 case 走一遍。
@Suite("深链 URL")
struct DashboardRouteURLTests {
    @Test("每条路线都能原样来回")
    func everyRouteRoundTrips() {
        let routes: [DashboardRoute] = [
            .composition,
            .comparison,
            .subscriptions,
            .heatmap,
            .categories,
            .account(AccountID(rawValue: UUID())),
            .provider(.cloudflare),
        ]
        for route in routes {
            let url = route.deepLinkURL
            #expect(url.scheme == DashboardDeepLink.scheme)
            #expect(DashboardDeepLink.route(from: url) == route, "\(url) 认不回 \(route)")
        }
    }

    @Test("整块那条只打开仪表盘，不推详情")
    func dashboardURLIsNotARoute() {
        let url = DashboardDeepLink.dashboardURL
        #expect(DashboardDeepLink.isDashboard(url))
        #expect(DashboardDeepLink.route(from: url) == nil)
    }

    @Test("不认识的 URL 一律不动")
    func unknownURLsAreIgnored() {
        for raw in [
            "https://tollcat.app/dashboard",
            "tollcat://nope",
            "tollcat://account/not-a-uuid",
            "tollcat://account",
            "tollcat://provider",
        ] {
            let url = URL(string: raw)!
            #expect(DashboardDeepLink.route(from: url) == nil, "\(raw) 不该解析出路线")
            #expect(!DashboardDeepLink.isDashboard(url) || raw.hasPrefix("tollcat://dashboard"))
        }
    }
}
