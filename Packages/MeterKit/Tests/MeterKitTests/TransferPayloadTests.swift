import Foundation
import Testing
@testable import MeterCore

struct TransferPayloadTests {
    @Test("载荷往返不丢字段，金额按字符串走")
    func payloadRoundTrips() throws {
        let payload = TransferPayload(
            connections: [
                TransferConnection(
                    accountID: AccountID.fixture(for: .cloudflare),
                    providerID: .cloudflare,
                    isEnabled: true,
                    sortIndex: 0,
                    credentialReference: "credential.cloudflare",
                    includeInGlobalRefresh: true,
                    credentialFields: ["apiToken": "secret", "accountID": "acct"]
                ),
            ],
            subscriptions: [
                TransferSubscription(
                    name: "ChatGPT Plus",
                    amount: Money(usd: Decimal(string: "20")!),
                    period: .monthly,
                    anchorYear: 2026,
                    anchorMonth: 8,
                    anchorDay: 3,
                    providerID: .openai,
                    quantity: 3
                ),
            ],
            preferences: TransferPreferences(
                includeAWSInGlobalRefresh: false,
                isReminderEnabled: true,
                reminderSchedule: ReminderSchedule(frequency: .weekly, hour: 21, minute: 0),
                appearanceRaw: "dark",
                hasCompletedOnboarding: true,
                providerHistoryRangeRaw: "days30",
                refreshesUsageOnActivate: true,
                seenUsageGuideIDs: ["heroExcludesSubscriptions"]
            )
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(TransferPayload.self, from: data)

        #expect(decoded.schemaVersion == TransferPayload.currentSchemaVersion)
        #expect(decoded.connections == payload.connections)
        #expect(decoded.subscriptions == payload.subscriptions)
        #expect(decoded.preferences == payload.preferences)
        #expect(decoded.preferences.refreshesUsageOnActivate == true)
        #expect(decoded.preferences.displayCurrency == ExchangeRates.usdCode)
        #expect(decoded.preferences.seenUsageGuideIDs == ["heroExcludesSubscriptions"])
        #expect(decoded.subscriptions[0].amountUSD == "20")
        #expect(decoded.subscriptions[0].quantity == 3)
        #expect(decoded.manualUsages.isEmpty)
        #expect(decoded.mailbox == nil)

        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["mailbox"] is NSNull)
    }

    @Test("缺 mailbox 键解不开，null 才是没用过信箱")
    func missingMailboxKeyFails() throws {
        let payload = TransferPayload(
            connections: [],
            subscriptions: [],
            preferences: TransferPreferences(
                includeAWSInGlobalRefresh: false,
                isReminderEnabled: false,
                reminderSchedule: ReminderSchedule(frequency: .weekly, hour: 21, minute: 0),
                appearanceRaw: "system",
                hasCompletedOnboarding: false,
                providerHistoryRangeRaw: "days30"
            )
        )
        let data = try JSONEncoder().encode(payload)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "mailbox")
        let stripped = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TransferPayload.self, from: stripped)
        }
    }

    @Test("描述里不打印凭据值")
    func connectionDescriptionRedactsSecrets() {
        let connection = TransferConnection(
            accountID: AccountID.fixture(for: .openai),
            providerID: .openai,
            isEnabled: true,
            sortIndex: 1,
            credentialReference: "credential.openai",
            includeInGlobalRefresh: true,
            credentialFields: ["apiToken": "sk-live-should-not-appear"]
        )
        #expect(!connection.description.contains("sk-live-should-not-appear"))
        #expect(!connection.debugDescription.contains("sk-live-should-not-appear"))
        #expect(connection.description.contains("apiToken"))
    }
}
