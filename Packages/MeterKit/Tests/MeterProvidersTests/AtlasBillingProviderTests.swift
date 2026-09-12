import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct AtlasBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let clientID = "mdb_sa_id_FIXTURE"
    private let clientSecret = "ATLAS-SECRET-MUST-NOT-LEAK"
    private let orgID = "5f7a1c2b3d4e5f6a7b8c9d0e"

    @Test("先换 token 再读待结发票，行项目摊成日线，差额落月初")
    func exchangesTokenThenReadsPendingInvoice() async throws {
        let client = fullStub()
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)

        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "47.13")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))

        let daily = try #require(snapshot.dailyUSD)
        // 32.00 的机器费 + 4713 与行项目 4700 的 0.13 差额一起落在月初。
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: Decimal(string: "32.13")!))
        #expect(daily[LiveProviderHarness.date(2026, 8, 9)] == Money(usd: 12))
        #expect(daily[LiveProviderHarness.date(2026, 8, 14)] == Money(usd: 3))
        #expect(daily.values.reduce(Money.zero, +) == snapshot.currentSpendUSD)
    }

    @Test("换 token 走 Basic，业务请求走 Bearer + 版本化 Accept")
    func authHeadersAreCorrect() async throws {
        let client = fullStub()
        _ = try await provider(client).fetch(credential: pinnedCredential)

        let token = try #require(client.requests.first)
        #expect(token.httpMethod == "POST")
        #expect(
            token.value(forHTTPHeaderField: "Authorization")
            == "Basic \(ProviderOAuth.basicValue(id: clientID, secret: clientSecret))"
        )
        #expect(String(data: token.httpBody ?? Data(), encoding: .utf8) == "grant_type=client_credentials")

        let invoice = try #require(client.requests.last)
        #expect(invoice.value(forHTTPHeaderField: "Authorization") == "Bearer fixture-atlas-access-token")
        #expect(invoice.value(forHTTPHeaderField: "Accept") == AtlasBillingProvider.acceptVersion)
        #expect(client.leakedSecrets([clientSecret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("没填组织就自己查一次 /orgs")
    func discoversOrganizationWhenUnpinned() async throws {
        let client = LiveProviderHarness.stub([
            (
                AtlasBillingProvider.tokenURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("atlas-oauth-token"))
            ),
            (
                AtlasBillingProvider.organizationsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("atlas-orgs"))
            ),
            (
                AtlasBillingProvider.pendingInvoicesURL(orgID: orgID),
                LiveProviderHarness.body(LiveProviderHarness.fixture("atlas-pending-invoices"))
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(
                providerID: .atlas,
                fields: [.clientID: clientID, .clientSecret: clientSecret]
            )
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "47.13")!))
        #expect(client.urls.contains(AtlasBillingProvider.organizationsURL))
    }

    @Test("待结发票直接返回数组时也能解出来")
    func decodesBareArrayResponse() throws {
        let bare = Data("""
        [{"amountBilledCents": 1000, "startDate": "2026-08-01T00:00:00Z"}]
        """.utf8)
        let invoices = try AtlasBillingProvider.decodeInvoices(bare)
        #expect(invoices.count == 1)
        #expect(invoices[0].amountBilledCents == 1000)
    }

    @Test("endDate 是下期起点，收进来要退一天")
    func periodEndIsExclusive() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = BillingPeriodResolver.resolve(
            startRaw: "2026-08-01T00:00:00Z",
            endRaw: "2026-09-01T00:00:00Z",
            endConvention: .exclusive,
            fallback: window,
            calendar: calendar
        )
        #expect(period.start == LiveProviderHarness.date(2026, 8, 1))
        #expect(period.end == LiveProviderHarness.date(2026, 8, 31))
    }

    @Test("上个月那张还挂在 pending 时，不把它的钱记进本月")
    func stalePendingInvoiceIsNotCountedThisMonth() async throws {
        let payload: [String: Any] = [
            "results": [
                [
                    "id": "inv_202607",
                    "statusName": "PENDING",
                    "startDate": "2026-07-01T00:00:00Z",
                    "endDate": "2026-08-01T00:00:00Z",
                    "amountBilledCents": 9900,
                    "lineItems": [
                        [
                            "sku": "CLUSTER_TIER_M10",
                            "startDate": "2026-07-05T00:00:00Z",
                            "totalPriceCents": 9900,
                        ],
                    ],
                ],
                [
                    "id": "inv_202608",
                    "statusName": "PENDING",
                    "startDate": "2026-08-01T00:00:00Z",
                    "endDate": "2026-09-01T00:00:00Z",
                    "amountBilledCents": 1200,
                    "lineItems": [
                        [
                            "sku": "CLUSTER_TIER_M10",
                            "startDate": "2026-08-09T00:00:00Z",
                            "totalPriceCents": 1200,
                        ],
                    ],
                ],
            ],
        ]
        let client = LiveProviderHarness.stub([
            (
                AtlasBillingProvider.tokenURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("atlas-oauth-token"))
            ),
            (
                AtlasBillingProvider.pendingInvoicesURL(orgID: orgID),
                LiveProviderHarness.json(payload)
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)

        #expect(snapshot.currentSpendUSD == Money(usd: 12))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        // 7/5 那笔不能被 clamp 拽到 8/1。
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == nil)
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 9)] == Money(usd: 12))
    }

    private func fullStub() -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (
                AtlasBillingProvider.tokenURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("atlas-oauth-token"))
            ),
            (
                AtlasBillingProvider.pendingInvoicesURL(orgID: orgID),
                LiveProviderHarness.body(LiveProviderHarness.fixture("atlas-pending-invoices"))
            ),
        ])
    }

    private var pinnedCredential: Credential {
        Credential(
            providerID: .atlas,
            fields: [.clientID: clientID, .clientSecret: clientSecret, .accountID: orgID]
        )
    }

    private func provider(_ client: any HTTPClient) -> AtlasBillingProvider {
        AtlasBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
