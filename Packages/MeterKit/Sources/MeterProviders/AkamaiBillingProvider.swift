import Foundation
import MeterCore

/// Akamai Invoicing API v4：`GET /invoicing-api/v4/invoices?month=YYYY-MM`
///（可选 `/contracts/{contractId}/invoices`）→ `invoiceTotal` + `invoiceCurrency`（ISO 4217）。
///
/// 文档：https://techdocs.akamai.com/invoicing
/// 认证：EdgeGrid（`accessKeyID`=client_token，`secretAccessKey`=client_secret，
/// `apiToken`=access_token；`accountID` 可选 = contractId；`projectID` = API host）。
/// **不要**用 companion Billing usage/metrics 当金额源。
public struct AkamaiBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.akamai }

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
        let clientToken = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .akamai)
        let clientSecret = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .akamai)
        let accessToken = try RequiredCredential.value(.apiToken, in: credential, providerID: .akamai)
        let resolvedHost = try {
            let h = credential.value(for: .projectID)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let h, !h.isEmpty {
                return h.replacingOccurrences(of: "https://", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            }
            throw ProviderError.missingCredential(providerID: .akamai)
        }()
        let contractID = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal = Decimal(0)

        for month in months {
            let period = Self.monthString(window: month, calendar: calendar)
            let path: String
            if let contractID, !contractID.isEmpty {
                path = "/invoicing-api/v4/contracts/\(contractID)/invoices"
            } else {
                path = "/invoicing-api/v4/invoices"
            }
            let query = "month=\(period)"
            let url = ProviderURL.https(
                host: resolvedHost,
                path: path,
                query: [URLQueryItem(name: "month", value: period)]
            )
            let auth = Self.edgeGridAuthorization(
                method: "GET",
                host: resolvedHost,
                path: path,
                query: query,
                clientToken: clientToken,
                clientSecret: clientSecret,
                accessToken: accessToken,
                timestamp: now
            )
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: url,
                    headers: [
                        "Authorization": auth,
                        "Accept": "application/json",
                    ],
                    client: httpClient,
                    providerID: .akamai
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                continue
            }
            if data.isEmpty { continue }
            let invoices = (try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .akamai)) ?? []
            var monthTotal = Decimal(0)
            for inv in invoices {
                let amount = inv.invoiceTotal?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.invoiceCurrency, providerID: .akamai)
                monthTotal += amount
                if month.start == current.start {
                    let label = inv.invoiceId.map(String.init) ?? inv.invoiceType ?? "invoice"
                    lines.add(
                        SpendLine(
                            category: inv.invoiceType ?? "invoice",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
            if month.start == current.start {
                currentTotal = monthTotal
                if monthTotal != 0 {
                    daily.add(day: month.start, amount: Money(usd: monthTotal))
                }
            } else if monthTotal != 0 {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: monthTotal),
                    current: current,
                    calendar: calendar
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .akamai
        )
        return Snapshot(
            providerID: .akamai,
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

    static func monthString(window: CalendarMonthWindow, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    /// EdgeGrid EG1-HMAC-SHA256（无 body / 无 headers 签名内容）。
    static func edgeGridAuthorization(
        method: String,
        host: String,
        path: String,
        query: String,
        clientToken: String,
        clientSecret: String,
        accessToken: String,
        timestamp: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HH:mm:ssZ"
        let ts = formatter.string(from: timestamp)
        let nonce = UUID().uuidString.lowercased()
        let authHeader = "EG1-HMAC-SHA256 client_token=\(clientToken);access_token=\(accessToken);timestamp=\(ts);nonce=\(nonce);"
        let dataToSign = [
            method.uppercased(),
            "https",
            host.lowercased(),
            path,
            query,
            "",
            "",
            authHeader,
        ].joined(separator: "\t")
        let signingKeyRaw = MeterHMAC.sha256(
            key: Data(clientSecret.utf8),
            message: Data(ts.utf8)
        )
        let signature = hmacBase64(keyData: signingKeyRaw, message: dataToSign)
        return authHeader + "signature=\(signature)"
    }

    static func hmacBase64(keyData: Data, message: String) -> String {
        let mac = MeterHMAC.sha256(key: keyData, message: Data(message.utf8))
        return mac.base64EncodedString()
    }

    struct Invoice: Decodable, Sendable {
        var invoiceId: Int?
        var invoiceTotal: FlexibleDecimal?
        var invoiceCurrency: String?
        var invoiceDate: String?
        var invoiceType: String?
        var contractId: String?
        var accountId: String?
    }
}
