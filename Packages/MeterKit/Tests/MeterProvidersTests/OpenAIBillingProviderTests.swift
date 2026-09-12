import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct OpenAIBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-admin-MUST-NOT-LEAK"

    @Test("正常响应：数字和字符串 amount.value 都计入")
    func successMapsDailyCosts() async throws {
        let client = stub(LiveProviderHarness.fixture("openai-organization-costs"))
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.providerID == .openai)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 7.62))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(roundedUSD: 3.12))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 2)] == Money(roundedUSD: 4.50))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        #expect(client.urls.allSatisfy { $0.query?.contains(secret) != true })
    }

    @Test("空 data 是 $0")
    func emptyDataIsZero() async throws {
        let client = stub(try! JSONSerialization.data(withJSONObject: [
            "object": "page",
            "has_more": false,
            "data": [] as [Any],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.dailyUSD?.isEmpty == true)
    }

    @Test("分页会跟着 next_page 再打一次")
    func followsNextPage() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let start = Int(window.start.timeIntervalSince1970)
        let first = try! JSONSerialization.data(withJSONObject: [
            "object": "page",
            "has_more": true,
            "next_page": "cursor-2",
            "data": [
                [
                    "object": "bucket",
                    "start_time": start,
                    "results": [
                        ["amount": ["value": 1, "currency": "usd"]],
                    ],
                ],
            ],
        ])
        let second = try! JSONSerialization.data(withJSONObject: [
            "object": "page",
            "has_more": false,
            "data": [
                [
                    "object": "bucket",
                    "start_time": start + 86400,
                    "results": [
                        ["amount": ["value": "2.5", "currency": "usd"]],
                    ],
                ],
            ],
        ])
        let client = LiveProviderHarness.stub([
            (OpenAIBillingProvider.costsURL(startTime: start, page: nil), LiveProviderHarness.body(first)),
            (OpenAIBillingProvider.costsURL(startTime: start, page: "cursor-2"), LiveProviderHarness.body(second)),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 3.50))
        #expect(client.urls.count == 2)
    }

    @Test("401 / 403 / 429 / 5xx")
    func statusMapping() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
        await expectStatus(429, code: .rateLimited, key: .rateLimited)
        await expectStatus(502, code: .serviceUnavailable, key: .serviceUnavailable)
    }

    @Test("历史窗口从更早的 start_time 翻页，合计只数本月")
    func historyUsesEarlierStartTimeAndKeepsCurrentMonthTotal() async throws {
        let span = CalendarMonthWindow.spanning(
            for: .availableHistory,
            lookbackMonths: OpenAIBillingProvider.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let start = Int(span.start.timeIntervalSince1970)
        let july = Int(LiveProviderHarness.date(2026, 7, 5).timeIntervalSince1970)
        let august = Int(LiveProviderHarness.date(2026, 8, 1).timeIntervalSince1970)
        let client = LiveProviderHarness.stub([
            (
                OpenAIBillingProvider.costsURL(startTime: start, limit: 180, page: nil),
                LiveProviderHarness.json([
                    "object": "page",
                    "has_more": false,
                    "data": [
                        [
                            "start_time": july,
                            "results": [["amount": ["value": 9, "currency": "usd"]]],
                        ],
                        [
                            "start_time": august,
                            "results": [["amount": ["value": 2, "currency": "usd"]]],
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: credential,
            horizon: .availableHistory
        )
        #expect(snapshot.currentSpendUSD == Money(usd: 2))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 7, 5)] == Money(usd: 9))
        #expect(client.urls.first?.query?.contains("limit=180") == true)
        #expect(client.urls.first?.query?.contains("start_time=\(start)") == true)
    }

    @Test("缺 amount 的 bucket 跳过")
    func missingAmount() async throws {
        let client = stub(try! JSONSerialization.data(withJSONObject: [
            "data": [
                [
                    "start_time": 1785542400,
                    "results": [["object": "organization.costs.result"]],
                ],
            ],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("非 usd 拒绝换算")
    func rejectsNonUSD() async {
        let client = stub(try! JSONSerialization.data(withJSONObject: [
            "data": [
                [
                    "start_time": 1785542400,
                    "results": [
                        ["amount": ["value": 3, "currency": "eur"]],
                    ],
                ],
            ],
        ]))
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("缺少 Admin Key")
    func missingKey() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .openai, fields: [:])
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
            try await provider(stub(Data("{}".utf8), status: status)).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .openai, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> OpenAIBillingProvider {
        OpenAIBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly))
    }

    private func stub(_ data: Data, status: Int = 200) -> RecordingHTTPClient {
        let start = Int(CalendarMonthWindow.current(now: now, calendar: calendar).start.timeIntervalSince1970)
        return LiveProviderHarness.stub([
            (OpenAIBillingProvider.costsURL(startTime: start, page: nil), LiveProviderHarness.body(data, status: status)),
        ])
    }
}
