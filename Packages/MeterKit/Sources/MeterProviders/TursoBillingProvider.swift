import Foundation
import MeterCore

/// Turso 当期未出账发票。
///
/// 文档：`GET /v1/organizations/{organizationSlug}/invoices?type=upcoming`
/// 认证：`Authorization: Bearer <API token>`
///
/// `amount_due` 是美元字符串。没有 upcoming 时返回没读到，不要写成 $0。
public struct TursoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.turso }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .turso)
        let org = try RequiredCredential.value(.accountID, in: credential, providerID: .turso)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL(organization: org),
            headers: [
                "Authorization": "Bearer \(token)",
            ],
            client: httpClient,
            providerID: .turso
        )
        let payload = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .turso)
        guard let invoice = (payload.invoices ?? []).first else {
            return Snapshot(
                providerID: .turso,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive
            )
        }
        return Snapshot(
            providerID: .turso,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: invoice.amount_due?.value ?? 0)
        )
    }

    static func invoicesURL(organization: String) -> URL {
        ProviderURL.https(
            host: "api.turso.tech",
            path: "/v1/organizations/\(organization)/invoices",
            query: [URLQueryItem(name: "type", value: "upcoming")]
        )
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoice_number: String?
        var amount_due: FlexibleDecimal?
        var due_date: String?
    }
}
