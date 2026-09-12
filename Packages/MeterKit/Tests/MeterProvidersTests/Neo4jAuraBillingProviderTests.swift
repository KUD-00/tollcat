import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct Neo4jAuraBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let clientID = "neo4j-client-MUST-NOT-LEAK"
    private let clientSecret = "neo4j-secret-MUST-NOT-LEAK"
    private let orgID = "aa6e77da-64b1-4da4-b34a-f920aad9739d"

    @Test("先换 token，没填组织就自己列，再读本月用量")
    func discoversOrgThenReadsUsage() async throws {
        let client = discoveryStub(usage: currentUsageJSON)
        let snapshot = try await provider(client).fetch(credential: unpinnedCredential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "7.62")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 9)] == Money(usd: Decimal(string: "7.62")!))
        #expect(client.urls.contains(Neo4jAuraBillingProvider.organizationsURL))
        #expect(client.leakedSecrets([clientSecret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("填了组织就不再列")
    func pinnedOrgSkipsDiscovery() async throws {
        let client = pinnedStub(usage: currentUsageJSON)
        _ = try await provider(client).fetch(credential: pinnedCredential)
        #expect(!client.urls.contains(Neo4jAuraBillingProvider.organizationsURL))
        #expect(client.urls.contains(currentUsageURL))
    }

    @Test("换 token 走 Basic，业务请求走 Bearer")
    func authHeadersAreCorrect() async throws {
        let client = pinnedStub(usage: currentUsageJSON)
        _ = try await provider(client).fetch(credential: pinnedCredential)
        let token = try #require(client.requests.first)
        #expect(token.httpMethod == "POST")
        #expect(
            token.value(forHTTPHeaderField: "Authorization")
                == "Basic \(ProviderOAuth.basicValue(id: clientID, secret: clientSecret))"
        )
        #expect(String(data: token.httpBody ?? Data(), encoding: .utf8) == "grant_type=client_credentials")
        let usage = try #require(client.requests.last)
        #expect(usage.value(forHTTPHeaderField: "Authorization") == "Bearer fixture-neo4j-access-token")
        #expect(client.leakedSecrets([clientSecret]).isEmpty)
    }

    @Test("end 钳到现在之前，不是下月 1 号")
    func usageEndIsBeforeNow() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let end = Neo4jAuraBillingProvider.usageEnd(window: window, now: now)
        #expect(end < now)
        #expect(end <= window.nextStart)
        #expect(currentUsageURL.absoluteString.contains("end=2026-08-16T11:59:59Z"))
        #expect(!currentUsageURL.absoluteString.contains("2026-09-01"))
    }

    @Test("历史是一个窗口一次请求，不按月拆")
    func historyIsOneUsageRequest() async throws {
        let client = pinnedStub(usage: historyUsageJSON, url: historyUsageURL)
        _ = try await provider(client).fetch(
            credential: pinnedCredential,
            horizon: .availableHistory
        )
        let usageCalls = client.urls.filter { $0.path.contains("/billing/usage") }
        #expect(usageCalls.count == 1)
        #expect(usageCalls.first == historyUsageURL)
    }

    @Test("历史窗口把上个月的行落到月初")
    func historyRowsLandOnPastMonthStart() async throws {
        let client = pinnedStub(usage: historyUsageJSON, url: historyUsageURL)
        let snapshot = try await provider(client).fetch(
            credential: pinnedCredential,
            horizon: .availableHistory
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "7.62")!))
        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 7, 1)] == Money(usd: 4))
        #expect(daily[LiveProviderHarness.date(2026, 8, 9)] == Money(usd: Decimal(string: "7.62")!))
    }

    @Test("创建页直达 Client credentials，按天限流")
    func setupURLAndDailyQuota() {
        let descriptor = ProviderCatalog.neo4j
        #expect(
            descriptor.credentialSetupURL?.absoluteString
                == "https://console.neo4j.io/account/client-credentials"
        )
        #expect(descriptor.credentialSetupURL != descriptor.billingURL)
        #expect(descriptor.minimumRefreshInterval == 86400)
    }

    @Test("401 / 403 / 429")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (Neo4jAuraBillingProvider.tokenURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: pinnedCredential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (Neo4jAuraBillingProvider.tokenURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: pinnedCredential)
        }
        await LiveProviderHarness.expectStatus(429, code: .rateLimited, key: .rateLimited) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (Neo4jAuraBillingProvider.tokenURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: pinnedCredential)
        }
    }

    private var currentUsageURL: URL {
        Neo4jAuraBillingProvider.usageURL(
            orgID: orgID,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            now: now,
            pageToken: "",
            projectID: nil
        )
    }

    private var historyUsageURL: URL {
        Neo4jAuraBillingProvider.usageURL(
            orgID: orgID,
            window: CalendarMonthWindow.spanning(
                for: .availableHistory,
                lookbackMonths: ProviderCatalog.neo4j.historyLookbackMonths,
                now: now,
                calendar: calendar
            ),
            now: now,
            pageToken: "",
            projectID: nil
        )
    }

    private var currentUsageJSON: [String: Any] {
        [
            "data": [
                [
                    "list_cost": "7.62",
                    "pricing_currency": "credits",
                    "charge_period_start": "2026-08-09T00:00:00Z",
                    "resource_name": "AuraDB Professional",
                    "resource_type": "instance",
                    "base_sku": "professional.gcp.primary_db.1gb",
                ],
            ],
            "links": ["next": ""],
        ]
    }

    private var historyUsageJSON: [String: Any] {
        [
            "data": [
                [
                    "list_cost": 4,
                    "charge_period_start": "2026-07-15T00:00:00Z",
                    "resource_name": "July",
                    "resource_type": "instance",
                ],
                [
                    "list_cost": "7.62",
                    "charge_period_start": "2026-08-09T00:00:00Z",
                    "resource_name": "August",
                    "resource_type": "instance",
                ],
            ],
            "links": ["next": ""],
        ]
    }

    private var pinnedCredential: Credential {
        Credential(
            providerID: .neo4j,
            fields: [.clientID: clientID, .clientSecret: clientSecret, .accountID: orgID]
        )
    }

    private var unpinnedCredential: Credential {
        Credential(
            providerID: .neo4j,
            fields: [.clientID: clientID, .clientSecret: clientSecret]
        )
    }

    private func provider(_ client: RecordingHTTPClient) -> Neo4jAuraBillingProvider {
        Neo4jAuraBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }

    private func tokenResponse() -> StubHTTPResponse {
        LiveProviderHarness.json([
            "access_token": "fixture-neo4j-access-token",
            "expires_in": 3600,
            "token_type": "bearer",
        ])
    }

    private func pinnedStub(usage: [String: Any], url: URL? = nil) -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (Neo4jAuraBillingProvider.tokenURL, tokenResponse()),
            (url ?? currentUsageURL, LiveProviderHarness.json(usage)),
        ])
    }

    private func discoveryStub(usage: [String: Any]) -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (Neo4jAuraBillingProvider.tokenURL, tokenResponse()),
            (
                Neo4jAuraBillingProvider.organizationsURL,
                LiveProviderHarness.json([
                    "data": [["id": orgID, "name": "Personal"]],
                ])
            ),
            (currentUsageURL, LiveProviderHarness.json(usage)),
        ])
    }
}
