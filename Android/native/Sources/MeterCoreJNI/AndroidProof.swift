#if os(Android)
import Foundation
import MeterBridge
import MeterCore
import MeterProviders

/// 与 `FixtureAggregationTests.designFixturesSumToSpecTotal` 同一条向量。
enum AndroidProof {
    // ≈ 标记已随 Confidence.requiresApproximationMark 一起退役，formatted 不再带 ≈。
    static let expectedFormatted = "$47.20"
    static let expectedTotal = Money(usd: 47.20)
    static let expectedConfidence = Confidence.estimated
    static let expectedStubSpend = Money(usd: 11.05)

    static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func now(_ calendar: Calendar = calendar()) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 16, hour: 12))!
    }

    static func compute() throws -> MonthToDate {
        let calendar = calendar()
        let now = now(calendar)
        let snapshots = try FixtureLoader.designSnapshots(now: now, calendar: calendar).map { snapshot in
            var copy = snapshot
            copy.accountID = AccountID.fixture(for: snapshot.providerID)
            return copy
        }
        return MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar
        )
    }

    static func matches(_ result: MonthToDate) -> Bool {
        result.totalUSD == expectedTotal
            && result.confidence == expectedConfidence
            && result.formattedTotal == expectedFormatted
            && result.estimatedAccounts == [AccountID.fixture(for: .neon)]
    }

    static func estimatedLabel(_ result: MonthToDate) -> String {
        result.estimatedAccounts.contains(AccountID.fixture(for: .neon))
            ? "neon"
            : result.estimatedAccounts.map(\.rawValue.uuidString).joined(separator: ",")
    }

    static func fixtureProofJSON() -> String {
        do {
            let result = try compute()
            return object([
                ("formatted", .string(result.formattedTotal)),
                ("total", .string(result.totalUSD.formatted())),
                ("confidence", .string(result.confidence.rawValue)),
                ("estimated", .string(estimatedLabel(result))),
                ("matches", .bool(matches(result))),
                ("source", .string("FixtureLoader.designSnapshots")),
            ])
        } catch {
            return object([
                ("formatted", .string("—")),
                ("matches", .bool(false)),
                ("source", .string("FixtureLoader.designSnapshots")),
                ("error", .string(String(describing: error))),
            ])
        }
    }

    static func stubFetchCloudflareJSON() -> String {
        do {
            let snapshot = try stubFetchCloudflare()
            let spend = snapshot.currentSpendUSD ?? .zero
            let ok = spend == expectedStubSpend
            return object([
                ("provider", .string("cloudflare")),
                ("spend", .string(spend.formatted())),
                ("ok", .bool(ok)),
                ("parser", .string("CloudflareBillingProvider")),
                ("source", .string("StubHTTPClient")),
            ])
        } catch {
            return object([
                ("provider", .string("cloudflare")),
                ("ok", .bool(false)),
                ("parser", .string("CloudflareBillingProvider")),
                ("source", .string("StubHTTPClient")),
                ("error", .string(String(describing: error))),
            ])
        }
    }

    static func stubFetchCloudflare() throws -> Snapshot {
        let calendar = calendar()
        let now = now(calendar)
        guard let body = OfficialAPIFixture.data(named: "cloudflare-billable-usage"),
              let info = OfficialAPIFixture.data(named: "cloudflare-billable-usage-info") else {
            throw ProviderError.fixtureUnavailable(providerID: .cloudflare)
        }
        let account = "023e105f4ecef8ad9ca31a8372d0c353"
        // 路径和真 URL 一样。info 和当前周期是两条；按 path 回退不能把带 from/to 的上一周期配成当前样例。
        let usage = URL(string: "https://api.cloudflare.com/client/v4/accounts/\(account)/billable-usage")!
        let infoURL = URL(string: "https://api.cloudflare.com/client/v4/accounts/\(account)/billable-usage/info")!
        let client = StubHTTPClient(responses: [
            usage: StubHTTPResponse(body: body),
            infoURL: StubHTTPResponse(body: info),
        ])
        let provider = CloudflareBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
        let credential = Credential(
            providerID: .cloudflare,
            fields: [
                .apiToken: "cf-token-MUST-NOT-LEAK",
                .accountID: account,
            ]
        )
        return try JNIAsync.run {
            try await provider.fetch(credential: credential)
        }
    }

    private enum JSONValue {
        case string(String)
        case bool(Bool)

        var rendered: String {
            switch self {
            case .string(let value):
                return "\"\(escape(value))\""
            case .bool(let value):
                return value ? "true" : "false"
            }
        }
    }

    private static func object(_ pairs: [(String, JSONValue)]) -> String {
        let body = pairs.map { "\"\(escape($0.0))\":\($0.1.rendered)" }.joined(separator: ",")
        return "{\(body)}"
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
#endif
