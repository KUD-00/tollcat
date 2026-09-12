import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct NeonBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "neon-key-MUST-NOT-LEAK"
    private let org = "org-example"

    @Test("正常响应：按官方公式把用量算成美元，字符串 value 也能读")
    func successConvertsDocumentedUsage() async throws {
        let client = stubConsumption(LiveProviderHarness.fixture("neon-consumption-history"))
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.providerID == .neon)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD != nil)
        #expect(snapshot.currentSpendUSD!.roundedToCents() == Money(roundedUSD: 0.54))
        #expect(snapshot.dailyUSD?.isEmpty == false)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("明细按 metric 归类，项目 id 进 scope，数量换成计价单位")
    func linesGroupByMetricFamily() async throws {
        let client = stubConsumption(LiveProviderHarness.fixture("neon-consumption-history"))
        let snapshot = try await provider(client).fetch(credential: credential)

        let lines = try #require(snapshot.lines)
        #expect(lines.allSatisfy { $0.scope == "delicate-dawn-54854667" })
        #expect(Set(lines.map(\.category)).isSubset(of: [
            "Compute", "Storage", "Instant restore", "Data transfer", "Branches",
        ]))

        // 计算：原始是 CU-seconds，明细写 CU-hours，和 NeonPlanPricing 的口径一致。
        let compute = try #require(lines.first { $0.label == "Compute" })
        #expect(compute.unit == "CU-hours")
        #expect(compute.quantity != nil)

        // 存储：字节 → GB-months。
        let root = try #require(lines.first { $0.label == "Root branch storage" })
        #expect(root.unit == "GB-months")

        // 公共流量单独算：免费额度按项目扣，所以原价和额度说明都在这条上。
        let transfer = try #require(lines.first { $0.label == "Public network transfer" })
        #expect(transfer.category == "Data transfer")
        #expect(transfer.unit == "GB")
        #expect(transfer.listUSD != nil)
        #expect(transfer.allowanceNote == "First 500 GB per project included")
        // 500 GB 额度以内，实收就是 0——但这条不能因此消失。
        #expect(transfer.amountUSD == .zero)
    }

    @Test("认不出的 metric 不进明细，钱照样进日线")
    func unknownMetricStaysOutOfLines() async throws {
        let payload: [String: Any] = [
            "projects": [
                [
                    "project_id": "p1",
                    "periods": [
                        [
                            "period_plan": "launch",
                            "consumption": [
                                [
                                    "timeframe_start": "2026-08-01T00:00:00Z",
                                    "timeframe_end": "2026-08-02T00:00:00Z",
                                    "metrics": [
                                        ["metric_name": "some_new_metric", "value": 1000],
                                        ["metric_name": "compute_unit_seconds", "value": 3600],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]
        let client = stubConsumption(LiveProviderHarness.json(payload).body)
        let snapshot = try await provider(client).fetch(credential: credential)

        let lines = try #require(snapshot.lines)
        #expect(lines.map(\.label) == ["Compute"])
        #expect(lines[0].quantity == 1)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "0.106")!))
    }

    @Test("空 projects 是 $0")
    func emptyProjectsAreZero() async throws {
        let client = stubConsumption(try! JSONSerialization.data(withJSONObject: [
            "projects": [] as [Any],
        ]))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
    }

    @Test("401 / 403 / 429 / 5xx")
    func statusMapping() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
        await expectStatus(429, code: .rateLimited, key: .rateLimited)
        await expectStatus(500, code: .serviceUnavailable, key: .serviceUnavailable)
    }

    @Test("缺 metric value 的行跳过")
    func missingMetricValue() async throws {
        let payload: [String: Any] = [
            "projects": [
                [
                    "project_id": "p1",
                    "periods": [
                        [
                            "period_plan": "launch",
                            "consumption": [
                                [
                                    "timeframe_start": "2026-08-01T00:00:00Z",
                                    "timeframe_end": "2026-08-02T00:00:00Z",
                                    "metrics": [
                                        ["metric_name": "compute_unit_seconds"],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]
        let client = stubConsumption(try! JSONSerialization.data(withJSONObject: payload))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("没有 apiKey")
    func missingKey() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .neon, fields: [:])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    @Test("能列出组织再拉 consumption")
    func listsOrganizationsWhenNoAccountID() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let client = LiveProviderHarness.stub([
            (
                NeonBillingProvider.organizationsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("neon-organizations"))
            ),
            (
                NeonBillingProvider.consumptionURL(orgID: org, cursor: nil, window: window),
                LiveProviderHarness.body(LiveProviderHarness.fixture("neon-consumption-history"))
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .neon, fields: [.apiKey: secret])
        )
        #expect(snapshot.currentSpendUSD!.roundedToCents() == Money(roundedUSD: 0.54))
        #expect(client.urls.contains(where: { $0.path.contains("/users/me/organizations") }))
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("游标原地打转不把同一个 project 的用量加第二遍")
    func stalledCursorDoesNotDoubleCount() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let page = LiveProviderHarness.fixture("neon-consumption-history")
        // 厂商回同一个游标、同一批 project：真发生过就是无限翻页 + 累加。
        var stalled = try #require(
            try JSONSerialization.jsonObject(with: page) as? [String: Any]
        )
        stalled["pagination"] = ["cursor": "stuck"]
        let body = LiveProviderHarness.json(stalled)
        let client = LiveProviderHarness.stub([
            (
                NeonBillingProvider.organizationsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("neon-organizations"))
            ),
            (NeonBillingProvider.consumptionURL(orgID: org, cursor: nil, window: window), body),
            (NeonBillingProvider.consumptionURL(orgID: org, cursor: "stuck", window: window), body),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.currentSpendUSD!.roundedToCents() == Money(roundedUSD: 0.54))
        // organizations 一次 + consumption 两页（第二页游标原地打转后停）。
        #expect(client.urls.count <= 3)
    }

    @Test("认不出套餐不按 Launch 猜钱")
    func unknownPlanRefusesToPrice() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let client = LiveProviderHarness.stub([
            (
                NeonBillingProvider.organizationsURL,
                LiveProviderHarness.json(["organizations": [["id": org, "plan": "mystery-tier"]]])
            ),
            (
                NeonBillingProvider.consumptionURL(orgID: org, cursor: nil, window: window),
                LiveProviderHarness.body(LiveProviderHarness.fixture("neon-consumption-history"))
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("钉死的 org 不在组织列表里就失败，不用空计划硬算")
    func pinnedOrgMissingFromListFails() async {
        let client = LiveProviderHarness.stub([
            (
                NeonBillingProvider.organizationsURL,
                LiveProviderHarness.json(["organizations": [["id": "some-other-org", "plan": "scale"]]])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(stubConsumption(Data("{}".utf8), status: status)).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .neon, fields: [.apiKey: secret, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> NeonBillingProvider {
        NeonBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }

    private func stubConsumption(_ data: Data, status: Int = 200) -> RecordingHTTPClient {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        // 钉死 org 也会先拉 organizations 拿计划名，桩里必须有这条。
        return LiveProviderHarness.stub([
            (
                NeonBillingProvider.organizationsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("neon-organizations"))
            ),
            (
                NeonBillingProvider.consumptionURL(orgID: org, cursor: nil, window: window),
                LiveProviderHarness.body(data, status: status)
            ),
        ])
    }
}
