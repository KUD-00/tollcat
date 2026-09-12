import Foundation
import MeterCore

/// DataPacket 账户发票（GraphQL `invoices`）。
///
/// 文档：https://api.datapacket.com/
/// 认证：`Authorization: Bearer <API token>`。
/// Host：`api.datapacket.com`。
/// 金额：`total`（含税）+ `currency`。按 `createdAt` 归入本月；跳过 `DRAFT`。
public struct DataPacketBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.datapacket }
    public static let apiHost = "api.datapacket.com"
    static let maxPages = 20
    static let pageSize = 50

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .datapacket) {
            token = primary
        } else if let alt = try? RequiredCredential.value(.apiToken, in: credential, providerID: .datapacket) {
            token = alt
        } else {
            token = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .datapacket)
        }
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

        var pageIndex = 0
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let batch = try await loadInvoices(pageIndex: pageIndex, headers: headers)
            if batch.entries.isEmpty { break }
            for inv in batch.entries {
                if let kind = inv.invoiceType?.uppercased(), kind == "DRAFT" { continue }
                let amount = inv.total?.value ?? 0
                guard amount > 0 else { continue }
                try currencies.observe(inv.currency, providerID: .datapacket)
                let stamp = inv.createdAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? inv.dueDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.invoiceNumber ?? "invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: inv.invoiceType ?? "invoice",
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
            if batch.isLastPage == true { break }
            guard let next = batch.nextPageIndex else { break }
            pageIndex = next
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .datapacket
        )
        return Snapshot(
            providerID: .datapacket,
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

    private func loadInvoices(pageIndex: Int, headers: [String: String]) async throws -> Page {
        let query = """
        query {
          invoices(input: { pageIndex: \(pageIndex), pageSize: \(Self.pageSize) }) {
            isLastPage
            nextPageIndex
            entries {
              invoiceNumber
              total
              currency
              createdAt
              dueDate
              invoiceType
            }
          }
        }
        """
        let body = try JSONSerialization.data(withJSONObject: ["query": query])
        let data = try await ProviderHTTP.post(
            url: Self.graphqlURL,
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .datapacket
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .datapacket)
        if let page = envelope.data?.invoices {
            return page
        }
        let combined = (envelope.errors ?? []).compactMap(\.message).joined(separator: " ").lowercased()
        if combined.contains("unauthor") || combined.contains("not authenticated") {
            throw ProviderError.unauthorized(providerID: .datapacket)
        }
        if combined.contains("forbidden") || combined.contains("not authorized") {
            throw ProviderError.forbidden(providerID: .datapacket)
        }
        throw ProviderError.malformedResponse(providerID: .datapacket)
    }

    static let graphqlURL = URL(string: "https://api.datapacket.com/v0/graphql")!

    struct Envelope: Decodable, Sendable {
        var data: DataPayload?
        var errors: [GraphQLError]?
    }
    struct DataPayload: Decodable, Sendable {
        var invoices: Page?
    }
    struct Page: Decodable, Sendable {
        var isLastPage: Bool?
        var nextPageIndex: Int?
        var entries: [Invoice] = []
    }
    struct Invoice: Decodable, Sendable {
        var invoiceNumber: String?
        var total: FlexibleDecimal?
        var currency: String?
        var createdAt: String?
        var dueDate: String?
        var invoiceType: String?
    }
    struct GraphQLError: Decodable, Sendable {
        var message: String?
    }
}
