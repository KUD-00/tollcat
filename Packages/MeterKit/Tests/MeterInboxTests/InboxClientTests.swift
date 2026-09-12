import Foundation
import Testing
import MeterCore
@testable import MeterInbox

struct InboxClientTests {
    private let calendar = InboxHarness.calendar
    private let readKey = "tollr_READ-MUST-NOT-LEAK"

    @Test("建信箱把两把 key 都收下，投递 key 只在这一次出现")
    func createInboxReturnsBothKeys() async throws {
        let transport = InboxHarness.stub([
            (InboxEndpoint.inboxURL, InboxHarness.json([
                "mailbox": "mb_123",
                "readKey": readKey,
                "ingestKey": "tolli_WRITE",
                "ingestKeyID": "key_1",
            ], status: 201)),
        ])
        let provisioning = try await InboxClient(transport: transport).createInbox()
        #expect(provisioning.credentials.mailbox == "mb_123")
        #expect(provisioning.credentials.readKey == readKey)
        #expect(provisioning.ingestKey.secret == "tolli_WRITE")
        #expect(provisioning.ingestKey.id == "key_1")
        // 建信箱这一步不带任何 token。
        #expect(transport.requests.first?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("取读数用读 key，金额按十进制字符串解，不过 Double")
    func fetchReadingsParsesDecimalStrings() async throws {
        let transport = InboxHarness.stub([
            (InboxEndpoint.readingsURL, InboxHarness.json([
                "readings": [
                    [
                        "provider": "render",
                        "ingestKeyID": "key_render",
                        "periodStart": "2026-08-01",
                        "currentSpendUSD": "12.34",
                        "reportedAt": "2026-08-17T02:00:00Z",
                    ],
                    [
                        "provider": "expo",
                        "ingestKeyID": "key_expo",
                        "periodStart": "2026-08-01",
                        "currentSpendUSD": "0.10",
                        "reportedAt": "2026-08-17T02:00:05Z",
                    ],
                ],
            ])),
        ])
        let readings = try await InboxClient(transport: transport)
            .fetchReadings(readKey: readKey, calendar: calendar)

        #expect(readings.count == 2)
        #expect(readings[0].providerID == .render)
        #expect(readings[0].currentSpendUSD == Money(usd: Decimal(string: "12.34")!))
        #expect(readings[0].periodStart == InboxHarness.date(2026, 8, 1))
        #expect(readings[1].currentSpendUSD == Money(usd: Decimal(string: "0.10")!))

        let request = try #require(transport.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(readKey)")
        #expect(request.url?.absoluteString.contains(readKey) == false)
    }

    @Test("坏行只丢它自己，不废掉整次取回")
    func skipsUnparsableRowsOnly() async throws {
        let transport = InboxHarness.stub([
            (InboxEndpoint.readingsURL, InboxHarness.json([
                "readings": [
                    ["provider": "", "ingestKeyID": "key_a", "periodStart": "2026-08-01", "currentSpendUSD": "1.00"],
                    ["provider": "render", "ingestKeyID": "key_b", "periodStart": "不是日期", "currentSpendUSD": "1.00"],
                    ["provider": "render", "periodStart": "2026-08-01", "currentSpendUSD": "1.00"],
                    ["provider": "expo", "ingestKeyID": "key_c", "periodStart": "2026-08-01", "currentSpendUSD": "3.00"],
                ],
            ])),
        ])
        let readings = try await InboxClient(transport: transport)
            .fetchReadings(readKey: readKey, calendar: calendar)
        #expect(readings.map(\.providerID) == [.expo])
    }

    @Test("金额缺失时读数仍然成立，只是没有数——不当成 0")
    func missingAmountIsNotZero() {
        let reading = InboxClient.reading(
            from: InboxReadingPayload(
                ingestKeyID: "key_render",
                provider: "render",
                periodStart: "2026-08-01",
                currentSpendUSD: nil,
                reportedAt: nil
            ),
            calendar: calendar
        )
        #expect(reading?.currentSpendUSD == nil)
        // 没有 reportedAt 就退回周期起点，不留一个 1970。
        #expect(reading?.reportedAt == InboxHarness.date(2026, 8, 1))
    }

    @Test("401 / 403 映射成 unauthorized，让界面能说「信箱失效了，重建一个」")
    func mapsAuthFailures() async {
        for status in [401, 403] {
            let transport = InboxHarness.stub([
                (InboxEndpoint.readingsURL, InboxHarness.json(["error": "nope"], status: status)),
            ])
            await #expect(throws: InboxError(code: .unauthorized, httpStatus: status)) {
                _ = try await InboxClient(transport: transport)
                    .fetchReadings(readKey: readKey, calendar: calendar)
            }
        }
    }

