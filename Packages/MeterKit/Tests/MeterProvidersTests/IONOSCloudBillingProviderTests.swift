import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct IONOSCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "ionos-jwt-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("多张发票 total.quantity 相加，欧元按目录汇率折")
    func sumsInvoiceTotals() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("ionos-invoices"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "14.3")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer，路径带 YYYY-MM")
    func usesBearerAndPeriod() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("ionos-invoices"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(invoicesURL.path.hasSuffix("/billing/invoices/2026-08"))
    }

    @Test("当月发票还没出就报没读到，不是 $0")
    func missingInvoiceIsUnread() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.json([] as [Any])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(snapshot.kind == .usage)
    }

    @Test("404 也是没读到，不是账单接口挂了")
    func notFoundIsUnread() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.json(["message": "not found"], status: 404)),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
    }

    @Test("没有汇率的欧元账户直接拒绝")
    func rejectsEuroWithoutRate() async {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("ionos-invoices"))),
        ])
        await #expect(throws: ProviderError.unsupportedCurrency(providerID: .ionos)) {
            _ = try await IONOSCloudBillingProvider(
                httpClient: client,
                now: { now },
                calendar: calendar,
                rateSource: SharedExchangeRates(.usdOnly)
            ).fetch(credential: credential)
        }
    }

    private var invoicesURL: URL {
        IONOSCloudBillingProvider.invoicesURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .ionos, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> IONOSCloudBillingProvider {
        IONOSCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
