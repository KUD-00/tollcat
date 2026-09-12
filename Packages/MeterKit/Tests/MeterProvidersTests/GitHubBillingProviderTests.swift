import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct GitHubBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "github_pat_MUST-NOT-LEAK"
    private let login = "octocat"

    @Test("正常响应：月费和从量拆开，Copilot 不进日线")
    func successMapsUsageItems() async throws {
        let client = stubUsage(LiveProviderHarness.fixture("github-billing-usage"))
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.providerID == .github)
        #expect(snapshot.kind == .planAndUsage)
        #expect(snapshot.committedMonthlyUSD == Money(usd: 4))
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 0.08))
        #expect(snapshot.chargeDayOfMonth == 3)
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(roundedUSD: 0.08))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 3)] == nil)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        #expect(client.urls.contains { $0.path == "/user" })
        #expect(client.urls.contains { $0.path == "/users/octocat/settings/billing/usage" })
    }

    @Test("空 usageItems 是 $0 读数")
    func emptyItemsAreZero() async throws {
        let client = stubUsage(try! JSONSerialization.data(withJSONObject: [
            "usageItems": [] as [Any],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .planAndUsage)
        #expect(snapshot.committedMonthlyUSD == nil)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
    }

    @Test("401 / 403 / 429 / 5xx / 404")
    func statusMapping() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
        await expectStatus(429, code: .rateLimited, key: .rateLimited)
        await expectStatus(500, code: .serviceUnavailable, key: .serviceUnavailable)
        await expectStatus(404, code: .billingAPIUnavailable, key: .billingAPIUnavailable)
    }

    @Test("缺 netAmount 的行当 0")
    func missingAmount() async throws {
        let client = stubUsage(try! JSONSerialization.data(withJSONObject: [
            "usageItems": [
                ["date": "2026-08-01", "product": "actions"],
            ],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.committedMonthlyUSD == nil)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("Copilot 超额请求不是月费，进从量")
    func copilotOverageIsUsage() async throws {
        let client = stubUsage(try! JSONSerialization.data(withJSONObject: [
            "usageItems": [
                [
                    "date": "2026-08-02",
                    "product": "copilot",
                    "sku": "Copilot Premium Request",
                    "unitType": "requests",
                    "netAmount": 1.2,
                ],
            ],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.committedMonthlyUSD == nil)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 1.2))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 2)] == Money(roundedUSD: 1.2))
    }

    @Test("明细带上仓库、原价和用量，不进折算主路径")
    func linesCarryRepositoryAndListPrice() async throws {
        let client = stubUsage(LiveProviderHarness.fixture("github-billing-usage"))
        let snapshot = try await provider(client).fetch(credential: credential)

        let lines = try #require(snapshot.lines)
        #expect(lines.count == 2)
        let actions = try #require(lines.first { $0.label == "Actions Linux" })
        #expect(actions.category == "actions")
        #expect(actions.scope == "RelayOS")
        #expect(actions.amountUSD == Money(roundedUSD: 0.08))
        #expect(actions.listUSD == Money(roundedUSD: 0.08))
        #expect(actions.quantity == 10)
        #expect(actions.unit == "minutes")
        // 原价等于实收就没有抵扣可说。
        #expect(actions.discountUSD == nil)
        // 月费那条也在明细里：明细回答"钱花在哪"，不管它进哪个折算槽。
        #expect(lines.contains { $0.label == "Copilot Business" })
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 0.08))
    }

    @Test("被免费额度吃掉的行仍然留在明细里，原价挂着")
    func freeQuotaLinesSurviveWithListPrice() async throws {
        let client = stubUsage(try! JSONSerialization.data(withJSONObject: [
            "usageItems": [
                [
                    "date": "2026-08-02",
                    "product": "actions",
                    "sku": "Actions Linux",
                    "repositoryName": "RelayOS",
                    "unitType": "Minutes",
                    "quantity": 1667,
                    "grossAmount": 10.002,
                    "discountAmount": 10.002,
                    "netAmount": 0,
                ],
            ],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)

        let line = try #require(snapshot.lines?.first)
        #expect(line.amountUSD == .zero)
        #expect(line.listUSD == Money(usd: Decimal(string: "10.002")!))
        #expect(line.discountUSD == Money(usd: Decimal(string: "10.002")!))
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("同一个 sku 分散在多天，明细按 (product, sku, 仓库) 合成一条")
    func linesMergeAcrossDays() async throws {
        let client = stubUsage(try! JSONSerialization.data(withJSONObject: [
            "usageItems": [
                [
                    "date": "2026-08-01",
                    "product": "actions", "sku": "Actions Linux", "repositoryName": "RelayOS",
                    "unitType": "Minutes", "quantity": 4, "netAmount": 0.024,
                ],
                [
                    "date": "2026-08-02",
                    "product": "actions", "sku": "Actions Linux", "repositoryName": "RelayOS",
                    "unitType": "Minutes", "quantity": 2, "netAmount": 0.012,
                ],
                [
                    "date": "2026-08-02",
                    "product": "actions", "sku": "Actions Linux", "repositoryName": "gotanken",
                    "unitType": "Minutes", "quantity": 59, "netAmount": 0.354,
                ],
            ],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)

        let lines = try #require(snapshot.lines)
        #expect(lines.count == 2)
        let relay = try #require(lines.first { $0.scope == "RelayOS" })
        #expect(relay.quantity == 6)
        #expect(relay.amountUSD == Money(usd: Decimal(string: "0.036")!))
        // 排序按金额从大到小，gotanken 那条更贵。
        #expect(lines.first?.scope == "gotanken")
    }

    @Test("拉取更多历史按月逐次请求，总数仍然只数本月")
    func historyFetchesEachMonthAndKeepsCurrentMonthTotal() async throws {
        let months = GitHubBillingProvider.months(for: .availableHistory, now: now, calendar: calendar)
        #expect(months.count == GitHubBillingProvider.descriptor.historyLookbackMonths + 1)
        #expect(months.last?.year == 2026)
        #expect(months.last?.month == 8)

        var pairs: [(URL, StubHTTPResponse)] = [
            (
                GitHubBillingProvider.userURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("github-user"))
            ),
        ]
        for month in months {
            let isCurrent = month.month == 8 && month.year == 2026
            let payload: [String: Any] = [
                "usageItems": [
                    [
                        "date": isCurrent ? "2026-08-05" : "2026-07-05",
                        "product": "actions",
                        "sku": "Actions Linux",
                        "unitType": "Minutes",
                        "netAmount": 1,
                    ],
                ],
            ]
            pairs.append((
                GitHubBillingProvider.userUsageURL(
                    login: login,
                    year: month.year ?? 0,
                    month: month.month ?? 0
                ),
                LiveProviderHarness.json(payload)
            ))
        }
        let client = LiveProviderHarness.stub(pairs)
        let snapshot = try await provider(client).fetch(
            credential: credential,
            horizon: .availableHistory
        )

        #expect(client.urls.filter { $0.path.hasSuffix("/billing/usage") }.count == months.count)
        // 十三个月各 $1，本月只认 8 月那天。
        #expect(snapshot.currentSpendUSD == Money(usd: 1))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 7, 5)] == Money(usd: 12))
        // 明细同样只数本月：十三个月的 sku 合成一坨挂"本账期"上会骗人。
        #expect(snapshot.lines?.count == 1)
        #expect(snapshot.lines?.first?.amountUSD == Money(usd: 1))
    }

    @Test("历史窗口不把上个月的月费加进本月档位")
    func historyDoesNotInflateCommittedMonthly() async throws {
        let months = GitHubBillingProvider.months(for: .availableHistory, now: now, calendar: calendar)
        var pairs: [(URL, StubHTTPResponse)] = [
            (
                GitHubBillingProvider.userURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("github-user"))
            ),
        ]
        for month in months {
            let isCurrent = month.month == 8 && month.year == 2026
            pairs.append((
                GitHubBillingProvider.userUsageURL(
                    login: login,
                    year: month.year ?? 0,
                    month: month.month ?? 0
                ),
                LiveProviderHarness.json([
                    "usageItems": [
                        [
                            "date": isCurrent ? "2026-08-03" : "2026-07-03",
                            "product": "copilot",
                            "sku": "Copilot Business",
                            "unitType": "month",
                            "netAmount": 4,
                        ],
                    ],
                ] as [String: Any])
            ))
        }
        let snapshot = try await provider(LiveProviderHarness.stub(pairs)).fetch(
            credential: credential,
            horizon: .availableHistory
        )
        // 十三个月各一笔 $4 的月费，档位只能是 $4。
        #expect(snapshot.committedMonthlyUSD == Money(usd: 4))
        #expect(snapshot.chargeDayOfMonth == 3)
    }

    @Test("当月口径只请求一次")
    func currentMonthFetchesOnce() async throws {
        let client = stubUsage(LiveProviderHarness.fixture("github-billing-usage"))
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.urls.filter { $0.path.hasSuffix("/billing/usage") }.count == 1)
    }

    @Test("缺少 PAT")
    func missingToken() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .github, fields: [:])
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
            let client = LiveProviderHarness.stub([
                (GitHubBillingProvider.userURL, LiveProviderHarness.emptyJSON(status: status)),
            ])
            return try await provider(client).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .github, fields: [.personalAccessToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> GitHubBillingProvider {
        GitHubBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }

    private func stubUsage(_ data: Data) -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (
                GitHubBillingProvider.userURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("github-user"))
            ),
            (
                GitHubBillingProvider.userUsageURL(login: login, year: 2026, month: 8),
                LiveProviderHarness.body(data)
            ),
        ])
    }
}
