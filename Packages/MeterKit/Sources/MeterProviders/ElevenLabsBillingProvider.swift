import Foundation
import MeterCore

/// ElevenLabs 订阅超量与未结发票。
///
/// 文档：`GET /v1/user/subscription`
/// 认证：`xi-api-key`。
///
/// 优先：`current_overage.amount`/`currency`；再加 `open_invoices[].amount_due_cents`。
/// 都没有时才回落到免费额度比例。月费座位不摊。
public struct ElevenLabsBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.elevenlabs }

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
        let now = now()
        var currency = CurrencyAccumulator()
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .elevenlabs)
        let data = try await ProviderHTTP.get(
            url: Self.subscriptionURL,
            headers: [
                "xi-api-key": apiKey,
            ],
            client: httpClient,
            providerID: .elevenlabs
        )
        let payload = try ProviderHTTP.decode(Subscription.self, from: data, providerID: .elevenlabs)
        try currency.observe(payload.current_overage?.currency, providerID: .elevenlabs)
        try currency.observe(payload.currency, providerID: .elevenlabs)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let overage = payload.current_overage?.amount?.value ?? 0
        let invoiceCents = (payload.open_invoices ?? []).reduce(Int64(0)) { $0 + ($1.amount_due_cents ?? 0) }
        let invoiceUSD = Decimal(invoiceCents) / 100
        let spend = overage + invoiceUSD

        if spend > 0 {
            return try Snapshot(
                providerID: .elevenlabs,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive,
                currentSpendUSD: Money(usd: spend)
            ).convertedToUSD(using: currency, rates: rateSource.current)
        }

        let used = payload.character_count ?? 0
        let limit = payload.character_limit ?? 0
        let ratio: Double
        if limit > 0 {
            ratio = min(1, Double(used) / Double(limit))
        } else {
            ratio = 0
        }
        return try Snapshot(
            providerID: .elevenlabs,
            kind: .freeTier,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: .zero,
            freeQuotaUsedRatio: ratio
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    static let subscriptionURL = URL(string: "https://api.elevenlabs.io/v1/user/subscription")!

    struct Subscription: Decodable, Sendable {
        var character_count: Int?
        var character_limit: Int?
        var currency: String?
        var current_overage: Overage?
        var open_invoices: [OpenInvoice]?
    }

    struct Overage: Decodable, Sendable {
        var amount: FlexibleDecimal?
        var currency: String?
    }

    struct OpenInvoice: Decodable, Sendable {
        var amount_due_cents: Int64?
    }
}
