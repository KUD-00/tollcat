import Foundation
import Testing
import MeterCore
@testable import MeterProviders

enum LiveProviderHarness {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static var now: Date {
        date(2026, 8, 16, 12)
    }

    /// 测筛选/合计、不测折算时用 1:1，避免空表直接抛 unsupportedCurrency。
    static var passthroughRates: SharedExchangeRates {
        SharedExchangeRates(
            ExchangeRates(usdPerUnit: [
                "EUR": 1, "NOK": 1, "KWD": 1, "CNY": 1, "GBP": 1, "DKK": 1, "SEK": 1,
            ])
        )
    }

    /// 和打包目录同一张汇率。适配器测非美元时用这个，不要空表。
    static var catalogRates: SharedExchangeRates {
        SharedExchangeRates(
            ExchangeRates(usdPerUnit: [
                "CNY": Decimal(string: "0.1404")!,
                "EUR": Decimal(string: "1.0850")!,
                "GBP": Decimal(string: "1.2720")!,
                "JPY": Decimal(string: "0.00655")!,
                "AUD": Decimal(string: "0.6580")!,
                "CAD": Decimal(string: "0.7310")!,
                "SGD": Decimal(string: "0.7480")!,
                "INR": Decimal(string: "0.01185")!,
                "BRL": Decimal(string: "0.1780")!,
                "KRW": Decimal(string: "0.000724")!,
                "TWD": Decimal(string: "0.03105")!,
                "HKD": Decimal(string: "0.1282")!,
            ])
        )
    }

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        _ second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }

    /// 状态码 → ProviderError 三连断言。各家只负责「怎么造这个状态码的响应」。
    static func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey,
        fetch: (Int) async throws -> Snapshot
    ) async {
        let error = await #expect(throws: ProviderError.self) {
            _ = try await fetch(status)
        }
        #expect(error?.httpStatus == status)
        #expect(error?.code == code)
        #expect(error?.remediationKey == key)
    }

    /// 这次取数打过的每个 host 都必须在出站清单里。失败信息带上具体 URL。
    static func expectHostsDeclared(_ client: RecordingHTTPClient) {
        for url in client.urls where !OutboundHosts.contains(url) {
            Issue.record("undeclared outbound host: \(url.absoluteString)")
        }
    }

    static func fixture(_ name: String, ext: String = "json") -> Data {
        OfficialAPIFixture.data(named: name, extension: ext)!
    }

    static func stub(_ pairs: [(URL, StubHTTPResponse)]) -> RecordingHTTPClient {
        RecordingHTTPClient(responses: Dictionary(uniqueKeysWithValues: pairs))
    }

    static func json(
        _ object: Any,
        status: Int = 200,
        headers: [String: String] = [:]
    ) -> StubHTTPResponse {
        let data = try! JSONSerialization.data(withJSONObject: object)
        return body(data, status: status, headers: headers)
    }

    static func body(
        _ data: Data,
        status: Int = 200,
        headers: [String: String] = [:]
    ) -> StubHTTPResponse {
        var fields = ["Content-Type": "application/json"]
        for (key, value) in headers {
            fields[key] = value
        }
        return StubHTTPResponse(statusCode: status, body: data, headerFields: fields)
    }

    static func emptyJSON(status: Int) -> StubHTTPResponse {
        StubHTTPResponse(statusCode: status, body: Data("{}".utf8))
    }
}

final class RecordingHTTPClient: HTTPClient, @unchecked Sendable {
    private let stub: StubHTTPClient
    private(set) var requests: [URLRequest] = []

    init(responses: [URL: StubHTTPResponse]) {
        stub = StubHTTPClient(responses: responses)
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        return try await stub.send(request)
    }

    var urls: [URL] {
        requests.compactMap(\.url)
    }

    func leakedSecrets(_ secrets: [String]) -> [String] {
        var leaked: [String] = []
        for request in requests {
            let url = request.url?.absoluteString ?? ""
            for secret in secrets where url.contains(secret) && !leaked.contains(secret) {
                leaked.append(secret)
            }
        }
        return leaked
    }
}
