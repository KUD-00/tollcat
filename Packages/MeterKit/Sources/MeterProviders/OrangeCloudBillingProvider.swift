import Foundation
import MeterCore

/// Orange Flexible Engine / Cloud Avenue Customer Space 账单单据（`GET /cloud/b2b/v1/documents`）。
///
/// 文档：https://cloud.orange-business.com（Cloud Store Customer Space API）。
/// 认证：`Authorization: Bearer <access token>` + `X-API-Key` + `X-ECCS-Contract-Id`。
/// 可选：`clientID`/`clientSecret` 换 OAuth token（`POST /oauth/v3/token`）。
/// 优先 `documentType` = bills / invoices；金额 `amount` + ISO `currency`。
/// 区别于 Orange Business View Bill 的 M2M 电信账单。
public struct OrangeCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.orangecloud }
    public static let apiHost = "api.orange.com"
    static let tokenPath = "/oauth/v3/token"

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .orangecloud)
        let contractID = try RequiredCredential.value(.accountID, in: credential, providerID: .orangecloud)
        let token = try await resolveAccessToken(credential: credential)
        let headers = [
            "Authorization": "Bearer \(token)",
            "X-API-Key": apiKey,
            "X-ECCS-Contract-Id": contractID,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let documents = try await loadDocuments(headers: headers)
        for doc in documents {
            let type = (doc.documentType ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard Self.feeDocumentTypes.contains(type) else { continue }
            let currency = doc.currency?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            try currencies.observe(currency, providerID: .orangecloud)
            let amount = doc.amount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = Self.stamp(doc, calendar: calendar) ?? current.start
            let label = doc.filename
                ?? doc.period
                ?? doc.id
                ?? type

            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: type,
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
            providerID: .orangecloud
        )
        return Snapshot(
            providerID: .orangecloud,
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

    static let feeDocumentTypes: Set<String> = [
        "bills", "bill", "invoices", "invoice",
    ]

    static func stamp(_ doc: Document, calendar: Calendar) -> Date? {
        if let period = doc.period?.trimmingCharacters(in: .whitespacesAndNewlines), !period.isEmpty {
            if let parsed = BillingDateParser.parse(period, calendar: calendar) {
                return parsed
            }
            // YYYY-MM
            let parts = period.split(separator: "-")
            if parts.count >= 2,
               let y = Int(parts[0]), let m = Int(parts[1]),
               let date = calendar.date(from: DateComponents(year: y, month: m, day: 1)) {
                return date
            }
        }
        return doc.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? doc.updatedAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
    }

    private func resolveAccessToken(credential: Credential) async throws -> String {
        if let ready = credential.value(for: .apiToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !ready.isEmpty {
            return ready
        }
        if let ready = credential.value(for: .personalAccessToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !ready.isEmpty {
            return ready
        }
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .orangecloud)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .orangecloud)
        return try await ProviderOAuth.clientCredentialsToken(
            url: ProviderURL.https(host: Self.apiHost, path: Self.tokenPath),
            basic: (id: clientID, secret: clientSecret),
            form: ["grant_type": "client_credentials"],
            client: httpClient,
            providerID: .orangecloud
        )
    }

    private func loadDocuments(headers: [String: String]) async throws -> [Document] {
        var all: [Document] = []
        for type in ["bills", "invoices"] {
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/cloud/b2b/v1/documents",
                query: [URLQueryItem(name: "documentType", value: type)]
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .orangecloud
            )
            if let list = try? ProviderHTTP.decode([Document].self, from: data, providerID: .orangecloud) {
                all.append(contentsOf: list)
            } else if let wrapped = try? ProviderHTTP.decode(DocumentList.self, from: data, providerID: .orangecloud) {
                all.append(contentsOf: wrapped.documents ?? wrapped.data ?? [])
            }
        }
        if all.isEmpty {
            let url = ProviderURL.https(host: Self.apiHost, path: "/cloud/b2b/v1/documents")
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .orangecloud
            )
            if let list = try? ProviderHTTP.decode([Document].self, from: data, providerID: .orangecloud) {
                all = list
            } else {
                let wrapped = try ProviderHTTP.decode(DocumentList.self, from: data, providerID: .orangecloud)
                all = wrapped.documents ?? wrapped.data ?? []
            }
        }
        return all
    }

    struct DocumentList: Decodable, Sendable {
        var documents: [Document]?
        var data: [Document]?
    }

    struct Document: Decodable, Sendable {
        var id: String?
        var filename: String?
        var period: String?
        var createdAt: String?
        var updatedAt: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var documentType: String?
    }
}
