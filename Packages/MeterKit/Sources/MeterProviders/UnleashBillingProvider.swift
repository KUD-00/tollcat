import Foundation
import MeterCore

/// Unleash Enterprise 明细发票（`GET /api/admin/invoices/list`）。
///
/// 文档：https://docs.getunleash.io/api/get-detailed-invoices
/// 认证：`Authorization`（API key，可选 `Bearer ` 前缀）。
/// Host：凭据 `projectID`（实例主机名，如 `eu.app.unleash-hosted.com`）。
/// 金额：发票级 `totalAmount` + `currency`（主币单位；行内 minor units 不用）。
/// 日期：`invoiceDate` / `monthText` 周期。
public struct UnleashBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.unleash }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
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
        let token: String
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .unleash) {
            token = primary
        } else if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .unleash) {
            token = primary
        } else {
            token = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .unleash)
        }
        let host = try Self.resolveHost(credential: credential)
        let authValue = token.lowercased().hasPrefix("bearer ") ? token : token
        let headers = [
            "Authorization": authValue,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(host: host, headers: headers)
        for inv in invoices {
            let status = (inv.status ?? "").lowercased()
            if status == "void" || status == "uncollectible" || status == "draft" { continue }
            let amount = inv.totalAmount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.currency, providerID: .unleash)
            let stamp = inv.invoiceDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.monthText ?? inv.invoiceDate ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .unleash
        )
        return Snapshot(
            providerID: .unleash,
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

    static func resolveHost(credential: Credential) throws -> String {
        let raw = credential.value(for: .projectID)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? credential.value(for: .accountID)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else {
            throw ProviderError.missingCredential(providerID: .unleash)
        }
        var host = raw
        if let url = URL(string: raw), let h = url.host, !h.isEmpty {
            host = h
        } else {
            host = raw
                .replacingOccurrences(of: "https://", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if let slash = host.firstIndex(of: "/") {
                host = String(host[..<slash])
            }
        }
        guard !host.isEmpty, allowedHosts.contains(host.lowercased()) else {
            // host 来自用户填的 projectID/accountID，是不可信输入。只查「非空」不够：
            // 真传输的白名单是**整段相等**匹配，别家控制台域、第一方 Worker 都在名单上，
            // 填成那些就能把 Unleash 的 API key 送到名单内别人家去；
            // `https://eu.app.unleash-hosted.com@github.com` 这种 userinfo 写法
            // URL.host 解出来也是 github.com。钉死本家三台。
            throw ProviderError.missingCredential(providerID: .unleash)
        }
        return host
    }

    /// Hosted 的三台。自建实例用自定义域，今天本来就会被全局出站白名单挡住，
    /// 所以收紧这里不会砍掉任何现在能用的接法。
    static let allowedHosts: Set<String> = [
        "eu.app.unleash-hosted.com",
        "us.app.unleash-hosted.com",
        "app.unleash-hosted.com",
    ]

    static func invoicesURL(host: String) -> URL {
        ProviderURL.https(host: host, path: "/api/admin/invoices/list")
    }

    private func loadInvoices(host: String, headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(host: host),
            headers: headers,
            client: httpClient,
            providerID: .unleash
        )
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .unleash)
        return envelope.invoices ?? []
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoiceDate: String?
        var status: String?
        var totalAmount: FlexibleDecimal?
        var subtotal: FlexibleDecimal?
        var currency: String?
        var monthText: String?
    }
}
