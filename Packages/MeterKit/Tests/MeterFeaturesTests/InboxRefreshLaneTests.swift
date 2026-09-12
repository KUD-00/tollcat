import Foundation
import Testing
import MeterCore
import MeterInbox
import MeterPersistence
@testable import MeterFeatures

struct InboxRefreshLaneTests {
    private let calendar = InboxLaneHarness.calendar

    @Test("一次请求喂所有信箱账号，不是一家一个请求")
    func oneRequestFeedsEveryProvider() async {
        let transport = InboxLaneHarness.transport(readings: [
            ("render", "key_render", "12.34"),
            ("expo", "key_expo", "3.00"),
            ("clerk", "key_clerk", "25.00"),
        ])
        let outcomes = await InboxRefreshLane.run(
            targets: [
                InboxLaneHarness.target(.render, key: "key_render"),
                InboxLaneHarness.target(.expo, key: "key_expo"),
                InboxLaneHarness.target(.clerk, key: "key_clerk"),
            ],
            client: InboxClient(transport: transport),
            credentials: InboxLaneHarness.storeWithMailbox(),
            calendar: calendar
        )
        #expect(transport.requestCount == 1)
        #expect(outcomes.count == 3)
        let allSucceeded = outcomes.allSatisfy { $0.isSuccess }
        #expect(allSucceeded)
    }

    @Test("折出来的快照带 .inbox 来源，并盖上账号")
    func snapshotsAreMarkedAsInbox() async throws {
        let target = InboxLaneHarness.target(.render, key: "key_render")
        let outcomes = await InboxRefreshLane.run(
            targets: [target],
            client: InboxClient(transport: InboxLaneHarness.transport(readings: [
                ("render", "key_render", "12.34"),
            ])),
            credentials: InboxLaneHarness.storeWithMailbox(),
            calendar: calendar
        )
        let snapshot = try #require(outcomes.first?.snapshot)
        #expect(snapshot.source == .inbox)
        #expect(snapshot.accountID == target.accountID)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.34")!))
    }

    @Test("没有信箱账号时一个请求都不发")
    func noProvidersMeansNoRequest() async {
        let transport = InboxLaneHarness.transport(readings: [])
        let outcomes = await InboxRefreshLane.run(
            targets: [],
            client: InboxClient(transport: transport),
            credentials: InboxLaneHarness.storeWithMailbox(),
            calendar: calendar
        )
        #expect(transport.requestCount == 0)
        #expect(outcomes.isEmpty)
    }

    @Test("没有信箱凭据时不发请求，全部记失败——不是 $0")
    func missingMailboxFailsWithoutRequest() async {
        let transport = InboxLaneHarness.transport(readings: [])
        let outcomes = await InboxRefreshLane.run(
            targets: [InboxLaneHarness.target(.render, key: "key_render")],
            client: InboxClient(transport: transport),
            credentials: InMemoryCredentialStore(),
            calendar: calendar
        )
        #expect(transport.requestCount == 0)
        let flags = outcomes.map { $0.isSuccess }
        #expect(flags == [false])
    }

    @Test("Worker 挂了只影响信箱那几家，每家各记一次失败")
    func transportFailureIsContained() async {
        let outcomes = await InboxRefreshLane.run(
            targets: [
                InboxLaneHarness.target(.render, key: "key_render"),
                InboxLaneHarness.target(.expo, key: "key_expo"),
            ],
            client: InboxClient(transport: InboxLaneHarness.failingTransport()),
            credentials: InboxLaneHarness.storeWithMailbox(),
            calendar: calendar
        )
        #expect(outcomes.count == 2)
        let allFailed = outcomes.allSatisfy { !$0.isSuccess }
        #expect(allFailed)
    }

