import Foundation
import MeterCore

/// Hubble Network 组织发票（`GET /v1/org/{org_id}/billing/invoices`）。
///
/// 文档：https://hubble.com/docs/openapi.yaml
/// 认证：Bearer API key（scope `read-billing-invoices`）。
/// Host：`api.hubble.com`。`accountID` = `org_id`。
/// 金额：`total_balance`（组织币种主币；OpenAPI 未给 invoice 级 currency，缺省 USD，
/// 与 Stripe self-serve / Formspring 同类）。日期：`issue_timestamp`（UTC 秒）。
/// 跳过 `DRAFT`。订阅里的 `prepaid_devices` 是套餐设备数，不是预付钱包——不读余额类端点。
public struct HubbleBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.hubble }
    public static let apiHost = "api.hubble.com"
    public static let defaultCurrency = "USD"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .hubble) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .hubble)
        }
        let orgID = try RequiredCredential.value(.accountID, in: credential, providerID: .hubble)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe(Self.defaultCurrency, providerID: .hubble)

        let invoices = try await loadInvoices(orgID: orgID, headers: headers)
        for inv in invoices {
            let status = (inv.status ?? "").uppercased()
            if status == "DRAFT" { continue }
            let amount = inv.total_balance?.value ?? 0
            guard amount != 0 else { continue }
            let stamp: Date
            if let unix = inv.issue_timestamp?.value {
                stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: unix).doubleValue)
            } else {
                stamp = current.start
            }
            let label = inv.invoice_number ?? inv.invoice_id ?? "invoice"
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
            providerID: .hubble
        )
        return Snapshot(
            providerID: .hubble,
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

    private func loadInvoices(orgID: String, headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(orgID: orgID),
            headers: headers,
            client: httpClient,
            providerID: .hubble
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .hubble)
        return envelope.invoices ?? []
    }

    static func invoicesURL(orgID: String) -> URL {
        ProviderURL.https(host: apiHost, path: "/v1/org/\(orgID)/billing/invoices")
    }

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_id: String?
        var invoice_number: String?
        var issue_timestamp: FlexibleDecimal?
        var status: String?
        var total_balance: FlexibleDecimal?
    }
}
