import Foundation
import MeterCore

/// Typebot Stripe 发票列表（`GET /api/v1/billing/invoices?workspaceId=`）。
///
/// 文档：https://docs.typebot.com/api-reference/billing/list-invoices
/// 源码：`packages/billing/src/api/handleListInvoices.ts` — `amount` = Stripe `invoice.subtotal`（最小货币单位）。
/// 认证：`Authorization: Bearer <API token>`。Host：`app.typebot.io`（OpenAPI 亦列 `app.typebot.com`）。
/// 金额：`amount/100` + `currency`；日期：`date`（Stripe `paid_at` Unix 秒）。
/// 凭据：`apiToken`/`apiKey` + `accountID`（workspaceId）。
public struct TypebotBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.typebot }
    public static let apiHost = "app.typebot.io"
    static let centsPerUnit = Decimal(100)

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .typebot) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .typebot)
        }
        let workspaceID = try RequiredCredential.value(.accountID, in: credential, providerID: .typebot)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(workspaceID: workspaceID, headers: headers)
        for inv in invoices {
            let cents = inv.amount?.value ?? 0
            guard cents != 0 else { continue }
            let amount = cents / Self.centsPerUnit
            try currencies.observe(inv.currency, providerID: .typebot)
            let stamp: Date
            if let paid = inv.date?.value {
                let seconds = NSDecimalNumber(decimal: paid).doubleValue
                // Stripe paid_at 为秒；防御性兼容毫秒。
                stamp = Date(timeIntervalSince1970: seconds > 1_000_000_000_000 ? seconds / 1000 : seconds)
            } else {
                stamp = current.start
            }
            let label = inv.id ?? "invoice"
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
            providerID: .typebot
        )
        return Snapshot(
            providerID: .typebot,
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
        workspaceID: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(workspaceID: workspaceID),
            headers: headers,
            client: httpClient,
            providerID: .typebot
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .typebot)
        return envelope.invoices ?? []
    }

    static func invoicesURL(workspaceID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/api/v1/billing/invoices",
            query: [URLQueryItem(name: "workspaceId", value: workspaceID)]
        )
    }

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var url: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var date: FlexibleDecimal?
    }
}
