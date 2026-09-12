import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct VercelBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "vercel-token-MUST-NOT-LEAK"
    private let team = "team_example"

    @Test("正常 JSONL：数字和字符串 BilledCost 都计入")
    func successMapsJSONL() async throws {
        let client = stubCharges(LiveProviderHarness.fixture("vercel-billing-charges", ext: "jsonl"))
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.providerID == .vercel)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "137.25")!))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: 123))
        #expect(
            snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 2)]
                == Money(usd: Decimal(string: "14.25")!)
        )
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("明细按服务分组，项目名进 scope")
    func linesGroupByServiceWithProjectScope() async throws {
        let client = stubCharges(LiveProviderHarness.fixture("vercel-billing-charges", ext: "jsonl"))
        let snapshot = try await provider(client).fetch(credential: credential)

        let lines = try #require(snapshot.lines)
        // Fast Data Transfer 的两个项目各一条，不合并——scope 不同就是不同的格。
        #expect(lines.count == 3)
        #expect(Set(lines.map(\.scope)) == ["demo", "marketing"])

        let marketing = try #require(lines.first { $0.scope == "marketing" })
        #expect(marketing.category == "Fast Data Transfer")
        #expect(marketing.label == "Fast Data Transfer")
        #expect(marketing.amountUSD == Money(usd: Decimal(string: "3.20")!))
        #expect(marketing.quantity == 4)
        #expect(marketing.unit == "GB")
        // 这家没有原价栏，抵扣无从说起。
        #expect(marketing.listUSD == nil)
    }

    @Test("没有 ServiceName 的行不进明细，钱照样进日线")
    func rowsWithoutServiceNameAreSkippedInLines() async throws {
        let jsonl = Data("""
        {"BilledCost":2,"BillingCurrency":"USD","ChargePeriodStart":"2026-08-01T00:00:00.000Z"}
        """.utf8)
        let client = stubCharges(jsonl)
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: 2))
        #expect(snapshot.lines == nil)
    }

    @Test("空 JSONL 是用量 $0，不编使用比例")
    func emptyJSONLIsZeroUsage() async throws {
        let client = stubCharges(Data())
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.freeQuotaUsedRatio == nil)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
    }

    @Test("charges 404 是用量 $0，不是连不上")
    func notFoundChargesIsZeroUsage() async throws {
        let body = Data(#"{"error":{"code":"costs_not_found","message":"Costs not found"}}"#.utf8)
        let client = stubCharges(body, status: 404)
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
        #expect(snapshot.freeQuotaUsedRatio == nil)
        #expect(snapshot.dailyUSD == nil)
    }

    @Test("没有 teamId 时 Hobby 的 charges 404 仍是用量 $0")
    func discoveredTeamNotFoundChargesIsZeroUsage() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let body = Data(#"{"error":{"code":"costs_not_found","message":"Costs not found"}}"#.utf8)
        let client = LiveProviderHarness.stub([
            (
                VercelBillingProvider.userURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("vercel-user"))
            ),
            (
                VercelBillingProvider.chargesURL(from: window.start, to: window.nextStart, teamID: team),
                LiveProviderHarness.body(body, status: 404)
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .vercel, fields: [.apiToken: secret])
        )
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("401 / 403 / 429 / 5xx")
    func statusMapping() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
        await expectStatus(429, code: .rateLimited, key: .rateLimited)
        await expectStatus(503, code: .serviceUnavailable, key: .serviceUnavailable)
    }

    @Test("缺 BilledCost 的行当 0")
    func missingBilledCost() async throws {
        let line = #"{"BillingCurrency":"USD","ChargePeriodStart":"2026-08-01T00:00:00.000Z","ChargeCategory":"Usage"}"#
        let client = stubCharges(Data(line.utf8))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.hasBillableMetrics)
    }

    @Test("非 USD 拒绝换算")
    func rejectsNonUSD() async {
        let line = #"{"BilledCost":1,"BillingCurrency":"EUR","ChargePeriodStart":"2026-08-01T00:00:00.000Z"}"#
        let client = stubCharges(Data(line.utf8))
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("没有 teamId 时先打 /v2/user")
    func discoversDefaultTeam() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let client = LiveProviderHarness.stub([
            (
                VercelBillingProvider.userURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("vercel-user"))
            ),
            (
                VercelBillingProvider.chargesURL(from: window.start, to: window.nextStart, teamID: team),
                LiveProviderHarness.body(LiveProviderHarness.fixture("vercel-billing-charges", ext: "jsonl"))
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .vercel, fields: [.apiToken: secret])
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "137.25")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("缺少 token")
    func missingToken() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .vercel, fields: [:])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(stubCharges(Data("{}".utf8), status: status)).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .vercel, fields: [.apiToken: secret, .accountID: team])
    }

    private func provider(_ client: any HTTPClient) -> VercelBillingProvider {
        VercelBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly))
    }

    private func stubCharges(_ data: Data, status: Int = 200) -> RecordingHTTPClient {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        return LiveProviderHarness.stub([
            (
                VercelBillingProvider.chargesURL(from: window.start, to: window.nextStart, teamID: team),
                LiveProviderHarness.body(data, status: status)
            ),
        ])
    }
}
