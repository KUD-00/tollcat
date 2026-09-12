import Foundation
import MeterCore

/// DeepSeek 预充值余额。
///
/// 文档：`GET /user/balance`
/// 认证：普通 API key。`balance_infos` 几乎总会同时给 CNY 和 USD 两个槽；
/// 空着的美元槽是 `"0.00"`，不是「这是美元户」。各槽原币进 `wallets`，
/// `balanceUSD` 是折美元合计。表里没有的币种仍然拒。
public struct DeepSeekBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.deepseek }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .deepseek)
        let data = try await ProviderHTTP.get(
            url: Self.balanceURL,
            headers: [
                "Authorization": "Bearer \(apiKey)",
            ],
            client: httpClient,
            providerID: .deepseek
        )
        let payload = try ProviderHTTP.decode(Balance.self, from: data, providerID: .deepseek)
        return try snapshot(from: payload.balance_infos ?? [], now: now)
    }

    private func snapshot(from infos: [Info], now: Date) throws -> Snapshot {
        var wallets: [ConvertedAmount] = []
        for info in infos {
            guard let total = info.total_balance?.value else { continue }
            if let wallet = try wallet(total: total, currency: info.currency) {
                wallets.append(wallet)
            }
        }
        guard !wallets.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .deepseek)
        }
        var sum = Decimal(0)
        for wallet in wallets {
            sum += wallet.usd
        }
        return PrepaidSnapshot.make(
            providerID: .deepseek,
            now: now,
            calendar: calendar,
            balance: Money(usd: sum),
            converted: Self.ledgerConverted(wallets: wallets, sum: sum),
            wallets: wallets
        )
    }

    /// 落库会把 `converted.usd` 写成 `balanceUSD`。两槽都有钱时不能再用这一条。
    static func ledgerConverted(wallets: [ConvertedAmount], sum: Decimal) -> ConvertedAmount? {
        let converted = wallets.filter { $0.isConverted && $0.usd != 0 }
        guard converted.count == 1, converted[0].usd == sum else { return nil }
        return converted[0]
    }

    private func wallet(total: Decimal, currency: String?) throws -> ConvertedAmount? {
        if isUSD(currency) {
            return ConvertedAmount(
                currency: ExchangeRates.usdCode,
                amount: total,
                usdPerUnit: 1,
                usd: total
            )
        }
        if let converted = rateSource.current.toUSD(total, from: currency), converted.isConverted {
            return converted
        }
        if total == 0 {
            return nil
        }
        throw ProviderError.unsupportedCurrency(providerID: .deepseek)
    }

    static let balanceURL = URL(string: "https://api.deepseek.com/user/balance")!

    private func isUSD(_ raw: String?) -> Bool {
        guard let raw else { return false }
        return raw.compare("USD", options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    struct Balance: Decodable, Sendable {
        var is_available: Bool?
        var balance_infos: [Info]?
    }

    struct Info: Decodable, Sendable {
        var currency: String?
        var total_balance: FlexibleDecimal?
        var granted_balance: FlexibleDecimal?
        var topped_up_balance: FlexibleDecimal?
    }
}
