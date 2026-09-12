import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Z.com Cloud 請求データ（`GET /v1/{tenant_id}/billing-invoices`）。
///
/// 文档：https://cloud.z.com/th/en/cloud/docs/account-billing-invoices-list.html
/// 认证：Identity `POST /v2.0/tokens`，再 `X-Auth-Token`。
/// Host：`identity.{region}.cloud.z.com` / `account.{region}.cloud.z.com`。
/// 金额：`bill_plas_tax` / `bill_plus_tax`（税込，默认 JPY）。
/// 凭据：`clientID`/`email`=API 用户名，`clientSecret`/`apiToken`=密码，
/// `tenantID`=テナント ID，可选 `accountID`=region（默认 `tyo1`）。
public struct ZComCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.zcomcloud }
    public static let defaultRegion = "tyo1"

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
        let username: String
        if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .zcomcloud) {
            username = primary
        } else if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .zcomcloud) {
            username = primary
        } else {
            username = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .zcomcloud)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .zcomcloud) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .zcomcloud) {
            password = primary
        } else {
            password = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .zcomcloud)
        }
        let tenantID = try RequiredCredential.value(.tenantID, in: credential, providerID: .zcomcloud)
        let regionRaw = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let region = (regionRaw?.isEmpty == false) ? regionRaw! : Self.defaultRegion
        let token = try await authenticate(
            username: username, password: password, tenantID: tenantID, region: region
        )
        let headers = [
            "X-Auth-Token": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe("JPY", providerID: .zcomcloud)

        let invoices = try await loadInvoices(
            tenantID: tenantID, region: region, headers: headers
        )
        for inv in invoices {
            let amount = inv.billPlasTax?.value ?? inv.billPlusTax?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = inv.invoiceDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoiceID.map(String.init) ?? "invoice"
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
            providerID: .zcomcloud
        )
        return Snapshot(
            providerID: .zcomcloud,
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

    private func authenticate(
        username: String,
        password: String,
        tenantID: String,
        region: String
    ) async throws -> String {
        let body = try JSONSerialization.data(
            withJSONObject: [
                "auth": [
                    "passwordCredentials": [
                        "username": username,
                        "password": password,
                    ],
                    "tenantId": tenantID,
                ]
            ]
        )
        let data = try await ProviderHTTP.post(
            url: Self.identityURL(region: region, path: "/v2.0/tokens"),
            headers: ["Content-Type": "application/json"],
            body: body,
            client: httpClient,
            providerID: .zcomcloud
        )
        let envelope = try ProviderHTTP.decode(V2TokenEnvelope.self, from: data, providerID: .zcomcloud)
        guard let token = envelope.access?.token?.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: .zcomcloud)
        }
        return token
    }

    private func loadInvoices(
        tenantID: String,
        region: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let url = ProviderURL.https(
            host: "account.\(region).cloud.z.com",
            path: "/v1/\(tenantID)/billing-invoices",
            query: [URLQueryItem(name: "limit", value: "100")]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .zcomcloud
        )
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .zcomcloud)
        return envelope.billingInvoices ?? []
    }

    static func identityURL(region: String, path: String) -> URL {
        ProviderURL.https(host: "identity.\(region).cloud.z.com", path: path)
    }

    struct V2TokenEnvelope: Decodable, Sendable {
        var access: V2Access?
    }

    struct V2Access: Decodable, Sendable {
        var token: V2Token?
    }

    struct V2Token: Decodable, Sendable {
        var id: String?
    }

    struct InvoiceList: Decodable, Sendable {
        var billingInvoices: [Invoice]?

        enum CodingKeys: String, CodingKey {
            case billingInvoices = "billing_invoices"
        }
    }

    struct Invoice: Decodable, Sendable {
        var invoiceID: Int?
        var invoiceDate: String?
        var dueDate: String?
        var billPlasTax: FlexibleDecimal?
        var billPlusTax: FlexibleDecimal?
        var paymentMethodType: String?

        enum CodingKeys: String, CodingKey {
            case invoiceID = "invoice_id"
            case invoiceDate = "invoice_date"
            case dueDate = "due_date"
            case billPlasTax = "bill_plas_tax"
            case billPlusTax = "bill_plus_tax"
            case paymentMethodType = "payment_method_type"
        }
    }
}
