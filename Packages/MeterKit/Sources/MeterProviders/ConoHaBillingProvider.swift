import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// ConoHa 请求データ（`GET /v1/{tenant_id}/billing-invoices`）。
///
/// 文档：https://doc.conoha.jp/reference/api-vps2/api-account-vps2/account-billing-invoices-list-v2/
/// 认证：Identity `POST /v2.0/tokens`（VPS2）或 `/v3/auth/tokens`（c3* 区），
/// 再 `X-Auth-Token`。
/// Host：`identity.{region}.conoha.io` / `account.{region}.conoha.io`。
/// 金额：`bill_plas_tax` / `bill_plus_tax`（税込 JPY）。
/// 凭据：`clientID`/`email`=API 用户名，`clientSecret`/`apiToken`=密码，
/// `tenantID`=テナント ID，可选 `accountID`=region（默认 `tyo1`）。
public struct ConoHaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.conoha }
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
        if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .conoha) {
            username = primary
        } else if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .conoha) {
            username = primary
        } else {
            username = try RequiredCredential.value(.accessKeyID, in: credential, providerID: .conoha)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .conoha) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .conoha) {
            password = primary
        } else {
            password = try RequiredCredential.value(.secretAccessKey, in: credential, providerID: .conoha)
        }
        let tenantID = try RequiredCredential.value(.tenantID, in: credential, providerID: .conoha)
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
        try currencies.observe("JPY", providerID: .conoha)

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
            providerID: .conoha
        )
        return Snapshot(
            providerID: .conoha,
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
        if region.lowercased().hasPrefix("c3") {
            return try await authenticateV3(
                username: username, password: password, tenantID: tenantID, region: region
            )
        }
        return try await authenticateV2(
            username: username, password: password, tenantID: tenantID, region: region
        )
    }

    private func authenticateV2(
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
            providerID: .conoha
        )
        let envelope = try ProviderHTTP.decode(V2TokenEnvelope.self, from: data, providerID: .conoha)
        guard let token = envelope.access?.token?.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: .conoha)
        }
        return token
    }

    private func authenticateV3(
        username: String,
        password: String,
        tenantID: String,
        region: String
    ) async throws -> String {
        let body = try JSONSerialization.data(
            withJSONObject: [
                "auth": [
                    "identity": [
                        "methods": ["password"],
                        "password": [
                            "user": [
                                "name": username,
                                "password": password,
                                "domain": ["id": "default"],
                            ]
                        ],
                    ],
                    "scope": [
                        "project": ["id": tenantID]
                    ],
                ]
            ]
        )
        var request = URLRequest(url: Self.identityURL(region: region, path: "/v3/auth/tokens"))
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let respData: Data
        let http: HTTPURLResponse
        do {
            (respData, http) = try await httpClient.send(request)
        } catch {
            throw ProviderError.networkFailure(providerID: .conoha)
        }
        if let mapped = ProviderError.fromHTTPStatus(http.statusCode, providerID: .conoha) {
            throw mapped
        }
        if let token = http.value(forHTTPHeaderField: "X-Subject-Token"), !token.isEmpty {
            return token
        }
        // Some gateways lowercase
        if let token = http.value(forHTTPHeaderField: "x-subject-token"), !token.isEmpty {
            return token
        }
        _ = respData
        throw ProviderError.unauthorized(providerID: .conoha)
    }

    private func loadInvoices(
        tenantID: String,
        region: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let url = ProviderURL.https(
            host: "account.\(region).conoha.io",
            path: "/v1/\(tenantID)/billing-invoices",
            query: [URLQueryItem(name: "limit", value: "100")]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .conoha
        )
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .conoha)
        return envelope.billingInvoices ?? []
    }

    static func identityURL(region: String, path: String) -> URL {
        ProviderURL.https(host: "identity.\(region).conoha.io", path: path)
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
