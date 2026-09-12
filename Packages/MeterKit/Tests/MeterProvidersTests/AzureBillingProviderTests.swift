import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct AzureBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let tenantID = "11111111-2222-3333-4444-555555555555"
    private let clientID = "66666666-7777-8888-9999-000000000000"
    private let clientSecret = "AZURE-SECRET-MUST-NOT-LEAK"
    private let subscriptionID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

    @Test("换 token 后按天读 MonthToDate，UsageDate 是紧凑数字")
    func readsDailyMonthToDate() async throws {
        let client = fullStub()
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "8.5")!))
        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: Decimal(string: "3.25")!))
        #expect(daily[LiveProviderHarness.date(2026, 8, 2)] == Money(usd: Decimal(string: "4.1")!))
        #expect(daily[LiveProviderHarness.date(2026, 8, 15)] == Money(usd: Decimal(string: "1.15")!))
        #expect(client.leakedSecrets([clientSecret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("client_secret 只在表单体里，不进 URL")
    func secretStaysInFormBody() async throws {
        let client = fullStub()
        _ = try await provider(client).fetch(credential: credential)

        let token = try #require(client.requests.first)
        let body = String(data: token.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("grant_type=client_credentials"))
        #expect(body.contains("client_id=\(clientID)"))
        #expect(body.contains("scope=https%3A%2F%2Fmanagement.azure.com%2F.default"))
        #expect(token.url?.absoluteString.contains(clientSecret) == false)
    }

    @Test("按列名找下标，列顺序换了也算得对")
    func columnOrderDoesNotMatter() throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let properties = AzureBillingProvider.Properties(
            columns: [
                AzureBillingProvider.Column(name: "UsageDate", type: "Number"),
                AzureBillingProvider.Column(name: "Currency", type: "String"),
                AzureBillingProvider.Column(name: "PreTaxCost", type: "Number"),
            ],
            rows: [
                [.number(20260803), .text("USD"), .number(Decimal(string: "2.50")!)],
            ]
        )
        var currency = CurrencyAccumulator()
        let daily = try AzureBillingProvider.accumulate(
            properties, window: window, calendar: calendar, currency: &currency
        )
        #expect(daily.daily[LiveProviderHarness.date(2026, 8, 3)] == Money(usd: Decimal(string: "2.5")!))
    }

    @Test("汇率表里没有这个币种才拒绝，有就换算")
    func convertsWhenRateIsKnownAndRejectsOtherwise() throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let properties = AzureBillingProvider.Properties(
            columns: [
                AzureBillingProvider.Column(name: "Cost", type: "Number"),
                AzureBillingProvider.Column(name: "Currency", type: "String"),
            ],
            rows: [[.number(1000), .text("JPY")]]
        )
        var currency = CurrencyAccumulator()
        let daily = try AzureBillingProvider.accumulate(
            properties, window: window, calendar: calendar, currency: &currency
        )
        // 累加阶段只记币种，不换也不拒。
        #expect(daily.total == Money(usd: 1000))

        let base = Snapshot(
            providerID: .azure,
            accountID: AccountID.fixture(for: .azure),
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: daily.total,
            dailyUSD: daily.snapshotDaily
        )

        // 表里没有 JPY：宁可这次没读到，也不按猜的汇率记账。
        #expect(throws: ProviderError.unsupportedCurrency(providerID: .azure)) {
            _ = try base.convertedToUSD(using: currency, rates: .usdOnly)
        }

        let rates = ExchangeRates(usdPerUnit: ["JPY": Decimal(string: "0.00655")!])
        let converted = try base.convertedToUSD(using: currency, rates: rates)
        #expect(converted.currentSpendUSD == Money(usd: Decimal(string: "6.55")!))
        #expect(converted.converted?.currency == "JPY")
        #expect(converted.converted?.amount == 1000)
        #expect(converted.isCurrencyConverted)
    }

    @Test("认不出成本列就报响应异常，不当成 0")
    func unknownCostColumnFails() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let properties = AzureBillingProvider.Properties(
            columns: [AzureBillingProvider.Column(name: "Whatever", type: "Number")],
            rows: [[.number(5)]]
        )
        var currency = CurrencyAccumulator()
        #expect(throws: ProviderError.malformedResponse(providerID: .azure)) {
            _ = try AzureBillingProvider.accumulate(
                properties, window: window, calendar: calendar, currency: &currency
            )
        }
    }

    @Test("四个字段缺一个就报缺凭据")
    func requiresAllFourFields() async {
        let client = LiveProviderHarness.stub([])
        let partial = Credential(
            providerID: .azure,
            fields: [.tenantID: tenantID, .clientID: clientID, .clientSecret: clientSecret]
        )
        await #expect(throws: ProviderError.missingCredential(providerID: .azure)) {
            _ = try await provider(client).fetch(credential: partial)
        }
    }

    private func fullStub() -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (
                AzureBillingProvider.tokenURL(tenantID: tenantID),
                LiveProviderHarness.body(LiveProviderHarness.fixture("azure-oauth-token"))
            ),
            (
                AzureBillingProvider.queryURL(subscriptionID: subscriptionID),
                LiveProviderHarness.body(LiveProviderHarness.fixture("azure-cost-query"))
            ),
        ])
    }

    private var credential: Credential {
        Credential(
            providerID: .azure,
            fields: [
                .tenantID: tenantID,
                .clientID: clientID,
                .clientSecret: clientSecret,
                .accountID: subscriptionID,
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> AzureBillingProvider {
        AzureBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly))
    }
}
