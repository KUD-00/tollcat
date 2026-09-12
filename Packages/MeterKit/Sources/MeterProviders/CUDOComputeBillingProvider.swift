import Foundation
import MeterCore

/// CUDO Compute 账单发票（`GET /v1/invoices?id=<billingAccountId>`）。
///
/// 文档：https://docs.cudocompute.com/api/billing/list-invoices
/// 认证：`Authorization: Bearer <API key>`；`accountID` = billing account id。
/// Host：`rest.compute.cudo.org`。
/// 金额：`total`（int64 字符串，Stripe 分）+ `currency`。日期：`created`（unix 秒字符串）。
public struct CUDOComputeBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.cudocompute }
    public static let apiHost = "rest.compute.cudo.org"
    static let centsPerUnit = Decimal(100)
    static let maxPages = 20

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .cudocompute) {
            token = primary
        } else if let alt = try? RequiredCredential.value(.apiToken, in: credential, providerID: .cudocompute) {
            token = alt
        } else {
            token = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .cudocompute)
        }
        let billingAccountID = try RequiredCredential.value(.accountID, in: credential, providerID: .cudocompute)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var startingAfter: String? = nil
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(
                billingAccountID: billingAccountID,
                startingAfter: startingAfter,
                headers: headers
            )
            if batch.invoices.isEmpty { break }
            for inv in batch.invoices {
                if let status = inv.status?.lowercased(), status == "void" || status == "draft" {
                    continue
                }
                let cents = inv.total?.value ?? inv.amountDue?.value ?? 0
                guard cents > 0 else { continue }
                let amount = cents / Self.centsPerUnit
                try currencies.observe(inv.currency, providerID: .cudocompute)
                let stamp: Date = {
                    if let raw = inv.created, let unix = Double(raw) {
                        return Date(timeIntervalSince1970: unix)
                    }
                    return current.start
                }()
                let label = inv.number ?? inv.id ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.billingReason ?? inv.status ?? "invoice",
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
            if batch.hasMore != true { break }
            startingAfter = batch.invoices.last?.id
            if startingAfter == nil { break }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .cudocompute
        )
        return Snapshot(
            providerID: .cudocompute,
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

    private func loadInvoices(
        billingAccountID: String,
        startingAfter: String?,
        headers: [String: String]
    ) async throws -> ListResponse {
        var components = URLComponents(url: Self.invoicesURL, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "id", value: billingAccountID),
            URLQueryItem(name: "pageSize", value: "100"),
        ]
        if let startingAfter {
            items.append(URLQueryItem(name: "startingAfter", value: startingAfter))
        }
        components.queryItems = items
        let data = try await ProviderHTTP.get(
            url: components.url!,
            headers: headers,
            client: httpClient,
            providerID: .cudocompute
        )
        return try ProviderHTTP.decode(ListResponse.self, from: data, providerID: .cudocompute)
    }

    static let invoicesURL = URL(string: "https://rest.compute.cudo.org/v1/invoices")!

    struct ListResponse: Decodable, Sendable {
        var invoices: [Invoice] = []
        var hasMore: Bool?
    }
    struct Invoice: Decodable, Sendable {
        var id: String?
        var number: String?
        var total: FlexibleDecimal?
        var amountDue: FlexibleDecimal?
        var currency: String?
        var created: String?
        var status: String?
        var billingReason: String?
    }
}
