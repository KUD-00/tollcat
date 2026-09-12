import Foundation
import MeterCore

/// Postman 已付发票（`GET /accounts` → `GET /accounts/{accountId}/invoices?status=PAID`）。
///
/// 文档：Postman API。认证：`X-Api-Key`。
/// Host：`api.postman.com`（欧盟 `api.eu.postman.com`）。
/// 金额：`totalAmount.value` + `totalAmount.currency`。
public struct PostmanBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.postman }
    public static let apiHosts = ["api.postman.com", "api.eu.postman.com"]

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .postman)
        let preferredAccount = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let headers = [
            "X-Api-Key": apiKey,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let (host, accountId) = try await resolveAccount(
            preferredAccount: preferredAccount,
            headers: headers
        )
        let invoices = try await loadInvoices(host: host, accountId: accountId, headers: headers)
        for inv in invoices {
            let amount = inv.totalAmount?.value?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(inv.totalAmount?.currency, providerID: .postman)
            let stamp = inv.invoiceDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
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
            providerID: .postman
        )
        return Snapshot(
            providerID: .postman,
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

    private func resolveAccount(
        preferredAccount: String?,
        headers: [String: String]
    ) async throws -> (String, String) {
        if let preferred = preferredAccount, !preferred.isEmpty {
            // `eu:<id>` selects EU host.
            if preferred.lowercased().hasPrefix("eu:") {
                let id = String(preferred.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty else { throw ProviderError.missingCredential(providerID: .postman) }
                return ("api.eu.postman.com", id)
            }
            return ("api.postman.com", preferred)
        }
        var lastError: Error?
        for host in Self.apiHosts {
            do {
                let accounts = try await loadAccounts(host: host, headers: headers)
                if let id = accounts.first?.id ?? accounts.first?.accountId {
                    return (host, id)
                }
            } catch {
                lastError = error
            }
        }
        if let lastError { throw lastError }
        throw ProviderError.malformedResponse(providerID: .postman)
    }

    private func loadAccounts(host: String, headers: [String: String]) async throws -> [Account] {
        let url = ProviderURL.https(host: host, path: "/accounts")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .postman
        )
        if let list = try? ProviderHTTP.decode([Account].self, from: data, providerID: .postman) {
            return list
        }
        let envelope = try ProviderHTTP.decode(AccountsEnvelope.self, from: data, providerID: .postman)
        return envelope.accounts ?? envelope.data ?? []
    }

    private func loadInvoices(
        host: String,
        accountId: String,
        headers: [String: String]
    ) async throws -> [Invoice] {
        let url = ProviderURL.https(
            host: host,
            path: "/accounts/\(accountId)/invoices",
            query: [URLQueryItem(name: "status", value: "PAID")]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .postman
        )
        if let list = try? ProviderHTTP.decode([Invoice].self, from: data, providerID: .postman) {
            return list
        }
        let envelope = try ProviderHTTP.decode(InvoicesEnvelope.self, from: data, providerID: .postman)
        return envelope.invoices ?? envelope.data ?? []
    }

    struct AccountsEnvelope: Decodable, Sendable {
        var accounts: [Account]?
        var data: [Account]?
    }

    struct Account: Decodable, Sendable {
        var id: String?
        var accountId: String?
    }

    struct InvoicesEnvelope: Decodable, Sendable {
        var invoices: [Invoice]?
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var invoiceNumber: String?
        var invoiceDate: String?
        var createdAt: String?
        var totalAmount: MoneyAmount?
    }

    struct MoneyAmount: Decodable, Sendable {
        var value: FlexibleDecimal?
        var currency: String?
    }
}
