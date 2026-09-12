import Foundation
import MeterCore

/// i3D.net 账户发票（`GET /v3/account/invoice`）。
///
/// 文档：https://docs.i3d.net/api-references/general/billing.md
/// 认证：`PRIVATE-TOKEN: <api key>`。
/// Host：`api.i3d.net`。
/// 金额：`amountIncVAT` / `amountExclVAT` 为**分**（cents，字符串）+ `currency`。
/// 日期：`creationDate`（unix 秒）。`isCredit == 1` 跳过贷项。
public struct I3DNetBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.i3dnet }
    public static let apiHost = "api.i3d.net"
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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .i3dnet) {
            token = primary
        } else if let alt = try? RequiredCredential.value(.apiToken, in: credential, providerID: .i3dnet) {
            token = alt
        } else {
            token = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .i3dnet)
        }
        let headers = [
            "PRIVATE-TOKEN": token,
            "Accept": "application/json",
            "RANGED-DATA": "start=0,results=100",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for inv in invoices {
            if inv.isCredit == 1 { continue }
            let cents = inv.amountIncVAT?.value ?? inv.amountExclVAT?.value ?? 0
            guard cents > 0 else { continue }
            let amount = cents / Self.centsPerUnit
            try currencies.observe(inv.currency, providerID: .i3dnet)
            let stamp: Date = {
                if let unix = inv.creationDate {
                    return Date(timeIntervalSince1970: TimeInterval(unix))
                }
                return current.start
            }()
            let label = inv.invoiceNumber ?? inv.id ?? "invoice"
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
            providerID: .i3dnet
        )
        return Snapshot(
            providerID: .i3dnet,
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

    private func loadInvoices(headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL, headers: headers, client: httpClient, providerID: .i3dnet
        )
        return try ProviderHTTP.decode([Invoice].self, from: data, providerID: .i3dnet)
    }

    static let invoicesURL = URL(string: "https://api.i3d.net/v3/account/invoice")!

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoiceNumber: String?
        var creationDate: Int?
        var currency: String?
        var amountIncVAT: FlexibleDecimal?
        var amountExclVAT: FlexibleDecimal?
        var isCredit: Int?
    }
}
