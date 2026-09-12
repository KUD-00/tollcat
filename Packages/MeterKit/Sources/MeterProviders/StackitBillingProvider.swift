import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// STACKIT Invoice Exporter（`GET /v1/organizations/{organizationId}/invoices`）。
///
/// 文档：https://docs.api.stackit.cloud/documentation/invoice-exporter/version/v1
/// 认证：服务账号 Bearer（`apiToken` / `personalAccessToken` / `apiKey`）。
/// Host：`invoice-exporter.api.stackit.cloud`。
/// 金额：`gross` + `currency`（发票总额，本位币）。
/// 组织：`accountID` / `tenantID` / `projectID` = organizationId。
/// 可用 `year` / `month` 过滤当月发票。
public struct StackitBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.stackit }
    public static let apiHost = "invoice-exporter.api.stackit.cloud"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .stackit) {
            token = primary
        } else if let primary = try? RequiredCredential.value(.personalAccessToken, in: credential, providerID: .stackit) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .stackit)
        }
        let orgID: String
        if let primary = try? RequiredCredential.value(.accountID, in: credential, providerID: .stackit) {
            orgID = primary
        } else if let primary = try? RequiredCredential.value(.tenantID, in: credential, providerID: .stackit) {
            orgID = primary
        } else {
            orgID = try RequiredCredential.value(.projectID, in: credential, providerID: .stackit)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let months: [CalendarMonthWindow]
        if horizon == .availableHistory {
            months = CalendarMonthWindow.months(
                for: horizon,
                lookbackMonths: min(Self.descriptor.historyLookbackMonths, 12),
                now: now,
                calendar: calendar
            )
        } else {
            months = [current]
        }

        for month in months {
            let invoices = try await loadInvoices(
                orgID: orgID,
                year: calendar.component(.year, from: month.start),
                month: calendar.component(.month, from: month.start),
                headers: headers
            )
            for inv in invoices {
                // Skip credit notes / non-invoice docs when typed.
                if let doc = inv.documentType?.uppercased(), doc != "INVOICE", !doc.isEmpty {
                    continue
                }
                let amount = inv.gross?.value ?? 0
                guard amount != 0 else { continue }
                let currency = inv.currency ?? "EUR"
                try currencies.observe(currency, providerID: .stackit)
                let stamp = inv.creationDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.beginDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? month.start
                let label = inv.invoiceNumber ?? "invoice"
                if month.start == current.start {
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
                        start: month.start,
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
            providerID: .stackit
        )
        return Snapshot(
            providerID: .stackit,
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
        orgID: String,
        year: Int,
        month: Int,
        headers: [String: String]
    ) async throws -> [Invoice] {
        var results: [Invoice] = []
        var cursor: String? = nil
        for _ in 0..<20 {
            var query: [URLQueryItem] = [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
                URLQueryItem(name: "limit", value: "100"),
            ]
            if let cursor, !cursor.isEmpty {
                query.append(URLQueryItem(name: "cursor", value: cursor))
            }
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/v1/organizations/\(orgID)/invoices",
                query: query
            )
            let data = try await ProviderHTTP.get(
                url: url, headers: headers, client: httpClient, providerID: .stackit
            )
            let page = try ProviderHTTP.decode(InvoicePage.self, from: data, providerID: .stackit)
            results.append(contentsOf: page.invoices ?? [])
            let next = page.nextCursor?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let next, !next.isEmpty {
                cursor = next
            } else {
                break
            }
        }
        return results
    }

    struct InvoicePage: Decodable, Sendable {
        var invoices: [Invoice]?
        var nextCursor: String?
        var limit: Int?
    }

    struct Invoice: Decodable, Sendable {
        var invoiceNumber: String?
        var creationDate: String?
        var beginDate: String?
        var endDate: String?
        var currency: String?
        var gross: FlexibleDecimal?
        var net: FlexibleDecimal?
        var documentType: String?

        enum CodingKeys: String, CodingKey {
            case invoiceNumber
            case creationDate
            case beginDate
            case endDate
            case currency
            case gross
            case net
            case documentType
        }
    }
}
