import Foundation
import MeterCore

/// Remote.com 平台/服务费（`GET /v1/billing-documents` + 可选 `/{id}/breakdown`）。
///
/// 文档：https://developer.remote.com/docs/pull-eor-cost-breakdown
/// 认证：`Authorization: Bearer <company API token>`（`invoices:read`）。
/// 优先服务费单据：`peo_management_fees` / `supplemental_service_invoice`；
/// 其余单据只累加 breakdown 里 service/management/platform fee 行，跳过工资 funding。
/// 金额为整数分（cents）+ `billing_document_currency` / `invoice_currency`。
public struct RemoteBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.remote }
    public static let apiHost = "gateway.remote.com"
    static let pageSize = 50
    static let maxPages = 40
    static let maxBreakdownFetches = 30

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
        let token = try RequiredCredential.value(.apiKey, in: credential, providerID: .remote)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let documents = try await loadDocuments(headers: headers)
        var breakdownBudget = Self.maxBreakdownFetches

        for doc in documents {
            let docType = (doc.billing_document_type ?? doc.type ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if Self.payrollFundingTypes.contains(docType) {
                // Still allow fee lines via breakdown; do not take whole-document total.
            }
            let stamp = Self.stamp(doc, calendar: calendar) ?? current.start
            let currency = (doc.billing_document_currency ?? doc.currency)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            if Self.feeDocumentTypes.contains(docType) {
                try currencies.observe(currency, providerID: .remote)
                let cents = doc.total?.value ?? doc.amount?.value ?? 0
                let amount = cents / 100
                guard amount != 0 else { continue }
                let label = doc.number ?? doc.id ?? docType
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: docType,
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
                continue
            }

            guard let id = doc.id, !id.isEmpty, breakdownBudget > 0 else { continue }
            breakdownBudget -= 1
            guard let items = try? await loadBreakdown(id: id, headers: headers) else { continue }
            for item in items {
                guard Self.isFeeLine(item) else { continue }
                let lineCurrency = (item.invoice_currency ?? currency)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                try? currencies.observe(lineCurrency, providerID: .remote)
                let cents = item.invoice_amount?.value ?? 0
                let amount = cents / 100
                guard amount != 0 else { continue }
                let label = [
                    item.type,
                    item.description,
                    doc.number,
                    id,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "fee"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: item.type ?? "fee",
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
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .remote
        )
        return Snapshot(
            providerID: .remote,
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

    /// Whole-document totals are platform/service fees (not payroll funding).
    static let feeDocumentTypes: Set<String> = [
        "peo_management_fees",
        "supplemental_service_invoice",
    ]

    /// Payroll pass-through / funding — never take document total; fee lines only via breakdown.
    static let payrollFundingTypes: Set<String> = [
        "peo_funding_payrolls",
        "prefunding_invoice",
        "reconciliation_invoice",
        "reconciliation_credit_note",
    ]

    static func isFeeLine(_ item: BreakdownItem) -> Bool {
        let blob = [item.type, item.description]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        guard !blob.isEmpty else { return false }
        let needles = [
            "service fee", "management fee", "platform fee",
            "peo management", "eor service", "equity management",
        ]
        return needles.contains { blob.contains($0) }
    }

    static func stamp(_ doc: BillingDocument, calendar: Calendar) -> Date? {
        let raw = doc.issued_at ?? doc.created_at ?? doc.period_end ?? doc.period_start
        return raw.flatMap { BillingDateParser.parse($0, calendar: calendar) }
    }

    private func loadDocuments(headers: [String: String]) async throws -> [BillingDocument] {
        var all: [BillingDocument] = []
        var page = 1
        for _ in 0..<Self.maxPages {
            let url = ProviderURL.https(
                host: Self.apiHost,
                path: "/v1/billing-documents",
                query: [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "page_size", value: String(Self.pageSize)),
                ]
            )
            let data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .remote
            )
            let payload = try ProviderHTTP.decode(DocumentList.self, from: data, providerID: .remote)
            let rows = payload.data ?? payload.billing_documents ?? []
            all.append(contentsOf: rows)
            if rows.isEmpty || rows.count < Self.pageSize { break }
            page += 1
        }
        return all
    }

    private func loadBreakdown(id: String, headers: [String: String]) async throws -> [BreakdownItem] {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/billing-documents/\(id)/breakdown"
        )
        let data = try await ProviderHTTP.get(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .remote
        )
        let payload = try ProviderHTTP.decode(BreakdownList.self, from: data, providerID: .remote)
        return payload.data ?? payload.breakdown ?? []
    }

    struct DocumentList: Decodable, Sendable {
        var data: [BillingDocument]?
        var billing_documents: [BillingDocument]?
    }

    struct BillingDocument: Decodable, Sendable {
        var id: String?
        var number: String?
        var type: String?
        var billing_document_type: String?
        var total: FlexibleDecimal?
        var amount: FlexibleDecimal?
        var billing_document_currency: String?
        var currency: String?
        var issued_at: String?
        var created_at: String?
        var period_start: String?
        var period_end: String?
    }

    struct BreakdownList: Decodable, Sendable {
        var data: [BreakdownItem]?
        var breakdown: [BreakdownItem]?
    }

    struct BreakdownItem: Decodable, Sendable {
        var type: String?
        var description: String?
        var invoice_amount: FlexibleDecimal?
        var invoice_currency: String?
    }
}
