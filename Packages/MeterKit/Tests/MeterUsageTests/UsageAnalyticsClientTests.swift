import Foundation
import Testing
@testable import MeterUsage

struct UsageAnalyticsClientTests {
    @Test("连续停在同一页不计第二次，换页才加")
    func consecutiveSameScreenIsDeduped() async {
        let submitter = StubUsageSubmitter()
        let marker = InMemoryVisitMarker(lastDay: "1970-01-01")
        let client = UsageAnalyticsClient(
            submitter: submitter,
            visitMarker: marker,
            appVersion: "0.1.0 (1)",
            now: { Date(timeIntervalSince1970: 0) },
            debounceNanoseconds: 60_000_000_000
        )

        client.record(.dashboard)
        client.record(.dashboard)
        client.record(.services)
        client.record(.services)
        client.flush()
        try? await Task.sleep(nanoseconds: 80_000_000)

        #expect(submitter.received.count == 1)
        let screens = Dictionary(
            uniqueKeysWithValues: submitter.received[0].screens.map { ($0.id, $0.n) }
        )
        #expect(screens["dashboard"] == 1)
        #expect(screens["services"] == 1)
        #expect(submitter.received[0].newVisit == false)
    }

    @Test("UTC 日第一次打开才带 newVisit，成功后不再带")
    func newVisitOnlyOncePerUTCDay() async {
        let submitter = StubUsageSubmitter()
        let marker = InMemoryVisitMarker()
        let client = UsageAnalyticsClient(
            submitter: submitter,
            visitMarker: marker,
            appVersion: "0.1.0 (1)",
            now: { Date(timeIntervalSince1970: 0) },
            debounceNanoseconds: 60_000_000_000
        )

        client.record(.dashboard)
        client.flush()
        try? await Task.sleep(nanoseconds: 80_000_000)
        #expect(submitter.received.count == 1)
        #expect(submitter.received[0].newVisit == true)

        client.record(.settings)
        client.flush()
        try? await Task.sleep(nanoseconds: 80_000_000)
        #expect(submitter.received.count == 2)
        #expect(submitter.received[1].newVisit == false)
        #expect(submitter.received[1].screens.map(\.id) == ["settings"])
    }

    @Test("发送失败时 newVisit 不落盘，下次还能再报")
    func failedSubmitDoesNotConsumeVisit() async {
        let submitter = StubUsageSubmitter()
        submitter.setShouldFail(true)
        let marker = InMemoryVisitMarker()
        let client = UsageAnalyticsClient(
            submitter: submitter,
            visitMarker: marker,
            appVersion: "0.1.0 (1)",
            now: { Date(timeIntervalSince1970: 0) },
            debounceNanoseconds: 60_000_000_000
        )

        client.record(.dashboard)
        client.flush()
        try? await Task.sleep(nanoseconds: 80_000_000)
        #expect(submitter.received.isEmpty)

        submitter.setShouldFail(false)
        client.record(.services)
        client.flush()
        try? await Task.sleep(nanoseconds: 80_000_000)
        #expect(submitter.received.count == 1)
        #expect(submitter.received[0].newVisit == true)
    }

    @Test("离开设备的字段就这些")
    func payloadCarriesNothingElse() throws {
        let payload = UsageAnalyticsPayload(
            platform: "ios",
            appVersion: "0.1.0 (1)",
            newVisit: true,
            screens: [.init(id: "dashboard", n: 2)]
        )
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(Set(json.keys) == ["platform", "appVersion", "newVisit", "screens"])
        let keys = json.keys.map { $0.lowercased() }
        for banned in ["amount", "usd", "spend", "balance", "cost", "key", "token", "credential"] {
            #expect(!keys.contains { $0.contains(banned) }, "payload 里出现了 \(banned)")
        }
    }

    @Test("UTC 日字符串按公历零时区切")
    func utcDayIsCalendarDate() {
        // 1970-01-01 00:00 UTC
        #expect(UsageUTCDay.string(from: Date(timeIntervalSince1970: 0)) == "1970-01-01")
        // 1970-01-02 00:00 UTC
        #expect(UsageUTCDay.string(from: Date(timeIntervalSince1970: 86_400)) == "1970-01-02")
    }
}
