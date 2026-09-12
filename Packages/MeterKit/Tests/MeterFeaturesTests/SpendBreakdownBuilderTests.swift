import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

struct SpendBreakdownBuilderTests {
    private func line(
        _ category: String,
        _ label: String,
        scope: String? = nil,
        amount: Decimal,
        list: Decimal? = nil,
        quantity: Decimal? = nil,
        unit: String? = nil
    ) -> SpendLine {
        SpendLine(
            category: category,
            label: label,
            scope: scope,
            amountUSD: Money(usd: amount),
            listUSD: list.map(Money.init(usd:)),
            quantity: quantity,
            unit: unit
        )
    }

    private func make(
        _ lines: [SpendLine]?,
        grouping: SpendBreakdownGrouping = .category
    ) -> SpendBreakdownContent {
        SpendBreakdownBuilder.make(lines: lines, grouping: grouping, presentation: .usd)
    }

    @Test("没有明细就是空内容，界面不出这一节")
    func emptyLinesProduceEmptyContent() {
        #expect(make(nil).isEmpty)
        #expect(make([]).isEmpty)
    }

    @Test("按类别分组，金额从大到小")
    func groupsByCategoryDescending() {
        let content = make([
            line("actions", "Actions Linux", amount: 1),
            line("copilot", "Copilot Business", amount: 4),
            line("actions", "Actions storage", amount: 2),
        ])
        #expect(content.groups.map(\.title) == ["copilot", "actions"])
        #expect(content.groups[0].amountCaption == "$4.00")
        #expect(content.groups[1].amountCaption == "$3.00")
        #expect(content.totalCaption == "$7.00")
        // 占比按明细自身合计算。
        #expect(abs(content.groups[0].fraction - 4.0 / 7.0) < 0.0001)
    }

    @Test("没有 scope 维度就不给切换，选了也退回按类别")
    func scopeGroupingNeedsScopeData() {
        let content = make([line("actions", "Actions Linux", amount: 1)], grouping: .scope)
        #expect(content.supportsScopeGrouping == false)
        #expect(content.groups.map(\.title) == ["actions"])
    }

    @Test("有 scope 时可以按归属重新分组")
    func regroupsByScope() {
        let lines = [
            line("actions", "Actions Linux", scope: "RelayOS", amount: 10),
            line("actions", "Actions storage", scope: "RelayOS", amount: 1),
            line("actions", "Actions Linux", scope: "gotanken", amount: 5),
        ]
        let byCategory = make(lines)
        #expect(byCategory.supportsScopeGrouping)
        #expect(byCategory.groups.map(\.title) == ["actions"])

        let byScope = make(lines, grouping: .scope)
        #expect(byScope.groups.map(\.title) == ["RelayOS", "gotanken"])
        #expect(byScope.groups[0].amountCaption == "$11.00")
    }

    @Test("组数超过上限时尾巴并成「其他」，行不丢")
    func collapsesTailIntoOther() {
        let lines = (0..<10).map { index in
            line("cat\(index)", "sku\(index)", amount: Decimal(10 - index))
        }
        let content = make(lines)
        #expect(content.groups.count == SpendGrouping.maxGroups)
        let other = try? #require(content.groups.last)
        #expect(other?.id == "__other__")
        // 10+9+…+1 = 55；前 5 组是 10..6 共 40，其他 15。
        #expect(other?.amountCaption == "$15.00")
        #expect(content.groups.flatMap(\.items).count == 10)
    }

    @Test("全被免费额度吃掉时按原价画条，不给一屏空的")
    func fallsBackToListFractionWhenNothingBilled() {
        let content = make([
            line("actions", "Actions Linux", amount: 0, list: 10, quantity: 1667, unit: "Minutes"),
            line("actions", "Actions storage", amount: 0, list: 1, quantity: 7, unit: "Minutes"),
            line("packages", "Storage", amount: 0, list: 1, quantity: 100, unit: "Minutes"),
        ])
        #expect(content.totalCaption == "$0.00")
        #expect(content.groups.contains { $0.fraction > 0 })
        let actions = try? #require(content.groups.first { $0.title == "actions" })
        #expect((actions?.fraction ?? 0) > 0.9)
        // 合计是 0，百分比不能写出来——那会被读成"花了九成"。
        #expect(actions?.shareCaption == nil)
    }

    @Test("有原价才写抵扣那一行")
    func discountCaptionNeedsListPrice() {
        #expect(make([line("actions", "a", amount: 1)]).discountCaption == nil)
        #expect(make([line("actions", "a", amount: 1, list: 1)]).discountCaption == nil)
        let discounted = make([line("actions", "a", amount: 0, list: 10)])
        #expect(discounted.discountCaption?.contains("$10.00") == true)
    }

