import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Frank Energie（NL）发票 GraphQL（`invoices(siteReference).allInvoices`）。
///
/// 社区客户端：https://github.com/HiDiHo01/python-frank-energie
/// Host：`frank-graphql-prod.graphcdn.app`。
/// 认证：Bearer `authToken`（凭据 `apiToken`/`apiKey`），或 `email` + `clientSecret`/`apiKey` 走 login mutation。
/// `accountID` = `siteReference`（如邮编+门牌 `"1000AA 101"`）。
/// 金额：`totalAmount`（EUR 主币）；日期：`startDate` / `invoiceDate`。
public struct FrankEnergieBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.frankenergie }
    public static let apiHost = "frank-graphql-prod.graphcdn.app"
    public static let currency = "EUR"
    public static let graphqlURL = ProviderURL.https(host: apiHost, path: "/")

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
        let site = try RequiredCredential.value(.accountID, in: credential, providerID: .frankenergie)
        let token = try await accessToken(credential: credential)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        try currencies.observe(Self.currency, providerID: .frankenergie)

        let payload = try await ProviderGraphQL.query(
            InvoicesData.self,
            url: Self.graphqlURL,
            query: Self.invoicesQuery,
            variables: ["siteReference": site],
            headers: headers,
            client: httpClient,
            providerID: .frankenergie
        )
        for inv in payload.invoices?.allInvoices ?? [] {
            let amount = inv.totalAmount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = inv.startDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.invoiceDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.periodDescription ?? inv.id ?? "invoice"
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
            providerID: .frankenergie
        )
        return Snapshot(
            providerID: .frankenergie,
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

    private func accessToken(credential: Credential) async throws -> String {
        if let ready = credential.value(for: .apiToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !ready.isEmpty
        {
            return ready
        }
        if let ready = credential.value(for: .apiKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !ready.isEmpty,
           credential.value(for: .email) == nil
        {
            return ready
        }
        let email = try RequiredCredential.value(.email, in: credential, providerID: .frankenergie)
        let password: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .frankenergie) {
            password = primary
        } else {
            password = try RequiredCredential.value(.apiKey, in: credential, providerID: .frankenergie)
        }
        let body = try JSONSerialization.data(
            withJSONObject: [
                "query": Self.loginMutation,
                "operationName": "Login",
                "variables": ["email": email, "password": password],
            ]
        )
        let data = try await ProviderHTTP.post(
            url: Self.graphqlURL,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body,
            client: httpClient,
            providerID: .frankenergie
        )
        let envelope = try ProviderHTTP.decode(LoginEnvelope.self, from: data, providerID: .frankenergie)
        if let message = envelope.errors?.compactMap(\.message).joined(separator: " "),
           !message.isEmpty
        {
            let lower = message.lowercased()
            if lower.contains("auth") || lower.contains("unauthor") || lower.contains("credential") {
                throw ProviderError.unauthorized(providerID: .frankenergie)
            }
        }
        guard let token = envelope.data?.login?.authToken?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !token.isEmpty
        else {
            throw ProviderError.unauthorized(providerID: .frankenergie)
        }
        return token
    }

    static let invoicesQuery = """
    query Invoices($siteReference: String!) {
      invoices(siteReference: $siteReference) {
        allInvoices {
          id
          invoiceDate
          startDate
          periodDescription
          totalAmount
        }
      }
    }
    """

    static let loginMutation = """
    mutation Login($email: String!, $password: String!) {
      login(email: $email, password: $password) {
        authToken
        refreshToken
      }
    }
    """

    struct InvoicesData: Decodable, Sendable {
        var invoices: InvoicesPayload?
    }

    struct InvoicesPayload: Decodable, Sendable {
        var allInvoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoiceDate: String?
        var startDate: String?
        var periodDescription: String?
        var totalAmount: FlexibleDecimal?
    }

    struct LoginEnvelope: Decodable, Sendable {
        var data: LoginData?
        var errors: [GraphQLError]?
    }

    struct LoginData: Decodable, Sendable {
        var login: LoginTokens?
    }

    struct LoginTokens: Decodable, Sendable {
        var authToken: String?
        var refreshToken: String?
    }

    struct GraphQLError: Decodable, Sendable {
        var message: String?
    }
}
