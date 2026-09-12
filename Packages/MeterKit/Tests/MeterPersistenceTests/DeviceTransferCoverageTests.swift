import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 落盘字段增减时，跨设备迁移必须明确表态：接到载荷上，或写进「不装」名单。
///
/// `quantity` 漏接就是因为 `TransferSubscription` 的这个参数有默认值，
/// 编译器不抱怨，往返测试当时也没断言份数。这份名单把「有没有想到」
/// 变成「有没有写进表」；提交闸 `scripts/check-source-invariants.py`
/// 扫同一套表。改了两边一起改。
@MainActor
struct DeviceTransferCoverageTests {
    @Test("SwiftData 模型要么进迁移包，要么明示不装")
    func everyModelIsClassified() {
        let actual = Set(PersistenceContainer.schema.entities.map(\.name))
        let classified = Set(Self.transferredModels).union(Self.omittedModels.keys)
        #expect(
            actual == classified,
            Comment(rawValue: mismatch(label: "Schema", actual: actual, expected: classified))
        )
        for (name, reason) in Self.omittedModels {
            #expect(!reason.isEmpty, "\(name) 的不装理由不能空")
        }
    }

    @Test("落盘字段进了迁移包，或在名单里明示不装；进包的标识符必须出现在 DeviceTransfer")
    func persistedFieldsAreCarriedOrExplicitlyOmitted() throws {
        var gaps: [String] = []

        gaps.append(
            contentsOf: fieldGaps(
                label: "SubscriptionRecord",
                actual: schemaAttributes(of: SubscriptionRecord.self),
                carried: Self.subscriptionCarried,
                omitted: []
            )
        )
        gaps.append(
            contentsOf: fieldGaps(
                label: "ManualUsageRecord",
                actual: schemaAttributes(of: ManualUsageRecord.self),
                carried: Self.manualUsageCarried,
                omitted: []
            )
        )
        gaps.append(
            contentsOf: fieldGaps(
                label: "ProviderConfigRecord",
                actual: schemaAttributes(of: ProviderConfigRecord.self),
                carried: Self.providerConfigCarried,
                omitted: Self.providerConfigOmitted
            )
        )
        gaps.append(
            contentsOf: fieldGaps(
                label: "ProviderMembershipRecord",
                actual: schemaAttributes(of: ProviderMembershipRecord.self),
                carried: Self.membershipCarried,
                omitted: []
            )
        )
        gaps.append(
            contentsOf: fieldGaps(
                label: "AppPreferencesRecord",
                actual: schemaAttributes(of: AppPreferencesRecord.self),
                carried: Self.preferencesCarried,
                omitted: Self.preferencesOmitted
            )
        )
        gaps.append(
            contentsOf: fieldGaps(
                label: "StoredInboxMailbox",
                actual: storedLabels(StoredInboxMailbox(mailbox: "mb", readKey: "rk")),
                carried: Self.mailboxCarried,
                omitted: []
            )
        )

        gaps.append(
            contentsOf: transferGaps(
                typeName: "TransferSubscription",
                actual: storedLabels(dummySubscription),
                expected: Set(Self.subscriptionCarried.values)
            )
        )
        gaps.append(
            contentsOf: transferGaps(
                typeName: "TransferManualUsage",
                actual: storedLabels(dummyManualUsage),
                expected: Set(Self.manualUsageCarried.values)
            )
        )
        gaps.append(
            contentsOf: transferGaps(
                typeName: "TransferConnection",
                actual: storedLabels(dummyConnection),
                expected: Set(Self.providerConfigCarried.values).union(["credentialFields"])
            )
        )
        gaps.append(
            contentsOf: transferGaps(
                typeName: "TransferPreferences",
                actual: storedLabels(dummyPreferences),
                expected: Set(Self.preferencesCarried.values)
            )
        )
        gaps.append(
            contentsOf: transferGaps(
                typeName: "TransferMailbox",
                actual: storedLabels(TransferMailbox(mailbox: "mb", readKey: "rk")),
                expected: Set(Self.mailboxCarried.values)
            )
        )
        gaps.append(
            contentsOf: transferGaps(
                typeName: "TransferPayload",
                actual: storedLabels(dummyPayload),
                expected: Self.payloadFields
            )
        )

        let source = try maskedDeviceTransferSource()
        var identifiers = Set(Self.subscriptionCarried.values)
        identifiers.formUnion(Self.providerConfigCarried.values)
        identifiers.formUnion(Self.membershipCarried.values)
        identifiers.formUnion(Self.preferencesCarried.values)
        identifiers.formUnion(Self.mailboxCarried.values)
        identifiers.formUnion(Self.manualUsageCarried.values)
        identifiers.formUnion(Self.payloadFields)
        identifiers.insert("credentialFields")
        for name in identifiers.sorted() {
            if !mentions(name, in: source) {
                gaps.append(
                    "DeviceTransfer.swift 没有提到 \(name)。collect / apply 要读写这个载荷字段。"
                )
            }
        }

        #expect(gaps.isEmpty, Comment(rawValue: gaps.joined(separator: "\n")))
    }

    @Test("进包字段往返后值还在；明示不装的到了目的地是空的")
    func carriedValuesSurviveAndOmittedValuesReset() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let calendar = utcCalendar
        let sourceCredentials = InMemoryCredentialStore()
        let source = try PersistenceContainer.makeContainer(inMemory: true)
        let sourceContext = ModelContext(source)

        try sourceCredentials.save(
            CredentialFieldsCodec.encode(["apiToken": "sentinel-key"]),
            reference: "credential.github"
        )
        try InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_sentinel", readKey: "tollr_sentinel"),
            to: sourceCredentials
        )
        sourceContext.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .github),
                providerID: .github,
                isEnabled: false,
                sortIndex: 7,
                lastSuccessfulRefreshAt: now,
                credentialReference: "credential.github",
                includeInGlobalRefresh: false,
                usesInbox: true
            )
        )
        sourceContext.insert(
            SubscriptionRecord(
                domain: MonthlySubscription(
                    name: "Copilot Business",
                    amount: Money(usd: Decimal(string: "12.34")!),
                    period: .annual,
                    anchorDate: date(2025, 3, 17),
                    endDate: date(2026, 5, 20),
                    providerID: .github,
                    quantity: 7
                ),
                calendar: calendar
            )
        )
        try AppPreferencesRecord.save(
            AppPreferences(
                includeAWSInGlobalRefresh: true,
                isDemoModeEnabled: true,
                isDemoBannerDismissed: true,
                isReminderEnabled: true,
                reminderSchedule: ReminderSchedule(
                    frequency: .daily,
                    hour: 7,
                    minute: 13,
                    weekday: 5,
                    dayOfMonth: 19
                ),
                appearance: .dark,
                hasCompletedOnboarding: true,
                providerHistoryRange: .months12,
                hidesCat: true,
                refreshesUsageOnActivate: true,
                dashboardFilter: DashboardFilter(
                    monthsBack: 3,
                    includesSubscriptions: false,
                    excludedAccounts: [AccountID.fixture(for: .aws)]
                ),
                displayCurrency: "JPY",
                seenUsageGuideIDs: ["inboxForMissingAPIs", "heroExcludesSubscriptions"],
                dashboardLayout: DashboardLayout(
                    order: ["composition", "services", "budget"],
                    pinnedAccounts: [AccountID.fixture(for: .aws)],
                    monthlyBudgetUSD: 120,
                    sidebarModule: "subscriptions"
                )
            ),
            to: sourceContext
        )
        sourceContext.insert(
            try SnapshotRecord(
                domain: Snapshot(
                    providerID: .github,
                    accountID: AccountID.fixture(for: .github),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: now,
                    periodEnd: now,
                    currentSpendUSD: Money(usd: 4)
                ),
                calendar: utcCalendar
            )
        )
        try sourceContext.save()

        let payload = try DeviceTransfer.collect(container: source, credentials: sourceCredentials)
        #expect(payload.subscriptions[0].quantity == 7)

        let destinationCredentials = InMemoryCredentialStore()
        let destination = try PersistenceContainer.makeContainer(inMemory: true)
        let destinationContext = ModelContext(destination)
        destinationContext.insert(
            try SnapshotRecord(
                domain: Snapshot(
                    providerID: .neon,
                    accountID: AccountID.fixture(for: .neon),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: now,
                    periodEnd: now,
                    currentSpendUSD: Money(usd: 1)
                ),
                calendar: utcCalendar
            )
        )
        try AppPreferencesRecord.save(
            AppPreferences(
                isDemoModeEnabled: true,
                dashboardFilter: DashboardFilter(monthsBack: 2, excludedAccounts: [AccountID.fixture(for: .openai)])
            ),
            to: destinationContext
        )
        try destinationContext.save()

        let code = try #require(TransferCode(userInput: "K7M2Q9XR4T"))
        let exported = try DeviceTransfer.makeExport(
            container: source,
            credentials: sourceCredentials,
            now: now,
            calendar: calendar,
            code: code
        )
        try DeviceTransfer.applyImport(
            fileBytes: exported.fileBytes,
            code: code,
            container: destination,
            credentials: destinationCredentials,
            now: now.addingTimeInterval(60),
            calendar: calendar
        )

        let dest = ModelContext(destination)
        let configs = try dest.fetch(FetchDescriptor<ProviderConfigRecord>())
        #expect(configs.count == 1)
        #expect(configs[0].providerID == .github)
        #expect(configs[0].isEnabled == false)
        #expect(configs[0].sortIndex == 7)
        #expect(configs[0].credentialReference == "credential.github")
        #expect(configs[0].includeInGlobalRefresh == false)
        #expect(configs[0].usesInbox == true)
        #expect(configs[0].lastSuccessfulRefreshAt == nil)
        // 还在用的接入不带终点。结束过的那种另有一条往返测试（`DeviceTransferTests`）——
        // 它没有凭据可搬，塞进这条哨兵会和上面那句凭据断言打架。
        #expect(configs[0].archivedAt == nil)

        let raw = try #require(try destinationCredentials.read(reference: "credential.github"))
        #expect(try CredentialFieldsCodec.decode(raw)["apiToken"] == "sentinel-key")

        let mailbox = try #require(InboxMailboxStore.load(from: destinationCredentials))
        #expect(mailbox.mailbox == "mb_sentinel")
        #expect(mailbox.readKey == "tollr_sentinel")

        let subscriptions = try dest.fetch(FetchDescriptor<SubscriptionRecord>())
        #expect(subscriptions.count == 1)
        let restored = try subscriptions[0].toDomain(calendar: calendar)
        #expect(restored.name == "Copilot Business")
        #expect(restored.amount == Money(usd: Decimal(string: "12.34")!))
        #expect(restored.period == .annual)
        #expect(calendar.component(.year, from: restored.anchorDate) == 2025)
        #expect(calendar.component(.month, from: restored.anchorDate) == 3)
        #expect(calendar.component(.day, from: restored.anchorDate) == 17)
        #expect(restored.providerID == .github)
        #expect(restored.quantity == 7)
        #expect(restored.endDate == date(2026, 5, 20))

        let preferences = try AppPreferencesRecord.load(from: dest)
        #expect(preferences.includeAWSInGlobalRefresh)
        #expect(preferences.isReminderEnabled)
        #expect(preferences.reminderSchedule.frequency == .daily)
        #expect(preferences.reminderSchedule.hour == 7)
        #expect(preferences.reminderSchedule.minute == 13)
        #expect(preferences.reminderSchedule.weekday == 5)
        #expect(preferences.reminderSchedule.dayOfMonth == 19)
        #expect(preferences.appearance == .dark)
        #expect(preferences.hasCompletedOnboarding)
        #expect(preferences.providerHistoryRange == .months12)
        #expect(preferences.hidesCat)
        #expect(preferences.refreshesUsageOnActivate)
        #expect(preferences.displayCurrency == "JPY")
        #expect(!preferences.isDemoModeEnabled)
        #expect(!preferences.isDemoBannerDismissed)
        // 取景框刻意不搬，落到产品默认（仅从量），不是 `.unfiltered`。
        #expect(preferences.dashboardFilter == DashboardFilter(includesSubscriptions: false))
        #expect(preferences.seenUsageGuideIDs == ["heroExcludesSubscriptions", "inboxForMissingAPIs"])
        // 版式随人走：顺序、钉出的账号、预算原样到新机器。
        #expect(preferences.dashboardLayout.order == ["composition", "services", "budget"])
        #expect(preferences.dashboardLayout.pinnedAccounts == [AccountID.fixture(for: .aws)])
        #expect(preferences.dashboardLayout.monthlyBudgetUSD == 120)
        #expect(preferences.dashboardLayout.sidebarModule == "subscriptions")

        #expect(try dest.fetch(FetchDescriptor<SnapshotRecord>()).isEmpty)
    }

    // MARK: - 名单

    /// 进包的 SwiftData 模型。字段表在下面。
    private static let transferredModels: Set<String> = [
        "SubscriptionRecord",
        "ManualUsageRecord",
        "ProviderConfigRecord",
        "ProviderMembershipRecord",
        "AppPreferencesRecord",
    ]

    private static let omittedModels: [String: String] = [
        "SnapshotRecord": "SPEC 12：历史读数不进包，刷新重拉",
        "TipRecord": "打赏收据留在买过的那台设备上",
        "MonthlyRollupRecord": "缓存不是数据：换设备时从对方自己的快照重折一遍，不该跟着搬",
        "AccountLatestRecord": "缓存不是数据：换设备时从对方自己的快照重折一遍，不该跟着搬",
        "LedgerStampRecord": "缓存不是数据：账本从对方自己的快照重折，戳记的是本机那一份输入",
    ]

    private static let manualUsageCarried: [String: String] = [
        "accountIDRaw": "accountID",
        "providerIDRaw": "providerID",
        "periodYear": "periodYear",
        "periodMonth": "periodMonth",
        "amountUSD": "amountUSD",
        "enteredAt": "enteredAt",
        // 这笔手填折成快照时用哪一种 kind。以前导入写死 `.usage`，
        // `.planAndUsage` 那几家换台设备就变一个数。
        "kindRaw": "kindRaw",
    ]

    private static let subscriptionCarried: [String: String] = [
        "name": "name",
        "amountUSD": "amountUSD",
        "periodRaw": "period",
        "anchorYear": "anchorYear",
        "anchorMonth": "anchorMonth",
        "anchorDay": "anchorDay",
        "endYear": "endYear",
        "endMonth": "endMonth",
        "endDay": "endDay",
        "accountIDRaw": "accountID",
        "providerIDRaw": "providerID",
        "quantity": "quantity",
    ]

    private static let providerConfigCarried: [String: String] = [
        "accountIDRaw": "accountID",
        "providerIDRaw": "providerID",
        "nickname": "nickname",
        "identityHint": "identityHint",
        "remoteIdentityFingerprint": "remoteIdentityFingerprint",
        "isEnabled": "isEnabled",
        "archivedAt": "archivedAt",
        "sortIndex": "sortIndex",
        "credentialReference": "credentialReference",
        "includeInGlobalRefresh": "includeInGlobalRefresh",
        "usesInbox": "usesInbox",
        "inboxIngestKeyID": "inboxIngestKeyID",
    ]
    private static let providerConfigOmitted: Set<String> = [
        "lastSuccessfulRefreshAt",
        // `archivedAt` 的分量形状，不单独进包：包里带瞬间，导入时按**本机**
        // 日历重记那一天（见 `ArchivedStamp`）。带分量会把源设备的时区钉过来。
        "archivedDay",
    ]

    private static let membershipCarried: [String: String] = [
        "providerIDRaw": "providerID",
        "sortIndex": "sortIndex",
    ]

    private static let preferencesCarried: [String: String] = [
        "includeAWSInGlobalRefresh": "includeAWSInGlobalRefresh",
        "isReminderEnabled": "isReminderEnabled",
        "reminderFrequencyRaw": "reminderSchedule",
        "reminderHour": "reminderSchedule",
        "reminderMinute": "reminderSchedule",
        "reminderWeekday": "reminderSchedule",
        "reminderDayOfMonth": "reminderSchedule",
        "appearanceRaw": "appearanceRaw",
        "hasCompletedOnboarding": "hasCompletedOnboarding",
        "providerHistoryRangeRaw": "providerHistoryRangeRaw",
        "hidesCat": "hidesCat",
        "refreshesUsageOnActivate": "refreshesUsageOnActivate",
        "displayCurrencyRaw": "displayCurrency",
        "seenUsageGuideIDsJSON": "seenUsageGuideIDs",
        "dashboardLayoutJSON": "dashboardLayout",
        "lastSeenWhatsNewVersion": "lastSeenWhatsNewVersion",
    ]
    private static let preferencesOmitted: Set<String> = [
        "id",
        "isDemoModeEnabled",
        "isDemoBannerDismissed",
        "filterMonthsBack",
        "filterPeriodKindRaw",
        "filterPeriodMonthCount",
        "filterIncludesSubscriptions",
        "filterExcludedAccountsJSON",
        // Mac 菜单栏露什么是这台机器的事，iPhone / Android 没有对应物。
        "menuBarStyleRaw",
        "hidesDockIconWhenWindowClosed",
    ]

    private static let mailboxCarried: [String: String] = [
        "mailbox": "mailbox",
        "readKey": "readKey",
    ]

    private static let payloadFields: Set<String> = [
        "schemaVersion",
        "connections",
        "memberships",
        "subscriptions",
        "preferences",
        "mailbox",
        "manualUsages",
    ]

    // MARK: - 源码扫描

    private func schemaAttributes(of model: any PersistentModel.Type) -> Set<String> {
        let entity = PersistenceContainer.schema.entities.first {
            $0.name == String(describing: model)
        }
        guard let entity else { return [] }
        return Set(entity.attributesByName.keys)
    }

    private func storedLabels<T>(_ value: T) -> Set<String> {
        Set(Mirror(reflecting: value).children.compactMap(\.label))
    }

    private func fieldGaps(
        label: String,
        actual: Set<String>,
        carried: [String: String],
        omitted: Set<String>
    ) -> [String] {
        let expected = Set(carried.keys).union(omitted)
        var gaps: [String] = []
        for name in actual.subtracting(expected).sorted() {
            gaps.append("\(label).\(name) 既没进迁移包，也不在不装名单里")
        }
        for name in expected.subtracting(actual).sorted() {
            gaps.append("\(label).\(name) 在名单里，类型上已经没了")
        }
        for name in Set(carried.keys).intersection(omitted).sorted() {
            gaps.append("\(label).\(name) 同时出现在进包和不装名单")
        }
        return gaps
    }

    private func transferGaps(typeName: String, actual: Set<String>, expected: Set<String>) -> [String] {
        var gaps: [String] = []
        for name in actual.subtracting(expected).sorted() {
            gaps.append("\(typeName).\(name) 是新的载荷字段：接到 DeviceTransfer，或从类型上拿掉")
        }
        for name in expected.subtracting(actual).sorted() {
            gaps.append("\(typeName) 没有 \(name)，但名单还指着它")
        }
        return gaps
    }

    private func mismatch(label: String, actual: Set<String>, expected: Set<String>) -> String {
        let extra = actual.subtracting(expected).sorted()
        let missing = expected.subtracting(actual).sorted()
        var parts: [String] = []
        if !extra.isEmpty {
            parts.append("\(label) 多了 \(extra.joined(separator: ", "))：进包还是不装？")
        }
        if !missing.isEmpty {
            parts.append("\(label) 名单里的 \(missing.joined(separator: ", ")) 已经不在 Schema 里")
        }
        return parts.joined(separator: "\n")
    }

    private func mentions(_ identifier: String, in source: String) -> Bool {
        source.range(
            of: "\\b\(NSRegularExpression.escapedPattern(for: identifier))\\b",
            options: .regularExpression
        ) != nil
    }

    private func maskedDeviceTransferSource() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterPersistence/DeviceTransfer.swift")
        let original = try String(contentsOf: url, encoding: .utf8)
        return maskCommentsAndStrings(original)
    }

    private var dummyManualUsage: TransferManualUsage {
        TransferManualUsage(
            accountID: AccountID.fixture(for: .fly),
            providerID: .fly,
            periodYear: 2026,
            periodMonth: 8,
            amount: Money(roundedUSD: 12.34),
            enteredAt: Date(timeIntervalSince1970: 1_787_000_000),
            kind: .usage
        )
    }

    private var dummySubscription: TransferSubscription {
        TransferSubscription(
            name: "n",
            amount: Money(usd: 1),
            period: .monthly,
            anchorYear: 2026,
            anchorMonth: 1,
            anchorDay: 1,
            providerID: nil,
            quantity: 1
        )
    }

    private var dummyConnection: TransferConnection {
        TransferConnection(
            accountID: AccountID.fixture(for: .github),
            providerID: .github,
            isEnabled: true,
            sortIndex: 0,
            credentialReference: "ref",
            includeInGlobalRefresh: true,
            credentialFields: [:],
            usesInbox: false
        )
    }

    private var dummyPreferences: TransferPreferences {
        TransferPreferences(
            includeAWSInGlobalRefresh: false,
            isReminderEnabled: false,
            reminderSchedule: .default,
            appearanceRaw: "system",
            hasCompletedOnboarding: false,
            providerHistoryRangeRaw: "days30"
        )
    }

    private var dummyPayload: TransferPayload {
        TransferPayload(
            connections: [],
            subscriptions: [],
            preferences: dummyPreferences,
            mailbox: nil
        )
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return utcCalendar.date(from: components)!
    }
}

