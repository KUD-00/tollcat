import Foundation
import MeterCore

/// Sevalla 本周期 PaaS 用量费用（`GET /v2/company/{id}/paas-usage`）。
///
/// 文档：https://api-docs.sevalla.com/v2/company/get-usage
/// 认证：`Authorization: Bearer`（API key）。Host：`api.sevalla.com`。
/// 金额：每行 `cost`（文档标明 Cost in USD）；日期：`date`（unix 毫秒）。
/// Company ID：优先 `accountID`；缺省则 `GET /v2/validate` 回 `company`。
/// `period_offset`：0=当前账期，-1=上一账期（历史）。
public struct SevallaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.sevalla }
    public static let apiHost = "api.sevalla.com"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .sevalla) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .sevalla)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let companyID: String
        if let override = credential.value(for: .accountID)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            companyID = override
        } else {
            companyID = try await loadCompanyID(headers: headers)
        }

        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let offsets: [Int]
        switch horizon {
        case .currentMonth:
            offsets = [0]
        case .availableHistory:
            offsets = [0, -1]
        }

        for offset in offsets {
            let envelope = try await loadUsage(companyID: companyID, periodOffset: offset, headers: headers)
            for row in envelope.company?.paas_usage ?? [] {
                let amount = row.cost?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe("USD", providerID: .sevalla)
                let stamp: Date
                if let ms = row.date?.value {
                    stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: ms).doubleValue / 1000.0)
                } else {
                    stamp = current.start
                }
                let label = row.category ?? row.id ?? "usage"
                if offset == 0 {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: row.category ?? "usage",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                } else {
                    daily.addPastMonth(
                        start: stamp,
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
            providerID: .sevalla
        )
        return Snapshot(
            providerID: .sevalla,
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

    private func loadCompanyID(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.validateURL,
            headers: headers,
            client: httpClient,
            providerID: .sevalla
        )
        let envelope = try ProviderHTTP.decode(ValidateEnvelope.self, from: data, providerID: .sevalla)
        guard let company = envelope.company?.trimmingCharacters(in: .whitespacesAndNewlines), !company.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .sevalla)
        }
        return company
    }

    private func loadUsage(
        companyID: String,
        periodOffset: Int,
        headers: [String: String]
    ) async throws -> UsageEnvelope {
        let data = try await ProviderHTTP.get(
            url: Self.usageURL(companyID: companyID, periodOffset: periodOffset),
            headers: headers,
            client: httpClient,
            providerID: .sevalla
        )
        return try ProviderHTTP.decode(UsageEnvelope.self, from: data, providerID: .sevalla)
    }

    static var validateURL: URL {
        ProviderURL.https(host: apiHost, path: "/v2/validate")
    }

    static func usageURL(companyID: String, periodOffset: Int) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/v2/company/\(companyID)/paas-usage",
            query: [URLQueryItem(name: "period_offset", value: String(periodOffset))]
        )
    }

    struct ValidateEnvelope: Decodable, Sendable {
        var company: String?
        var name: String?
        var status: String?
    }

    struct UsageEnvelope: Decodable, Sendable {
        var company: CompanyUsage?
    }

    struct CompanyUsage: Decodable, Sendable {
        var paas_usage: [UsageRow]?
    }

    struct UsageRow: Decodable, Sendable {
        var id: String?
        var date: FlexibleDecimal?
        var category: String?
        var id_resource: String?
        var usage: FlexibleDecimal?
        var cost: FlexibleDecimal?
    }
}
