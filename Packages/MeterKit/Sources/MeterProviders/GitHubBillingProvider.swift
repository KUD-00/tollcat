import Foundation
import MeterCore

/// GitHub Billing usage API（用户或组织）。
///
/// 文档：
/// - 用户：`GET /users/{username}/settings/billing/usage`
/// - 组织：`GET /organizations/{org}/settings/billing/usage/summary`
///   （亦可 `…/billing/usage` 明细；企业同路径前缀 `enterprises/{slug}`）
///
/// 认证：**classic PAT**（fine-grained 不支持 Billing usage）。Account permissions Plan: Read。
/// `Accept: application/vnd.github+json`，`X-GitHub-Api-Version: 2026-03-10`
///
/// 金额：`netAmount` / `grossAmount` / `discountAmount` / `pricePerUnit`。
/// 有 `accountID`（org 登录名）时走组织 summary；否则 `GET /user` → 用户 usage。
/// 日期：`year` / `month`（可选 `day`）。
public struct GitHubBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.github }
    public static let apiVersion = "2026-03-10"

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
        let token = try RequiredCredential.value(
            .personalAccessToken,
            in: credential,
            providerID: .github
        )
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": Self.apiVersion,
            "User-Agent": "TollCat",
        ]
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let org = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var items: [UsageItem] = []
        if let org, !org.isEmpty {
            for month in Self.months(for: horizon, now: now, calendar: calendar) {
                items.append(
                    contentsOf: try await loadOrgSummary(org: org, month: month, headers: headers)
                )
            }
        } else {
            let login = try await loadLogin(headers: headers)
            for month in Self.months(for: horizon, now: now, calendar: calendar) {
                items.append(
                    contentsOf: try await loadUserUsage(login: login, month: month, headers: headers)
                )
            }
        }

        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var committed = Money.zero
        var sawMonthly = false
        var chargeDay: Int?
        for item in items {
            let amount = Self.itemMoney(item)
            let day = item.date.flatMap { BillingDateParser.parse($0, calendar: calendar) } ?? window.start
            let inWindow = window.contains(day)
            if inWindow, let line = Self.line(from: item, amount: amount) {
                lines.add(line)
            }
            if item.isMonthlyPlan {
                guard inWindow else { continue }
                sawMonthly = true
                committed += amount
                if chargeDay == nil {
                    chargeDay = calendar.component(.day, from: day)
                }
                continue
            }
            daily.add(day: day, amount: amount)
        }

        let usage = daily.snapshotDaily
        return Snapshot(
            providerID: .github,
            kind: Self.descriptor.kind,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: usage == nil ? (sawMonthly ? nil : .zero) : Self.spend(
                in: daily,
                from: window.start,
                before: window.nextStart,
                calendar: calendar
            ),
            committedMonthlyUSD: sawMonthly ? committed : nil,
            chargeDayOfMonth: chargeDay,
            dailyUSD: usage,
            lines: lines.snapshot
        )
    }

    /// Prefer net; fall back to gross − discount, then gross.
    static func itemMoney(_ item: UsageItem) -> Money {
        if let net = item.netAmount?.value {
            return Money(usd: net)
        }
        if let gross = item.grossAmount?.value {
            let discount = item.discountAmount?.value ?? 0
            return Money(usd: max(gross - discount, 0))
        }
        return .zero
    }

    static func months(
        for horizon: BillingFetchHorizon,
        now: Date,
        calendar: Calendar
    ) -> [DateComponents] {
        let lookback: Int
        switch horizon {
        case .currentMonth:
            lookback = 0
        case .availableHistory:
            lookback = max(Self.descriptor.historyLookbackMonths, 1)
        }
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (0...lookback).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: thisMonth) else {
                return nil
            }
            return calendar.dateComponents([.year, .month], from: date)
        }
    }

    static func line(from item: UsageItem, amount: Money) -> SpendLine? {
        let product = item.product?.trimmed
        let sku = item.sku?.trimmed
        guard let category = product ?? sku, let label = sku ?? product else { return nil }
        return SpendLine(
            category: category,
            label: label,
            scope: item.repositoryName?.trimmed,
            amountUSD: amount,
            listUSD: item.grossAmount.map { Money(usd: $0.value) },
            quantity: item.quantity?.value,
            unit: item.unitType?.trimmed
        )
    }

    private static func spend(
        in daily: DailySpendAccumulator,
        from start: Date,
        before end: Date,
        calendar: Calendar
    ) -> Money {
        guard let days = daily.snapshotDaily else { return .zero }
        return days.reduce(into: .zero) { sum, entry in
            let day = calendar.startOfDay(for: entry.key)
            guard day >= start, day < end else { return }
            sum += entry.value
        }
    }

    private func loadOrgSummary(
        org: String,
        month: DateComponents,
        headers: [String: String]
    ) async throws -> [UsageItem] {
        let url = Self.orgUsageSummaryURL(org: org, year: month.year ?? 0, month: month.month ?? 0)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .github
        )
        // summary 可能是 { usageItems: [...] } 或直接数组 / 带 timePeriod 的包装
        if let envelope = try? ProviderHTTP.decode(UsageEnvelope.self, from: data, providerID: .github),
           envelope.usageItems != nil {
            return envelope.usageItems ?? []
        }
        if let array = try? JSONDecoder().decode([UsageItem].self, from: data) {
            return array
        }
        if let summary = try? ProviderHTTP.decode(UsageSummary.self, from: data, providerID: .github) {
            let stamped = Self.stamp(summary.usageItems ?? summary.items ?? [], period: summary.timePeriod, month: month, calendar: calendar)
            return stamped
        }
        throw ProviderError.malformedResponse(providerID: .github)
    }

    /// Org summary rows often omit per-row `date`; stamp from `timePeriod` or the queried month.
    static func stamp(
        _ items: [UsageItem],
        period: TimePeriod?,
        month: DateComponents,
        calendar: Calendar
    ) -> [UsageItem] {
        let fallback: String
        if let period,
           let year = period.year,
           let mon = period.month {
            let day = period.day ?? 1
            fallback = String(format: "%04d-%02d-%02d", year, mon, day)
        } else {
            fallback = String(format: "%04d-%02d-01", month.year ?? 0, month.month ?? 0)
        }
        return items.map { item in
            var copy = item
            if copy.date == nil || copy.date?.isEmpty == true {
                copy.date = fallback
            }
            return copy
        }
    }

    private func loadUserUsage(
        login: String,
        month: DateComponents,
        headers: [String: String]
    ) async throws -> [UsageItem] {
        let url = Self.userUsageURL(login: login, year: month.year ?? 0, month: month.month ?? 0)
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .github
        )
        let payload = try ProviderHTTP.decode(UsageEnvelope.self, from: data, providerID: .github)
        return payload.usageItems ?? []
    }

    private func loadLogin(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.userURL,
            headers: headers,
            client: httpClient,
            providerID: .github
        )
        let user = try ProviderHTTP.decode(User.self, from: data, providerID: .github)
        let login = user.login?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !login.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .github)
        }
        return login
    }

    static let userURL = URL(string: "https://api.github.com/user")!

    static func userUsageURL(login: String, year: Int, month: Int) -> URL {
        ProviderURL.https(
            host: "api.github.com",
            path: "/users/\(login)/settings/billing/usage",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
            ]
        )
    }

    static func orgUsageSummaryURL(org: String, year: Int, month: Int) -> URL {
        ProviderURL.https(
            host: "api.github.com",
            path: "/organizations/\(org)/settings/billing/usage/summary",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
            ]
        )
    }

    struct User: Decodable, Sendable {
        var login: String?
    }

    struct UsageEnvelope: Decodable, Sendable {
        var usageItems: [UsageItem]?
    }

    struct UsageSummary: Decodable, Sendable {
        var timePeriod: TimePeriod?
        var usageItems: [UsageItem]?
        var items: [UsageItem]?
    }

    struct TimePeriod: Decodable, Sendable {
        var year: Int?
        var month: Int?
        var day: Int?
    }

    struct UsageItem: Decodable, Sendable {
        var date: String?
        var product: String?
        var sku: String?
        var unitType: String?
        var repositoryName: String?
        var quantity: FlexibleDecimal?
        var netAmount: FlexibleDecimal?
        var grossAmount: FlexibleDecimal?
        var discountAmount: FlexibleDecimal?
        var pricePerUnit: FlexibleDecimal?

        var isMonthlyPlan: Bool {
            switch (unitType ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "month", "months":
                return true
            default:
                return false
            }
        }
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
