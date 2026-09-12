import Foundation
import MeterCore

/// Redis Cloud FOCUS 成本报告（`POST /cost-report` → `GET /tasks/{id}` → `GET /cost-report/{id}`）。
///
/// 文档：https://redis.io/docs/latest/operate/rc/api/examples/generate-cost-report/
/// 认证：`x-api-key`（Account key）+ `x-api-secret-key`（User key）。
/// Host：`api.redislabs.com`。
/// 金额：FOCUS 行 `BilledCost` / `EffectiveCost` + `BillingCurrency`；按 `BillingPeriodStart` / `ChargePeriodStart` 归月。
public struct RedisCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.rediscloud }
    public static let apiHost = "api.redislabs.com"
    static let maxPollAttempts = 20
    static let pollNanos: UInt64 = 200_000_000

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates
    public var sleepNanoseconds: @Sendable (UInt64) async -> Void

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates,
        sleepNanoseconds: @escaping @Sendable (UInt64) async -> Void = { ns in
            try? await Task.sleep(nanoseconds: ns)
        }
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
        self.sleepNanoseconds = sleepNanoseconds
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let accountKey: String
        if let primary = try? RequiredCredential.value(.accessKeyID, in: credential, providerID: .rediscloud) {
            accountKey = primary
        } else if let primary = try? RequiredCredential.value(.accountID, in: credential, providerID: .rediscloud) {
            accountKey = primary
        } else {
            accountKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .rediscloud)
        }
        let userKey: String
        if let primary = try? RequiredCredential.value(.secretAccessKey, in: credential, providerID: .rediscloud) {
            userKey = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .rediscloud) {
            userKey = primary
        } else {
            userKey = try RequiredCredential.value(.clientSecret, in: credential, providerID: .rediscloud)
        }
        let headers = [
            "x-api-key": accountKey,
            "x-api-secret-key": userKey,
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let periods: [CalendarMonthWindow] = {
            if horizon == .availableHistory {
                var list: [CalendarMonthWindow] = [current]
                var cursor = current.start
                // Redis cost-report max 40 days per request — one month windows.
                for _ in 0..<2 {
                    guard let prev = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
                    cursor = prev
                    list.append(CalendarMonthWindow.current(now: cursor, calendar: calendar))
                }
                return list
            }
            return [current]
        }()

        for window in periods {
            let rows = try await loadCostRows(window: window, headers: headers)
            for row in rows {
                let amount = row.BilledCost?.value ?? row.EffectiveCost?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(row.BillingCurrency ?? row.PricingCurrency, providerID: .rediscloud)
                let stamp = row.ChargePeriodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? row.BillingPeriodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                let label = row.ResourceName ?? row.ChargeDescription ?? row.SkuId ?? "usage"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: row.ServiceName ?? "usage",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else if horizon == .availableHistory {
                    daily.addPastMonth(
                        start: stamp,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .rediscloud
        )
        return Snapshot(
            providerID: .rediscloud,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadCostRows(
        window: CalendarMonthWindow,
        headers: [String: String]
    ) async throws -> [CostRow] {
        let body = try JSONSerialization.data(withJSONObject: [
            "startDate": Self.isoDay(window.start, calendar: calendar),
            "endDate": Self.isoDay(window.endInclusive, calendar: calendar),
            "format": "json",
        ])
        let createData = try await ProviderHTTP.post(
            url: Self.costReportURL,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .rediscloud
        )
        let task = try ProviderHTTP.decode(TaskEnvelope.self, from: createData, providerID: .rediscloud)
        guard let taskID = task.taskId, !taskID.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .rediscloud)
        }
        let costReportID = try await waitForReport(taskID: taskID, headers: headers)
        let reportData = try await ProviderHTTP.get(
            url: Self.costReportDownloadURL(id: costReportID),
            headers: headers,
            client: httpClient,
            providerID: .rediscloud
        )
        if let list = try? ProviderHTTP.decode([CostRow].self, from: reportData, providerID: .rediscloud) {
            return list
        }
        if let envelope = try? ProviderHTTP.decode(CostEnvelope.self, from: reportData, providerID: .rediscloud) {
            return envelope.records ?? envelope.data ?? envelope.costReport ?? []
        }
        // JSONL
        return try decodeJSONL(reportData)
    }

    private func waitForReport(taskID: String, headers: [String: String]) async throws -> String {
        for _ in 0..<Self.maxPollAttempts {
            let data = try await ProviderHTTP.get(
                url: Self.taskURL(id: taskID),
                headers: headers,
                client: httpClient,
                providerID: .rediscloud
            )
            let task = try ProviderHTTP.decode(TaskEnvelope.self, from: data, providerID: .rediscloud)
            let status = (task.status ?? "").lowercased()
            if status == "processing-completed" || status == "completed" {
                if let id = task.response?.resource?.costReportId ?? task.response?.costReportId {
                    return id
                }
            }
            if status.contains("fail") || status.contains("error") {
                throw ProviderError.malformedResponse(providerID: .rediscloud)
            }
            await sleepNanoseconds(Self.pollNanos)
        }
        throw ProviderError.malformedResponse(providerID: .rediscloud)
    }

    private func decodeJSONL(_ data: Data) throws -> [CostRow] {
        let text = String(data: data, encoding: .utf8) ?? ""
        var rows: [CostRow] = []
        let decoder = JSONDecoder()
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("{") else { continue }
            guard let lineData = trimmed.data(using: .utf8) else { continue }
            if let row = try? decoder.decode(CostRow.self, from: lineData) {
                rows.append(row)
            }
        }
        return rows
    }

    static let costReportURL = ProviderURL.https(host: apiHost, path: "/v1/cost-report")

    static func taskURL(id: String) -> URL {
        ProviderURL.https(host: apiHost, path: "/v1/tasks/\(id)")
    }

    static func costReportDownloadURL(id: String) -> URL {
        ProviderURL.https(host: apiHost, path: "/v1/cost-report/\(id)")
    }

    private static func isoDay(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    struct TaskEnvelope: Decodable, Sendable {
        var taskId: String?
        var status: String?
        var response: TaskResponse?
    }

    struct TaskResponse: Decodable, Sendable {
        var resource: TaskResource?
        var costReportId: String?
    }

    struct TaskResource: Decodable, Sendable {
        var costReportId: String?
    }

    struct CostEnvelope: Decodable, Sendable {
        var records: [CostRow]?
        var data: [CostRow]?
        var costReport: [CostRow]?
    }

    struct CostRow: Decodable, Sendable {
        var BilledCost: FlexibleDecimal?
        var EffectiveCost: FlexibleDecimal?
        var BillingCurrency: String?
        var PricingCurrency: String?
        var BillingPeriodStart: String?
        var ChargePeriodStart: String?
        var ResourceName: String?
        var ChargeDescription: String?
        var ServiceName: String?
        var SkuId: String?
    }
}
