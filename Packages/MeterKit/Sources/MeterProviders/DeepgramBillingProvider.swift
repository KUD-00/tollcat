import Foundation
import MeterCore

/// Deepgram 本月用量美元（优先于预充值余额）。
///
/// 文档：`GET /v1/projects/{project_id}/billing/breakdown`
/// 认证：`Authorization: Token <API key>`
///
/// `results[].dollars` 是区间内已计费美元。没填 Project ID 时用 key 能看到的第一个项目。
public struct DeepgramBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.deepgram }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .deepgram)
        let headers = [
            "Authorization": "Token \(key)",
        ]
        let projectID: String
        if let pinned = credential.value(for: .projectID)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !pinned.isEmpty {
            projectID = pinned
        } else {
            projectID = try await loadFirstProjectID(headers: headers)
        }
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let data = try await ProviderHTTP.get(
                url: Self.breakdownURL(projectID: projectID, window: month),
                headers: headers,
                client: httpClient,
                providerID: .deepgram
            )
            let payload = try ProviderHTTP.decode(Breakdown.self, from: data, providerID: .deepgram)
            let total = (payload.results ?? []).reduce(Decimal(0)) { $0 + ($1.dollars?.value ?? 0) }
            if month.start == current.start {
                currentTotal = total
                for row in payload.results ?? [] {
                    let amount = row.dollars?.value ?? 0
                    guard amount != 0 else { continue }
                    let day = row.start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? month.start
                    daily.add(day: calendar.startOfDay(for: day), amount: Money(usd: amount))
                }
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: total),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return Snapshot(
            providerID: .deepgram,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        )
    }

    private func loadFirstProjectID(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.projectsURL,
            headers: headers,
            client: httpClient,
            providerID: .deepgram
        )
        let payload = try ProviderHTTP.decode(ProjectList.self, from: data, providerID: .deepgram)
        guard let id = payload.projects?.first?.project_id, !id.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .deepgram)
        }
        return id
    }

    static let projectsURL = URL(string: "https://api.deepgram.com/v1/projects")!

    static func breakdownURL(projectID: String, window: CalendarMonthWindow) -> URL {
        ProviderURL.https(
            host: "api.deepgram.com",
            path: "/v1/projects/\(projectID)/billing/breakdown",
            query: [
                URLQueryItem(name: "start", value: window.rfc3339(window.start)),
                URLQueryItem(name: "end", value: window.rfc3339(window.nextStart)),
            ]
        )
    }

    struct ProjectList: Decodable, Sendable {
        var projects: [Project]?
    }

    struct Project: Decodable, Sendable {
        var project_id: String?
    }

    struct Breakdown: Decodable, Sendable {
        var results: [Row]?
    }

    struct Row: Decodable, Sendable {
        var dollars: FlexibleDecimal?
        var start: String?
        var end: String?
    }
}
