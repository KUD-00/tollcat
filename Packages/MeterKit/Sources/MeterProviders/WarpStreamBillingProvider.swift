import Foundation
import MeterCore

/// WarpStream 本月 pending invoice 合计（`total` + line `unit_price`/`quantity`/`total`，USD）。
///
/// 文档：
/// - `POST /api/v1/billing/invoices/get_pending_invoice`
/// - `POST /api/v1/billing/invoices/get_past_invoice`（历史）
/// 认证：`warpstream-api-key: <API key>`。
public struct WarpStreamBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.warpstream }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .warpstream)
        let headers = [
            "warpstream-api-key": apiKey,
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var lines = SpendLineAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0

        let pending = try await loadInvoice(url: Self.pendingURL, headers: headers)
        currentTotal += pending.total?.value ?? Self.sumTenants(pending)
        for line in Self.flattenCharges(pending) {
            lines.add(
                SpendLine(
                    category: line.product ?? "charge",
                    label: line.label,
                    amountUSD: Money(usd: line.total)
                )
            )
        }

        if horizon == .availableHistory {
            // Past invoices: empty body returns available history when supported.
            if let past = try? await loadInvoice(url: Self.pastURL, headers: headers) {
                let stamp = past.date_from.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? past.date_to.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let amount = past.total?.value ?? Self.sumTenants(past)
                if amount != 0, !current.contains(stamp) {
                    daily.addPastMonth(
                        start: stamp,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }

        return Snapshot(
            providerID: .warpstream,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    private func loadInvoice(url: URL, headers: [String: String]) async throws -> Invoice {
        let data = try await ProviderHTTP.post(
            url: url,
            headers: headers,
            body: Data("{}".utf8),
            client: httpClient,
            providerID: .warpstream
        )
        return try ProviderHTTP.decode(Invoice.self, from: data, providerID: .warpstream)
    }

    static let pendingURL = ProviderURL.https(
        host: "api.warpstream.com",
        path: "/api/v1/billing/invoices/get_pending_invoice"
    )
    static let pastURL = ProviderURL.https(
        host: "api.warpstream.com",
        path: "/api/v1/billing/invoices/get_past_invoice"
    )

    static func sumTenants(_ invoice: Invoice) -> Decimal {
        var total: Decimal = 0
        for tenant in invoice.tenants ?? [] {
            total += tenant.total?.value ?? 0
        }
        for charge in invoice.account_charges ?? [] {
            total += charge.total?.value ?? 0
        }
        return total
    }

    static func flattenCharges(_ invoice: Invoice) -> [FlatCharge] {
        var rows: [FlatCharge] = []
        for tenant in invoice.tenants ?? [] {
            for workspace in tenant.workspaces ?? [] {
                let ws = workspace.workspace_name ?? workspace.workspace_id ?? "workspace"
                for cluster in workspace.clusters ?? [] {
                    let cn = cluster.cluster_name ?? cluster.virtual_cluster_id ?? "cluster"
                    for charge in cluster.charges ?? [] {
                        let amount = charge.total?.value ?? 0
                        guard amount != 0 else { continue }
                        rows.append(
                            FlatCharge(
                                product: charge.product,
                                label: "\(ws)/\(cn): \(charge.product ?? "charge")",
                                total: amount
                            )
                        )
                    }
                }
            }
        }
        for charge in invoice.account_charges ?? [] {
            let amount = charge.total?.value ?? 0
            guard amount != 0 else { continue }
            rows.append(
                FlatCharge(
                    product: charge.product,
                    label: charge.product ?? "account",
                    total: amount
                )
            )
        }
        return rows
    }

    struct FlatCharge {
        var product: String?
        var label: String
        var total: Decimal
    }

    struct Invoice: Decodable, Sendable {
        var date_from: String?
        var date_to: String?
        var tenants: [Tenant]?
        var account_charges: [Charge]?
        var total: FlexibleDecimal?
    }

    struct Tenant: Decodable, Sendable {
        var tenant_id: String?
        var workspaces: [Workspace]?
        var total: FlexibleDecimal?
    }

    struct Workspace: Decodable, Sendable {
        var workspace_id: String?
        var workspace_name: String?
        var clusters: [Cluster]?
        var total: FlexibleDecimal?
    }

    struct Cluster: Decodable, Sendable {
        var virtual_cluster_id: String?
        var cluster_name: String?
        var charges: [Charge]?
        var total: FlexibleDecimal?
    }

    struct Charge: Decodable, Sendable {
        var product: String?
        var unit_price: FlexibleDecimal?
        var quantity: FlexibleDecimal?
        var total: FlexibleDecimal?
    }
}
