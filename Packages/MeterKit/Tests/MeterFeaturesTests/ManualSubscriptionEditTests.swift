import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

@MainActor
struct ManualSubscriptionEditTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
    }

    @Test("打开编辑页带上原有字段")
    func editPrefillsExistingFields() throws {
        let dashboard = DashboardModel.previewEmpty
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "ChatGPT Plus",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: now,
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                quantity: 2
            )
        )
        let item = try #require(dashboard.subscriptionItems().first)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            editing: item
        )
        #expect(model.isEditing)
        #expect(model.name == "ChatGPT Plus")
        #expect(model.navigationTitle == "ChatGPT Plus")
        #expect(model.parsedAmount == Money(usd: 10))
        #expect(model.quantity == 2)
        #expect(model.period == .monthly)
        #expect(model.affiliation == .account(AccountID.fixture(for: .openai)))
        #expect(model.total == Money(usd: 20))
    }

    @Test("编辑已有订阅是覆盖不是再插一条")
    func editOverwritesInsteadOfInserting() throws {
        let dashboard = DashboardModel.previewEmpty
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "ChatGPT Plus",
                amount: Money(usd: 20),
                period: .monthly,
                anchorDate: now,
                providerID: .openai
            )
        )
        let item = try #require(dashboard.subscriptionItems().first)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            editing: item
        )
        model.name = "ChatGPT Pro"
        model.amountText = "25"
        model.quantity = 2
        model.affiliation = .none
        try model.save()

        let updated = dashboard.subscriptionItems()
        #expect(updated.count == 1)
        #expect(updated[0].id == item.id)
        #expect(updated[0].name == "ChatGPT Pro")
        #expect(updated[0].amount == Money(usd: 50))
        #expect(updated[0].quantity == 2)
        #expect(updated[0].providerID == nil)
    }

    @Test("编辑页删除会把这笔拿掉")
    func editDeleteRemovesTheSubscription() throws {
        let dashboard = DashboardModel.previewEmpty
        try dashboard.applySubscription(
            MonthlySubscription(
                name: "Claude Max",
                amount: Money(usd: 200),
                period: .monthly,
                anchorDate: now
            )
        )
        #expect(dashboard.subscriptionItems().count == 1)
        let item = try #require(dashboard.subscriptionItems().first)
        let model = SubscriptionEditorModel(
            dashboard: dashboard,
            editing: item
        )
        try model.delete()
        #expect(dashboard.subscriptionItems().isEmpty)
        #expect(dashboard.subscriptions.isEmpty)
    }

    @Test("新建时份数乘单价才是落库金额")
    func createMultipliesUnitByQuantity() throws {
        let dashboard = DashboardModel.previewEmpty
        let model = SubscriptionEditorModel(dashboard: dashboard)
        model.name = "Copilot Business"
        model.amountText = "19"
        model.quantity = 3
        try model.save()
        let item = try #require(dashboard.subscriptionItems().first)
        #expect(item.amount == Money(usd: 57))
        #expect(item.quantity == 3)
        #expect(item.unitAmount == Money(usd: 19))
    }

    @Test("金额只认十进制，写字母不算数")
    func rejectsNonNumericAmount() {
        let model = SubscriptionEditorModel(dashboard: DashboardModel.previewEmpty)
        model.name = "x"
        for bad in ["abc", "20元", "-5", ""] {
            model.amountText = bad
            #expect(model.parsedAmount == nil, "\(bad) 不该解出金额")
        }
    }
}
