import Foundation
import MeterCore

/// Rackspace Billing API v2 本账期预估费用（`GET /v2/accounts/{ran}/estimated_charges`）。
///
/// 文档：https://docs.rackspace.com/reference/billing-apiguide-v2
/// 认证：`apiToken`（现成 X-Auth-Token）或 Identity `POST /v2.0/tokens`（`email`=username + `apiKey`）→ `X-Auth-Token`；`accountID` = RAN。
/// 金额：`currency` + `chargeSubTotal`；明细 `estimatedCharge[].amount`。
/// 可选：`/invoices/latest` 的 `invoiceTotal` 作历史对照（本适配器以 estimated_charges 为准）。
public struct RackspaceBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.rackspace }
    public static let identityHost = "identity.api.rackspacecloud.com"
    public static let billingHost = "billing.api.rackspacecloud.com"

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
        let ran = try RequiredCredential.value(.accountID, in: credential, providerID: .rackspace)
        let token: String
        if let ready = credential.value(for: .apiToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !ready.isEmpty {
            token = ready
        } else {
            let username = try RequiredCredential.value(.email, in: credential, providerID: .rackspace)
            let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .rackspace)
            token = try await authenticate(username: username, apiKey: apiKey)
        }
        let headers = [
            "X-Auth-Token": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()

        let url = ProviderURL.https(
            host: Self.billingHost,
            path: "/v2/accounts/\(ran)/estimated_charges"
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .rackspace
        )
        let envelope = try ProviderHTTP.decode(EstimatedEnvelope.self, from: data, providerID: .rackspace)
        let block = envelope.estimatedCharges
        try currencies.observe(block?.currency ?? "USD", providerID: .rackspace)

        var total = block?.chargeSubTotal?.value
            ?? block?.chargeTotal?.value
            ?? 0
        if total == 0 {
            for row in block?.estimatedCharge ?? [] {
                total += row.amount?.value ?? 0
            }
        }

        let periodStart = block?.currentBillingPeriodStartDate
            .flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? current.start
        let periodEnd = block?.currentBillingPeriodEndDate
            .flatMap { BillingDateParser.parse($0, calendar: calendar) }
            ?? current.endInclusive

        if total != 0 {
            daily.add(day: periodStart, amount: Money(usd: total))
        }
        for row in block?.estimatedCharge ?? [] {
            let amount = row.amount?.value ?? 0
            guard amount != 0 else { continue }
            let label = [
                row.offeringCode,
                row.chargeType,
                row.chargeDescription,
            ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "charge"
            lines.add(
                SpendLine(
                    category: row.category ?? row.chargeType ?? "usage",
                    label: label,
                    amountUSD: Money(usd: amount)
                )
            )
        }

        // Optional latest invoice for availableHistory (does not replace current estimate).
        if horizon == .availableHistory {
            if let invoice = try? await loadLatestInvoice(ran: ran, headers: headers) {
                try currencies.observe(invoice.currency ?? block?.currency, providerID: .rackspace)
                let invTotal = invoice.invoiceTotal?.value ?? invoice.amountDue?.value ?? 0
                if invTotal != 0,
                   let stamp = invoice.invoiceDate.flatMap({ BillingDateParser.parse($0, calendar: calendar) })
                    ?? invoice.periodEnd.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
                    daily.addPastMonth(
                        start: stamp,
                        amount: Money(usd: invTotal),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        let converted = try currencies.convert(
            total,
            rates: rateSource.current,
            providerID: .rackspace
        )
        return Snapshot(
            providerID: .rackspace,
            kind: .usage,
            fetchedAt: now,
            periodStart: periodStart,
            periodEnd: periodEnd,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func authenticate(username: String, apiKey: String) async throws -> String {
        let url = ProviderURL.https(host: Self.identityHost, path: "/v2.0/tokens")
        let bodyObj: [String: Any] = [
            "auth": [
                "RAX-KSKEY:apiKeyCredentials": [
                    "username": username,
                    "apiKey": apiKey,
                ]
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: bodyObj)
        let data = try await ProviderHTTP.post(
            url: url,
            headers: ["Content-Type": "application/json", "Accept": "application/json"],
            body: body,
            client: httpClient,
            providerID: .rackspace
        )
        let auth = try ProviderHTTP.decode(AuthResponse.self, from: data, providerID: .rackspace)
        guard let token = auth.access?.token?.id?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .rackspace)
        }
        return token
    }

    private func loadLatestInvoice(ran: String, headers: [String: String]) async throws -> Invoice {
        let url = ProviderURL.https(
            host: Self.billingHost,
            path: "/v2/accounts/\(ran)/invoices/latest"
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .rackspace
        )
        let wrapped = try ProviderHTTP.decode(InvoiceEnvelope.self, from: data, providerID: .rackspace)
        return wrapped.invoice ?? Invoice(
            invoiceTotal: nil,
            amountDue: nil,
            currency: nil,
            invoiceDate: nil,
            periodEnd: nil
        )
    }

    struct AuthResponse: Decodable, Sendable {
        var access: Access?
        struct Access: Decodable, Sendable {
            var token: Token?
        }
        struct Token: Decodable, Sendable {
            var id: String?
        }
    }

    struct EstimatedEnvelope: Decodable, Sendable {
        var estimatedCharges: EstimatedCharges?
    }

    struct EstimatedCharges: Decodable, Sendable {
        var currency: String?
        var chargeSubTotal: FlexibleDecimal?
        var chargeTotal: FlexibleDecimal?
        var discountTotal: FlexibleDecimal?
        var currentBillingPeriodStartDate: String?
        var currentBillingPeriodEndDate: String?
        var estimatedCharge: [EstimatedLine]?
    }

    struct EstimatedLine: Decodable, Sendable {
        var offeringCode: String?
        var amount: FlexibleDecimal?
        var category: String?
        var chargeType: String?
        var chargeDescription: String?
    }

    struct InvoiceEnvelope: Decodable, Sendable {
        var invoice: Invoice?
    }

    struct Invoice: Decodable, Sendable {
        var invoiceTotal: FlexibleDecimal?
        var amountDue: FlexibleDecimal?
        var currency: String?
        var invoiceDate: String?
        var periodEnd: String?
    }
}
