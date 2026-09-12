import Foundation
import MeterCore

/// Seven Bridges 发票（`GET /v2/billing/invoices` + `/{invoice_id}`）。
///
/// 文档：https://docs.sevenbridges.com/reference/list-invoices
/// 认证：`X-SBG-Auth-Token`。Host：`api.sbgenomics.com`（欧盟 `eu-api.sbgenomics.com`）。
/// 金额：`total.amount` + `total.currency`；周期 `invoice_period.from/to`。
/// 优先发票，不用 billing-group balance。
public struct SevenBridgesBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.sevenbridges }
    public static let apiHosts = ["api.sbgenomics.com", "eu-api.sbgenomics.com"]
    static let maxDetailFetches = 40

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .sevenbridges)
        let regionHint = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let headers = [
            "X-SBG-Auth-Token": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let host = try await resolveHost(regionHint: regionHint, headers: headers)
        let list = try await loadInvoices(host: host, headers: headers)
        var detailBudget = Self.maxDetailFetches
        for summary in list {
            let from = summary.invoice_period?.from.flatMap {
                BillingDateParser.parse($0, calendar: calendar)
            }
            let to = summary.invoice_period?.to.flatMap {
                BillingDateParser.parse($0, calendar: calendar)
            }
            let stamp = from ?? to ?? current.start
            var amount = summary.total?.amount?.value ?? 0
            var currency = summary.total?.currency
            if detailBudget > 0, let id = summary.id ?? summary.invoice_id {
                detailBudget -= 1
                if let detail = try? await loadDetail(host: host, id: id, headers: headers) {
                    amount = detail.total?.amount?.value ?? amount
                    currency = detail.total?.currency ?? currency
                }
            }
            try currencies.observe(currency, providerID: .sevenbridges)
            guard amount != 0 else { continue }
            // Attribute to current month if period overlaps current window.
            let inCurrent: Bool
            if let from, let to {
                inCurrent = from <= current.endInclusive && to >= current.start
            } else {
                inCurrent = current.contains(stamp)
            }
            if inCurrent {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
                        label: summary.invoice_number ?? summary.id ?? summary.invoice_id ?? "invoice",
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
            providerID: .sevenbridges
        )
        return Snapshot(
            providerID: .sevenbridges,
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

    private func resolveHost(regionHint: String?, headers: [String: String]) async throws -> String {
        if regionHint == "eu" || regionHint?.hasPrefix("eu") == true {
            return "eu-api.sbgenomics.com"
        }
        var lastError: Error?
        for host in Self.apiHosts {
            do {
                _ = try await loadInvoices(host: host, headers: headers)
                return host
            } catch {
                lastError = error
            }
        }
        if let lastError { throw lastError }
        return Self.apiHosts[0]
    }

    private func loadInvoices(host: String, headers: [String: String]) async throws -> [Invoice] {
        let url = ProviderURL.https(host: host, path: "/v2/billing/invoices")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .sevenbridges
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .sevenbridges) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .sevenbridges)
        return envelope.items ?? envelope.invoices ?? envelope.data ?? []
    }

    private func loadDetail(host: String, id: String, headers: [String: String]) async throws -> Invoice {
        let url = ProviderURL.https(host: host, path: "/v2/billing/invoices/\(id)")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .sevenbridges
        )
        return try ProviderHTTP.decode(Invoice.self, from: data, providerID: .sevenbridges)
    }

    struct InvoiceList: Decodable, Sendable {
        var items: [Invoice]?
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoice_id: String?
        var invoice_number: String?
        var total: Total?
        var invoice_period: Period?
    }

    struct Total: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
    }

    struct Period: Decodable, Sendable {
        var from: String?
        var to: String?
    }
}
