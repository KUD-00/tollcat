import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

/// 服务页什么时候整屏接管。
///
/// 这条规则原先长在视图里，而且是错的：空态被塞进 `List` 的一个 `Section`，
/// 于是它只能在那一行的容器里居中——挤在大标题底下，卡片下沿留一大块死白，
/// 屏幕下面三分之二空着。挪到 model 上除了能测，也让「整屏 or 一行」变成一个
/// 有名字的判断，而不是藏在布局里的副作用。
@MainActor
struct ServicesEmptyStateTests {
    @Test("一家都没接、也没有手动订阅时整屏接管")
    func takesOverTheScreenWhenTrulyEmpty() {
        let model = ServicesModel.previewEmpty
        #expect(model.connectedRows.isEmpty)
        #expect(model.manualSubscriptions.isEmpty)
        #expect(model.isFullyEmpty)
    }

    @Test("有接入的服务就走列表，不接管")
    func doesNotTakeOverWhenConnected() {
        let model = ServicesModel.preview
        model.reload()
        #expect(!model.connectedRows.isEmpty)
        #expect(!model.isFullyEmpty)
    }

    /// 半空那种情况：一家服务都没接，但已经录了一笔手动订阅。
    /// 整屏接管会把那笔订阅藏起来——列表里还有东西，就不能接管。
    @Test("只有手动订阅、没有接入服务时不接管，那笔订阅不能被藏起来")
    func keepsTheListWhenOnlyManualSubscriptionsExist() throws {
        let model = ServicesModel.previewEmpty
        try model.dashboard.applySubscription(
            MonthlySubscription(
                name: "ChatGPT Plus",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: Date(timeIntervalSince1970: 0)
            )
        )
        model.reload()
        #expect(model.connectedRows.isEmpty)
        #expect(!model.manualSubscriptions.isEmpty)
        #expect(!model.isFullyEmpty, "有手动订阅还整屏接管，那笔订阅就看不见了")
    }

    /// `reload()` 会被 onAppear 和好几个 onChange 连着触发，按
    /// `presentationToken` 去重。去重只能挡住重复触发，不能挡住真实写入。
    @Test("reload 去重不挡真实写入：加订阅后立刻可见")
    func reloadDeduplicationDoesNotHideWrites() throws {
        let model = ServicesModel.previewEmpty
        model.reload()
        #expect(model.manualSubscriptions.isEmpty)
        try model.dashboard.applySubscription(
            MonthlySubscription(
                name: "ChatGPT Plus",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: Date(timeIntervalSince1970: 0)
            )
        )
        model.reload()
        #expect(!model.manualSubscriptions.isEmpty, "写入换了 presentationToken，reload 必须真跑")
    }

    @Test("服务页默认按计费模式")
    func defaultsToKind() {
        let model = ServicesModel.previewEmpty
        #expect(model.sort == .kind)
        #expect(!model.usesSectionTitles)
    }

    @Test("预览种子有不止一种钱，按计费模式时画小标题")
    func previewUsesKindTitles() {
        let model = ServicesModel.preview
        #expect(model.usesSectionTitles)
        #expect(model.arrangedSections.contains { $0.title != nil })
        model.sort = .price
        #expect(!model.usesSectionTitles)
        #expect(model.arrangedSections.allSatisfy { $0.title == nil })
    }

    @Test("预览种子跨多个类别，按类别时分组且画小标题")
    func previewUsesCategoryTitles() {
        let model = ServicesModel.preview
        model.sort = .category
        #expect(model.usesSectionTitles)
        let sections = model.arrangedSections
        #expect(sections.count > 1)
        #expect(sections.allSatisfy { $0.category != nil && $0.title != nil })
        // 分组只是重排，一行不能丢也不能重复。
        #expect(sections.flatMap(\.rows).count == model.connectedRows.count)
        #expect(
            sections.map(\.category) == ServiceListArrangement.categoryOrder
                .filter { category in sections.contains { $0.category == category } },
            "组序跟目录声明序"
        )
    }
}
