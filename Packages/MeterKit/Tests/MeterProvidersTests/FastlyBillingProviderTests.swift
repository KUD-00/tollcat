import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FastlyBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "FASTLY-TOKEN-MUST-NOT-LEAK"

    @Test("当月至今发票金额直接当合计，周期用发票自己的")
    func readsMonthToDateInvoice() async throws {
        let client = LiveProviderHarness.stub([
            (
                FastlyBillingProvider.monthToDateURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("fastly-month-to-date"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "31.45")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("token 走 Fastly-Key 头，不是 Authorization")
    func usesFastlyKeyHeader() async throws {
        let client = LiveProviderHarness.stub([
            (
                FastlyBillingProvider.monthToDateURL,
                LiveProviderHarness.json(["monthly_transaction_amount": "1.00", "currency_code": "USD"])
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Fastly-Key") == token)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("非美元账户直接拒绝，不做汇率换算")
    func rejectsNonUSD() async throws {
        let client = LiveProviderHarness.stub([
            (
                FastlyBillingProvider.monthToDateURL,
                LiveProviderHarness.json([
                    "monthly_transaction_amount": "28.00",
                    "currency_code": "EUR",
                ])
            ),
        ])
        await #expect(throws: ProviderError.unsupportedCurrency(providerID: .fastly)) {
            _ = try await provider(client).fetch(credential: credential)
        }
    }

    @Test("发票没带周期就回落到当前日历月")
    func fallsBackToCalendarMonth() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = BillingPeriodResolver.resolve(
            startRaw: nil,
            endRaw: nil,
            endConvention: .inclusive,
            fallback: window,
            calendar: calendar
        )
        #expect(period.start == window.start)
        #expect(period.end == window.endInclusive)
    }

    private var credential: Credential {
        Credential(providerID: .fastly, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> FastlyBillingProvider {
        FastlyBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly))
    }
}