    @Test("签新 key 用读 key 授权，label 进请求体")
    func mintUsesReadKeyAndCarriesLabel() async throws {
        let transport = InboxHarness.stub([
            (
                InboxEndpoint.ingestKeysURL,
                InboxHarness.json(["ingestKey": "tolli_NEW", "ingestKeyID": "key_2"], status: 201)
            ),
        ])
        let key = try await InboxClient(transport: transport)
            .mintIngestKey(readKey: readKey, label: "Render 抓取")
        #expect(key.secret == "tolli_NEW")
        #expect(key.id == "key_2")

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(readKey)")
        let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("Render"))
    }

    @Test("签新 key 不吊销旧的——轮换要能平滑过渡")
    func mintDoesNotRevokeOldKeys() async throws {
        let transport = InboxHarness.stub([
            (
                InboxEndpoint.ingestKeysURL,
                InboxHarness.json(["ingestKey": "tolli_NEW", "ingestKeyID": "key_2"], status: 201)
            ),
        ])
        _ = try await InboxClient(transport: transport)
            .mintIngestKey(readKey: readKey, label: nil)
        // 只有一次 POST，没有顺带的 DELETE。
        #expect(transport.requests.count == 1)
        #expect(transport.requests.allSatisfy { $0.httpMethod != "DELETE" })
    }

    @Test("列出投递 key 只回元数据，永远没有 key 本身")
    func listReturnsMetadataOnly() async throws {
        let transport = InboxHarness.stub([
            (InboxEndpoint.ingestKeysURL, InboxHarness.json(["keys": [
                [
                    "id": "key_1", "label": "Render 抓取",
                    "createdAt": "2026-08-01T00:00:00Z",
                    "lastUsedAt": "2026-08-17T02:00:00Z",
                ],
                ["id": "key_2", "label": NSNull(), "createdAt": "2026-08-10T00:00:00Z"],
            ]])),
        ])
        let keys = try await InboxClient(transport: transport).listIngestKeys(readKey: readKey)
        #expect(keys.map(\.id) == ["key_1", "key_2"])
        #expect(keys[0].label == "Render 抓取")
        #expect(keys[0].lastUsedAt != nil)
        #expect(keys[1].lastUsedAt == nil)
    }

    @Test("吊销打到带 id 的那条路径")
    func revokeTargetsSpecificKey() async throws {
        let transport = InboxHarness.stub([
            (InboxEndpoint.ingestKeyURL(id: "key_1"), InboxHarness.json(["ok": true])),
        ])
        try await InboxClient(transport: transport)
            .revokeIngestKey(readKey: readKey, id: "key_1")
        #expect(transport.requests.first?.httpMethod == "DELETE")
        #expect(transport.requests.first?.url?.absoluteString.hasSuffix("/key_1") == true)
    }

    @Test("客户端没有投递方法：App 只取回，不投递")
    func clientCannotPostReadings() async throws {
        let transport = InboxHarness.stub([
            (InboxEndpoint.readingsURL, InboxHarness.json(["readings": []])),
        ])
        _ = try await InboxClient(transport: transport)
            .fetchReadings(readKey: readKey, calendar: calendar)
        #expect(transport.requests.allSatisfy { $0.httpMethod != "POST" })
    }
}
