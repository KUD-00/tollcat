import Foundation
import MeterCore

/// Vercel FOCUS v1.3 billing charges。
///
/// 文档：`GET /v1/billing/charges`
/// 认证：`Authorization: Bearer <token>`
/// 日期：必填 `from` / `to`（ISO 8601 UTC，`to` 是开区间）。日粒度，最长一年。
/// 响应：JSONL，一行一条 charge。
///
/// Hobby 没有发票，这条接口回 404 `costs_not_found`。当成用量 $0，不是连接失败；
/// 别的 404（teamId 错、路径变了）照样报错，不能装成 $0。
/// 公开接口没有免费额度比例，不编 `freeQuotaUsedRatio`。
/// 没填 teamId 时用 `/v2/user.defaultTeamId`；Team 范围的 token 这份 user 往往是 limited。
public struct VercelBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.vercel }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    /// 厂商用非美元结算时按这张表换。默认只认美元，行为和加它之前一样。
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        var currency = CurrencyAccumulator()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .vercel)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/jsonl",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )

        var teamID = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if teamID?.isEmpty == true { teamID = nil }
        if teamID == nil {
            teamID = try await loadDefaultTeamID(headers: [
                "Authorization": "Bearer \(token)",
            ])
        }

        let url = Self.chargesURL(from: fetchWindow.start, to: fetchWindow.nextStart, teamID: teamID)
        // Hobby 没有 costs 对象。Pro 空账期是 200 空 JSONL，走下面那条。
        guard let data = try await loadCharges(url: url, headers: headers) else {
            return Self.zeroUsageSnapshot(now: now, window: current)
        }

        let rows: [Charge]
        do {
            rows = try JSONLDecoder.decode(Charge.self, from: data)
        } catch {
            throw ProviderError.malformedResponse(providerID: .vercel)
        }

        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        for row in rows {
            try currency.observe(row.BillingCurrency, providerID: .vercel)
            let amount = (row.BilledCost ?? row.EffectiveCost)?.money ?? .zero
            let day = row.ChargePeriodStart.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            daily.add(day: day, amount: amount)
            // 明细口径跟着 `currentSpendUSD` 走。历史窗口会带回更早的行，
            // 不挡就会把去年的服务挂到本月明细上。
            if current.contains(day), let line = Self.line(from: row, amount: amount) {
                lines.add(line)
            }
        }

        return try Snapshot(
            providerID: .vercel,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: daily.total(in: current, calendar: calendar),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    /// Hobby 没有 costs 对象时 charges 回 404，走这里。
    private static func zeroUsageSnapshot(now: Date, window: CalendarMonthWindow) -> Snapshot {
        Snapshot(
            providerID: .vercel,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: .zero
        )
    }

    /// FOCUS 行 → 明细。Vercel 的第二个维度在 `Tags.ProjectName` 里：
    /// 同一个服务分摊到哪几个项目，是这家最值得看的一刀。
    ///
    /// 没有 `ServiceFamilyName`（Cloudflare 才有），分组键就用 `ServiceName` 本身。
    /// 组名和行名相同时，界面上行只写项目名，不会出现「Fluid Compute · Fluid Compute」。
    static func line(from row: Charge, amount: Money) -> SpendLine? {
        guard let service = row.ServiceName?.collapsedWhitespace else { return nil }
        return SpendLine(
            category: service,
            label: service,
            scope: row.Tags?.ProjectName?.collapsedWhitespace,
            amountUSD: amount,
            quantity: row.ConsumedQuantity?.value,
            unit: row.ConsumedUnit?.collapsedWhitespace
        )
    }

    /// 返回 nil 表示「Hobby 没有 costs」，只认 404 且正文 `costs_not_found`。
    ///
    /// 不走 `ProviderHTTP.get`：它把所有 404 都映射成同一个错误、正文丢掉，
    /// 区分不了 Hobby 和 teamId 错 / 路径错。那些 404 当 $0 会把整队的花费藏起来，
    /// 看着像「这个月没花钱」，所以只放行能证明是 Hobby 的那一种。
    private func loadCharges(url: URL, headers: [String: String]) async throws -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.send(request)
        } catch let error as ProviderError {
            throw error
        } catch {
            throw ProviderError.networkFailure(providerID: .vercel)
        }
        if response.statusCode == 404,
           let body = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           body.error?.code == "costs_not_found" {
            return nil
        }
        if let mapped = ProviderError.fromHTTPStatus(response.statusCode, providerID: .vercel) {
            throw mapped
        }
        return data
    }

    private func loadDefaultTeamID(headers: [String: String]) async throws -> String? {
        let data = try await ProviderHTTP.get(
            url: Self.userURL,
            headers: headers,
            client: httpClient,
            providerID: .vercel
        )
        let envelope = try ProviderHTTP.decode(UserEnvelope.self, from: data, providerID: .vercel)
        let raw = envelope.user?.defaultTeamId?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (raw?.isEmpty == false) ? raw : nil
    }

    static let userURL = URL(string: "https://api.vercel.com/v2/user")!

    static func chargesURL(from: Date, to: Date, teamID: String?) -> URL {
        var items = [
            URLQueryItem(name: "from", value: BillingDateParser.rfc3339(from)),
            URLQueryItem(name: "to", value: BillingDateParser.rfc3339(to)),
        ]
        if let teamID {
            items.append(URLQueryItem(name: "teamId", value: teamID))
        }
        return ProviderURL.https(host: "api.vercel.com", path: "/v1/billing/charges", query: items)
    }

    struct ErrorEnvelope: Decodable, Sendable {
        var error: ErrorBody?
    }

    struct ErrorBody: Decodable, Sendable {
        var code: String?
    }

    struct UserEnvelope: Decodable, Sendable {
        var user: User?
    }

    struct User: Decodable, Sendable {
        var defaultTeamId: String?
    }

    struct Charge: Decodable, Sendable {
        var BilledCost: FlexibleDecimal?
        var EffectiveCost: FlexibleDecimal?
        var BillingCurrency: String?
        var ChargePeriodStart: String?
        var ChargePeriodEnd: String?
        var ChargeCategory: String?
        var ServiceName: String?
        var ConsumedQuantity: FlexibleDecimal?
        var ConsumedUnit: String?
        var Tags: Tags?
    }

    /// FOCUS 的自由标签袋。Vercel 往里塞 `ProjectName`，只解这一个键——
    /// 其余的没有界面能承接，解出来也是死代码。
    struct Tags: Decodable, Sendable {
        var ProjectName: String?
    }
}

private extension String {
    /// 去掉首尾空白，空串当没有。厂商偶尔回 `""` 而不是省略字段。
    var collapsedWhitespace: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
