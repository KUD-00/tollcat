import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct QdrantBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let key = "QDRANT-MANAGEMENT-KEY-MUST-NOT-LEAK"
    private let accountID = "b3f1c0de-0000-4000-8000-000000000001"

    @Test("取草稿发票，毫分要除以 100000")
    func readsDraftInvoiceInMillicents() async throws {
        let client = fullStub()
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)

        #expect(snapshot.kind == .usage)
        // 1985000 毫分 = $19.85。按「分」算会变成 $19850，差 1000 倍。
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "19.85")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([key]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("已付的那张不算进当期")
    func ignoresPaidInvoices() {
        let invoices = [
            QdrantBillingProvider.Invoice(
                id: "paid", number: "QC-1", totalAmount: FlexibleDecimal(Decimal(9_900_000)),
                createdAt: "2026-08-05T00:00:00Z", status: "INVOICE_STATUS_PAID"
            ),
            QdrantBillingProvider.Invoice(
                id: "draft", number: "", totalAmount: FlexibleDecimal(Decimal(100_000)),
                createdAt: "2026-08-01T00:00:00Z", status: QdrantBillingProvider.draftStatus
            ),
        ]
        let draft = QdrantBillingProvider.draftInvoice(invoices)
        #expect(draft?.id == "draft")
        #expect(QdrantBillingProvider.money(millicents: draft?.totalAmount) == Money(usd: 1))
    }

    @Test("认证走 apikey 前缀，不是 Bearer")
    func usesApikeyScheme() async throws {
        let client = fullStub()
        _ = try await provider(client).fetch(credential: pinnedCredential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "apikey \(key)")
    }

    @Test("没填账号就自己查一次 /accounts")
    func discoversAccountWhenUnpinned() async throws {
        let client = LiveProviderHarness.stub([
            (
                QdrantBillingProvider.accountsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("qdrant-accounts"))
            ),
            (
                QdrantBillingProvider.meteringsURL(accountID: accountID),
                LiveProviderHarness.json(["items": [] as [Any]])
            ),
            (
                QdrantBillingProvider.invoicesURL(accountID: accountID),
                LiveProviderHarness.body(LiveProviderHarness.fixture("qdrant-invoices"))
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .qdrant, fields: [.apiKey: key])
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "19.85")!))
        #expect(client.urls.first == QdrantBillingProvider.accountsURL)
    }

    @Test("还没生成草稿时报「没读到」，不是 $0")
    func noDraftIsNotZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                QdrantBillingProvider.meteringsURL(accountID: accountID),
                LiveProviderHarness.json(["items": [] as [Any]])
            ),
            (
                QdrantBillingProvider.invoicesURL(accountID: accountID),
                LiveProviderHarness.json(["items": []])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(!snapshot.hasBillableMetrics)
    }

    private func fullStub() -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (
                QdrantBillingProvider.meteringsURL(accountID: accountID),
                LiveProviderHarness.json(["items": [] as [Any]])
            ),
            (
                QdrantBillingProvider.invoicesURL(accountID: accountID),
                LiveProviderHarness.body(LiveProviderHarness.fixture("qdrant-invoices"))
            ),
        ])
    }

    private var pinnedCredential: Credential {
        Credential(providerID: .qdrant, fields: [.apiKey: key, .accountID: accountID])
    }

    private func provider(_ client: any HTTPClient) -> QdrantBillingProvider {
        QdrantBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.catalogRates)
    }
}
