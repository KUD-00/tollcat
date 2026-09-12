import Foundation
@testable import MeterInbox

enum InboxHarness {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }

    static func stub(_ pairs: [(URL, StubbedResponse)]) -> RecordingInboxTransport {
        RecordingInboxTransport(responses: Dictionary(uniqueKeysWithValues: pairs))
    }

    static func json(_ object: Any, status: Int = 200) -> StubbedResponse {
        StubbedResponse(
            status: status,
            body: try! JSONSerialization.data(withJSONObject: object)
        )
    }
}

struct StubbedResponse: Sendable {
    var status: Int
    var body: Data
}

final class RecordingInboxTransport: InboxTransport, @unchecked Sendable {
    private let responses: [URL: StubbedResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [URL: StubbedResponse]) {
        self.responses = responses
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard let url = request.url, let stub = responses[url] else {
            throw InboxError(code: .unreachable)
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (stub.body, response)
    }
}
