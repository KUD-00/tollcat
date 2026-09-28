import Foundation
import MeterCore

/// Typebot Stripe 发票列表（`GET /api/v1/billing/invoices?workspaceId=`）。
///
/// 文档：https://docs.typebot.com/api-reference/billing/list-invoices
/// 源码：`packages/billing/src/api/handleListInvoices.ts` — `amount` = Stripe `invoice.subtotal`（最小货币单位）。
/// 认证：`Authorization: Bearer <API token>`。Host：`app.typebot.io`（OpenAPI 亦列 `app.typebot.com`）。
/// 金额：`amount` 按 Stripe 的币种小数位折主单位 + `currency`；日期：`date`（Stripe `paid_at` Unix 秒）。
/// 凭据：`apiToken`/`apiKey` + `accountID`（workspaceId）。
public struct TypebotBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.typebot }
    public static let apiHost = "app.typebot.io"

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
            // 没有 paid_at 的是没付的草稿/未结发票：塞进本月会每次取数都算成本月花费，
            // 永远滚不进历史，所以直接不计。
            guard let paid = inv.date?.value else { continue }
            let amount = Self.majorUnits(cents, currency: inv.currency)
            try currencies.observe(inv.currency, providerID: .typebot)
            let seconds = NSDecimalNumber(decimal: paid).doubleValue
            // Stripe paid_at 为秒；防御性兼容毫秒。
            let stamp = Date(timeIntervalSince1970: seconds > 1_000_000_000_000 ? seconds / 1000 : seconds)
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

        // 合计、日线、明细都按原币拼好，收尾统一乘同一个汇率——
        // 明细若留原币却标成美元，非美元户的逐行金额会差出一个汇率。
        return try Snapshot(
            providerID: .typebot,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    /// Stripe 的最小单位不是一律「分」：零小数币（JPY、KRW…）本身就是主单位，
    /// 三位小数币（KWD、BHD…）是千分之一。一律除 100 会把日元户少算百倍。
    static func majorUnits(_ minor: Decimal, currency: String?) -> Decimal {
        let code = (currency ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let zeroDecimal: Set<String> = [
            "BIF", "CLP", "DJF", "GNF", "JPY", "KMF", "KRW", "MGA",
            "PYG", "RWF", "UGX", "VND", "VUV", "XAF", "XOF", "XPF",
        ]
        let threeDecimal: Set<String> = ["BHD", "JOD", "KWD", "OMR", "TND"]
        if zeroDecimal.contains(code) { return minor }
        if threeDecimal.contains(code) { return minor / 1000 }
        return minor / 100
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