private func maskCommentsAndStrings(_ text: String) -> String {
    var out = ""
    out.reserveCapacity(text.count)
    let chars = Array(text)
    var i = 0
    while i < chars.count {
        let ch = chars[i]
        let nxt = i + 1 < chars.count ? chars[i + 1] : nil
        if ch == "/", nxt == "/" {
            while i < chars.count, chars[i] != "\n" {
                out.append(" ")
                i += 1
            }
            continue
        }
        if ch == "/", nxt == "*" {
            out.append(contentsOf: "  ")
            i += 2
            while i < chars.count {
                if chars[i] == "*", i + 1 < chars.count, chars[i + 1] == "/" {
                    out.append(contentsOf: "  ")
                    i += 2
                    break
                }
                out.append(chars[i] == "\n" ? "\n" : " ")
                i += 1
            }
            continue
        }
        if ch == "\"" {
            out.append(" ")
            i += 1
            while i < chars.count {
                if chars[i] == "\\" {
                    out.append(contentsOf: "  ")
                    i += 2
                    continue
                }
                if chars[i] == "\"" {
                    out.append(" ")
                    i += 1
                    break
                }
                out.append(chars[i] == "\n" ? "\n" : " ")
                i += 1
            }
            continue
        }
        out.append(ch)
        i += 1
    }
    return out
}
