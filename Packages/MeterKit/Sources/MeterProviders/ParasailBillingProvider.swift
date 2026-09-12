import Foundation
import MeterCore

/// Parasail 账单发票（`GET /v1/billing/invoices/current` + list）。
///
/// 文档：https://docs.parasail.io/parasail-docs/api-reference/billing-api
/// 认证：`Authorization: Bearer <psk-…>`。Host：`api.parasail.io`。
/// 金额：发票 `total`（USD）；忽略预付 `commit_purchase` / `applied_commit_or_credit` 行类型时仍以发票 total 为准。
/// 凭据：`apiToken`/`apiKey`。
public struct ParasailBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.parasail }
    public static let apiHost = "api.parasail.io"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .parasail) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .parasail)
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
        try currencies.observe("USD", providerID: .parasail)

        if let draft = try await loadCurrentInvoice(headers: headers) {
            let amount = draft.total?.value ?? 0
            if amount != 0 {
                currentTotal = amount
                daily.add(day: current.start, amount: Money(usd: amount))
                let items = draft.line_items ?? []
                if items.isEmpty {
                    lines.add(
                        SpendLine(
                            category: draft.type ?? "invoice",
                            label: draft.id ?? "current",
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else {
                    for item in items {
                        let itemType = (item.type ?? "").lowercased()
                        if itemType == "commit_purchase" || itemType == "applied_commit_or_credit" {
                            continue
                        }
                        let part = item.total?.value ?? 0
                        guard part != 0 else { continue }
                        lines.add(
                            SpendLine(
                                category: item.type ?? "usage",
                                label: item.name ?? "line",
                                amountUSD: Money(usd: part)
                            )
                        )
                    }
                    if lines.isEmpty {
                        lines.add(
                            SpendLine(
                                category: draft.type ?? "invoice",
                                label: draft.id ?? "current",
                                amountUSD: Money(usd: amount)
                            )
                        )
                    }
                }
            }
        }

        if horizon == .availableHistory {
            let invoices = try await loadInvoiceList(headers: headers)
            for inv in invoices {
                let status = (inv.status ?? "").uppercased()
                if status == "VOID" || status == "DRAFT" { continue }
                let amount = inv.total?.value ?? 0
                guard amount != 0 else { continue }
                let stamp = inv.start_timestamp.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.issued_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                if current.contains(stamp) { continue }
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
            providerID: .parasail
        )
        return Snapshot(
            providerID: .parasail,
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

    private func loadCurrentInvoice(headers: [String: String]) async throws -> Invoice? {
        do {
            let data = try await ProviderHTTP.get(
                url: Self.currentURL,
                headers: headers,
                client: httpClient,
                providerID: .parasail
            )
            return try ProviderHTTP.decode(Invoice.self, from: data, providerID: .parasail)
        } catch let error as ProviderError where error.code == .billingAPIUnavailable {
            return nil
        }
    }

    private func loadInvoiceList(headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.listURL,
            headers: headers,
            client: httpClient,
            providerID: .parasail
        )
        if let env = try? ProviderHTTP.decode(ListEnvelope.self, from: data, providerID: .parasail) {
            return env.invoices ?? env.data ?? []
        }
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .parasail)
    }

    static let currentURL: URL = ProviderURL.https(
        host: apiHost,
        path: "/v1/billing/invoices/current"
    )

    static let listURL: URL = ProviderURL.https(
        host: apiHost,
        path: "/v1/billing/invoices",
        query: [URLQueryItem(name: "status", value: "FINALIZED")]
    )

    struct ListEnvelope: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var status: String?
        var type: String?
        var total: FlexibleDecimal?
        var start_timestamp: String?
        var end_timestamp: String?
        var issued_at: String?
        var line_items: [LineItem]?
    }

    struct LineItem: Decodable, Sendable {
        var name: String?
        var total: FlexibleDecimal?
        var type: String?
    }
}
