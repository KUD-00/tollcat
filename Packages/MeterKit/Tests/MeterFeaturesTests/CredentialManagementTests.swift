import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct CredentialManagementTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("有 API 用量身份时详情入口是管理凭据，Cursor 手填超额不进")
    func apiAccountsOfferManagementAndCursorDoesNot() {
        let cloudflare = ProviderDetailModel.preview(.cloudflare)
        #expect(cloudflare.showsCredentialManagement)
        #expect(cloudflare.credentialItems.count == 1)
        #expect(cloudflare.credentialItems[0].canRotate)
        #expect(cloudflare.credentialItems[0].title == String(localized: L("按量计费")))

        let cursor = ProviderDetailModel.preview(.cursor)
        #expect(!cursor.showsCredentialManagement)
        #expect(!cursor.showsRotateCredentials)
    }

    @Test("只加了厂商、还没有用量身份时不出现管理凭据")
    func membershipWithoutUsageHidesManagement() throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.cloudflare)
        let model = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        #expect(model.supportsUsageSetup)
        #expect(model.usageAccounts.isEmpty)
        #expect(!model.showsCredentialManagement)
    }

    @Test("手填的信箱那家可以再接一份，但不能重填 API 钥匙")
    func typedInboxAccountCannotRotate() throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.fly)
        try dashboard.applyManualUsage(providerID: .fly, amount: Money(usd: 9), to: nil)
        let model = ProviderDetailModel(providerID: .fly, dashboard: dashboard)
        #expect(model.showsCredentialManagement)
        #expect(model.supportsUsageSetup)
        let item = try #require(model.credentialItems.first)
        #expect(!item.canRotate)
        #expect(item.title == String(localized: L("按量计费")))
    }

    @Test("两份用量用昵称区分，点进去才是重填")
    func twoAccountsUseNicknames() {
        let model = ProviderDetailModel(
            providerID: .cloudflare,
            dashboard: .previewTwoCloudflare
        )
        #expect(model.showsCredentialManagement)
        let titles = Set(model.credentialItems.map(\.title))
        #expect(titles.contains(String(localized: L("工作"))))
        #expect(titles.contains(String(localized: L("个人"))))
        #expect(model.credentialItems.allSatisfy { $0.canRotate })
    }

    @Test("删掉一份用量不拆厂商门口")
    func deletingOneAccountKeepsMembership() async throws {
        let dashboard = try makeDashboard()
        try dashboard.addMembership(.cloudflare)
        try dashboard.applyManualUsage(providerID: .cloudflare, amount: Money(usd: 4), to: nil)
        let model = ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
        let id = try #require(model.usageAccounts.first?.accountID)
        await model.deleteUsageAccount(id)
        #expect(model.usageAccounts.isEmpty)
        #expect(dashboard.memberships().contains { $0.providerID == .cloudflare })
    }

    @Test("详情页入口收成管理凭据，从右侧推进，重填和再接一份仍走抽屉")
    func detailFoldsRotateAndAddIntoManagement() throws {
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        let sheet = try GuardrailSourceScan.sourceText(named: "CredentialManagementSheet.swift")
        #expect(detail.contains("L(\"管理凭据\")"))
        #expect(detail.contains("NavigationLink"))
        #expect(detail.contains("CredentialManagementSheet"))
        #expect(!detail.contains("重新填写凭据"))
        #expect(!detail.contains("再接一笔按量账单"))
        #expect(sheet.contains("L(\"再接一笔按量账单\")"))
        #expect(sheet.contains("mode: .rotate"))
        #expect(sheet.contains("mode: .create"))
        #expect(!sheet.contains("meterDrawerChrome"))
        #expect(!sheet.contains("Button(role: .close)"))
        #expect(sheet.contains("meterListRowHitTarget"))
        #expect(!sheet.contains("meterPrimaryActionBar"))
    }

    @Test("读数明细在管理凭据下面，从右侧推进，不就地展开")
    func readingDetailsPushesBelowCredentials() throws {
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        let history = try GuardrailSourceScan.sourceText(named: "ProviderDetailHistoryView.swift")
        #expect(detail.contains("credentialManagementLink\n            }\n            historyLink"))
        #expect(detail.contains("ProviderDetailHistoryView"))
        #expect(!detail.contains("DisclosureGroup"))
        #expect(history.contains("L(\"读数明细\")"))
        #expect(history.contains("navigationTitle"))
        #expect(!history.contains("meterDrawerChrome"))
        #expect(!history.contains("Button(role: .close)"))
    }

    private func makeDashboard() throws -> DashboardModel {
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
        return DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: now, calendar: calendar),
            httpClient: StubHTTPClient()
        )
    }
}