    @Test("用量收敛到人看得懂的位数，单位原样不翻译")
    func quantityCaptionIsReadable() {
        let content = make([
            line("actions", "storage", amount: 1, quantity: Decimal(string: "0.46822993099999999")!, unit: "GigabyteHours"),
            line("actions", "linux", amount: 2, quantity: 1667, unit: "Minutes"),
        ])
        let linux = try? #require(content.groups.first?.items.first { $0.title.hasPrefix("linux") })
        #expect(linux?.detailCaption == "1,667 Minutes")
        let storage = try? #require(
            content.groups.flatMap(\.items).first { $0.title.hasPrefix("storage") }
        )
        #expect(storage?.detailCaption == "0.468 GigabyteHours")
    }

    @Test("额度说明跟着用量一起写进那一行")
    func allowanceNoteJoinsDetailCaption() {
        let content = make([
            line("Containers", "Container vCPU", amount: 0, quantity: 26840, unit: "vCPU-seconds"),
            line("Workers", "Workers Standard", amount: 1),
        ].enumerated().map { index, base -> SpendLine in
            var copy = base
            if index == 0 { copy.allowanceNote = "First 375 vCPU-minutes included" }
            return copy
        })
        let item = try? #require(
            content.groups.flatMap(\.items).first { $0.title == "Container vCPU" }
        )
        #expect(item?.detailCaption == "26,840 vCPU-seconds · First 375 vCPU-minutes included")
    }

    @Test("组里只有一条时，额度说明提到组行上")
    func singleLineGroupLiftsAllowanceNote() {
        var only = line("Browser Rendering", "Browser Run - Browser Hours", amount: 0, quantity: 6.2, unit: "Hours")
        only.allowanceNote = "First 10 hours included"
        let content = make([only])
        #expect(content.groups.first?.allowanceCaption == "First 10 hours included")
    }

    @Test("合计为 0 时按原价画条，不按用量——跨单位的用量不可比")
    func zeroTotalFallsBackToListPrice() {
        let content = make([
            line("actions", "Actions Linux", scope: "RelayOS", amount: 0, list: 10, quantity: 1667, unit: "Minutes"),
            line("actions", "Actions storage", scope: "RelayOS", amount: 0, list: 0.01, quantity: 7.48, unit: "GigabyteHours"),
            line("packages", "Packages storage", scope: "RelayOS", amount: 0, list: 0.04, quantity: 1.2, unit: "GigabyteHours"),
        ])
        // actions 合并后单位不一致、quantity 变 nil；按用量算会得出 packages 占满。
        let actions = try? #require(content.groups.first { $0.title == "actions" })
        let packages = try? #require(content.groups.first { $0.title == "packages" })
        #expect((actions?.fraction ?? 0) > 0.99)
        #expect((packages?.fraction ?? 1) < 0.01)
    }

    @Test("组里跨仓库才在行上写仓库；只有一个就不重复")
    func itemTitleNamesScopeOnlyWhenGroupSpansScopes() {
        let single = [line("actions", "Actions Linux", scope: "RelayOS", amount: 1)]
        #expect(make(single).groups[0].items[0].title == "Actions Linux")
        #expect(make(single, grouping: .scope).groups[0].items[0].title == "Actions Linux")

        // 组名和行名不同时，行名照写——它带的是"哪个 sku"这条信息。
        let spanning = [
            line("actions", "Actions Linux", scope: "RelayOS", amount: 2),
            line("actions", "Actions Linux", scope: "gotanken", amount: 1),
        ]
        #expect(
            make(spanning).groups[0].items.map(\.title)
                == ["Actions Linux · RelayOS", "Actions Linux · gotanken"]
        )
    }

    @Test("组名和行名相同的家，行里只写归属")
    func itemTitleDropsLabelWhenItEqualsCategory() {
        let lines = [
            line("Fast Data Transfer", "Fast Data Transfer", scope: "relayos", amount: 2),
            line("Fast Data Transfer", "Fast Data Transfer", scope: "marketing", amount: 1),
        ]
        #expect(make(lines).groups[0].items.map(\.title) == ["relayos", "marketing"])
    }

    @Test("金额全是 0 时按原价排，构成条不能从小画到大")
    func zeroAmountsOrderByListPrice() {
        let content = make([
            line("Edge Requests", "Edge Requests", amount: 0, list: 0.3),
            line("Fluid Compute", "Fluid Compute", amount: 0, list: 6.4),
            line("Fast Data Transfer", "Fast Data Transfer", amount: 0, list: 2.95),
        ])
        #expect(content.groups.map(\.title) == ["Fluid Compute", "Fast Data Transfer", "Edge Requests"])
        #expect(content.groups[0].fraction > content.groups[1].fraction)
        #expect(content.groups[1].fraction > content.groups[2].fraction)
        #expect(content.groups.allSatisfy { $0.isZeroBilled })
    }

    @Test("详情页预览不拿 $0 组去凑三个槽位")
    func previewGroupsSkipZeroBilled() {
        let content = make([
            line("Workers", "Workers Standard", amount: 4.62),
            line("R2", "R2 Storage", amount: 3.18),
            line("Workers KV", "KV List", amount: 0, list: 0.34),
            line("Browser Rendering", "Browser Hours", amount: 0, list: 0.18),
        ])
        #expect(content.groups.count == 4)
        #expect(content.previewGroups.map(\.title) == ["Workers", "R2"])
        #expect(content.itemCount > content.previewGroups.count)
    }

    @Test("全是 $0 时预览空着，入口留给「全部 N 项」")
    func previewGroupsEmptyWhenNothingBilled() {
        let content = make([
            line("Workers KV", "KV List", amount: 0, list: 0.34),
            line("Browser Rendering", "Browser Hours", amount: 0, list: 0.18),
            line("D1", "D1 Storage", amount: 0, list: 0.05),
        ])
        #expect(content.previewGroups.isEmpty)
        #expect(content.groups.count == 3)
        #expect(content.itemCount == 3)
    }

    @Test("真花钱的组超过上限时预览仍只留前几组")
    func previewGroupsCapBilledRows() {
        let lines = (0..<5).map { index in
            line("cat\(index)", "sku\(index)", amount: Decimal(10 - index))
        }
        let content = make(lines)
        #expect(content.previewGroups.map(\.title) == ["cat0", "cat1", "cat2"])
    }
}