    @Test("某账号没有投递记录时跳过，不写一条 $0，也不把手填标成失败")
    func providerWithoutReadingIsNotZero() async {
        let render = InboxLaneHarness.target(.render, key: "key_render")
        let expo = InboxLaneHarness.target(.expo, key: "key_expo")
        let outcomes = await InboxRefreshLane.run(
            targets: [render, expo],
            client: InboxClient(transport: InboxLaneHarness.transport(readings: [
                ("render", "key_render", "5.00"),
            ])),
            credentials: InboxLaneHarness.storeWithMailbox(),
            calendar: calendar
        )
        let byID = Dictionary(uniqueKeysWithValues: outcomes.map { ($0.accountID, $0) })
        #expect(byID[render.accountID]?.isSuccess == true)
        #expect(byID[expo.accountID]?.isSkipped == true)
    }

    @Test("投递了没接入的服务，不会凭空冒出来")
    func unrequestedProviderIsIgnored() async {
        let render = InboxLaneHarness.target(.render, key: "key_render")
        let outcomes = await InboxRefreshLane.run(
            targets: [render],
            client: InboxClient(transport: InboxLaneHarness.transport(readings: [
                ("render", "key_render", "5.00"),
                ("qdrant", "key_other", "99.00"),
            ])),
            credentials: InboxLaneHarness.storeWithMailbox(),
            calendar: calendar
        )
        let ids = outcomes.map { $0.accountID }
        #expect(ids == [render.accountID])
    }

    @Test("投递 body 写错 provider 也不许串种：key 的归属是唯一事实源")
    func mismatchedProviderFieldCannotPolluteHistory() throws {
        let target = InboxLaneHarness.target(.render, key: "key_render")
        // 投递方把 provider 填成了别家，但 key 是 render 账号签出去的那把。
        let reading = InboxReading(
            providerID: ProviderID("expo"),
            ingestKeyID: "key_render",
            periodStart: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            currentSpendUSD: Money(usd: 5),
            reportedAt: now
        )
        let outcomes = InboxRefreshLane.distribute(
            targets: [target],
            readings: [reading],
            calendar: calendar
        )
        let snapshot = try #require(outcomes.first?.snapshot)
        #expect(snapshot.providerID == .render)
        #expect(snapshot.accountID == target.accountID)
        #expect(snapshot.currentSpendUSD == Money(usd: 5))
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
    }
}

enum InboxLaneHarness {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func target(_ provider: ProviderID, key: String) -> InboxRefreshTarget {
        InboxRefreshTarget(
            accountID: AccountID.fixture(for: provider),
            providerID: provider,
            ingestKeyID: key
        )
    }

    static func storeWithMailbox() -> any CredentialStore {
        let store = InMemoryCredentialStore()
        try? InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_test", readKey: "tollr_test"),
            to: store
        )
        return store
    }

    static func transport(readings: [(String, String, String)]) -> CountingInboxTransport {
        let rows = readings.map { provider, key, amount in
            [
                "provider": provider,
                "ingestKeyID": key,
                "periodStart": "2026-08-01",
                "currentSpendUSD": amount,
                "reportedAt": "2026-08-17T02:00:00Z",
            ]
        }
        let body = try! JSONSerialization.data(withJSONObject: ["readings": rows])
        return CountingInboxTransport(body: body, status: 200)
    }

    static func failingTransport() -> CountingInboxTransport {
        CountingInboxTransport(body: Data("{}".utf8), status: 503)
    }
}

final class CountingInboxTransport: InboxTransport, @unchecked Sendable {
    private let body: Data
    private let status: Int
    private(set) var requestCount = 0

    init(body: Data, status: Int) {
        self.body = body
        self.status = status
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requestCount += 1
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (body, response)
    }
}

private extension BillingRefreshOutcome {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isSkipped: Bool {
        if case .skipped = self { return true }
        return false
    }

    var snapshot: Snapshot? {
        if case .success(_, let snapshot) = self { return snapshot }
        return nil
    }

    var accountID: AccountID {
        switch self {
        case .success(let id, _): id
        case .failure(let id): id
        case .skipped(let id): id
        }
    }
}