struct SpendBreakdownViewTests {
    @Test("合计和圆环左右排，数字走主角金额样式")
    func summaryPutsAmountBesideDonut() throws {
        let view = try GuardrailSourceScan.sourceText(named: "SpendBreakdownView.swift")
        #expect(view.contains(".meterAmountStyle()"))
        #expect(view.contains("HStack(alignment: .center"))
        #expect(view.contains("isAccessibilitySize"))
        #expect(!view.contains("MeterFont.title2"))
        #expect(!view.contains(".frame(maxWidth: .infinity)\n            .padding(.top"))
    }

    @Test("子行长说明只折左侧，右侧金额不换行")
    func sublineKeepsAmountOnOneLine() throws {
        let row = try GuardrailSourceScan.sourceText(named: "SpendSublineRow.swift")
        #expect(!row.contains("LabeledContent {"))
        #expect(row.contains("HStack(alignment: .firstTextBaseline"))
        #expect(row.contains(".fixedSize(horizontal: true, vertical: false)"))
        #expect(row.contains(".layoutPriority(1)"))
        #expect(row.contains("leadingColumn"))
        #expect(row.contains("trailingColumn"))
    }

    @Test("组行同样不把长说明挤到金额上")
    func groupRowKeepsAmountOnOneLine() throws {
        let row = try GuardrailSourceScan.sourceText(named: "SpendBreakdownRow.swift")
        #expect(!row.contains("LabeledContent {"))
        #expect(row.contains("HStack(alignment: .firstTextBaseline"))
        #expect(row.contains(".fixedSize(horizontal: true, vertical: false)"))
        #expect(row.contains(".layoutPriority(1)"))
    }

    @Test("全部 N 项和订阅卡查看更多共用行内 tint 链接")
    func allItemsLinkMatchesSeeMoreChrome() throws {
        let label = try GuardrailSourceScan.sourceText(named: "MeterInlineLinkLabel.swift")
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        let subscriptions = try GuardrailSourceScan.sourceText(named: "SubscriptionsModuleView.swift")
        #expect(label.contains("Color.accentColor"))
        #expect(label.contains("MeterFont.subheadline.weight(.semibold)"))
        #expect(label.contains("chevron.right"))
        #expect(label.contains("meterListRowHitTarget"))
        #expect(detail.contains("MeterInlineLinkLabel"))
        #expect(detail.contains("openBreakdown"))
        #expect(!detail.contains("MeterColumnPushLink(title: Text(L(\"花在哪了\")))"))
        #expect(subscriptions.contains("MeterInlineLinkLabel(Text(L(\"查看更多\")))"))
    }
}
