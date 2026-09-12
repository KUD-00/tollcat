import Foundation

/// 接入说明、套餐和公告。
///
/// **安全红线（SPEC 第 07 节）：** 目录只带文字和数字，绝不能携带任何 URL
/// 或端点。远程可改的跳转地址等于钓鱼登录页。控制台地址、API base URL
/// 全部在 `MeterProviders` 的 descriptor 里编译进 App。
///
/// 文案：中文是规范字段。`en` / `ja` 是 overlay，老 App 忽略未知键，
/// 所以不升 `schemaVersion`。打包目录必须列齐；展示走 `localized(for:)`。
public struct Catalog: Hashable, Sendable {
    public var schemaVersion: Int
    /// 这份目录写出去的时刻，精确到秒。只写日期的 `T00:00:00Z` 同一天内无法区分新旧。
    public var updatedAt: Date
    public var guides: [ProviderID: SetupGuide]
    public var plans: [SubscriptionPlan]
    public var notices: [Notice]
    /// 汇率。只有数字，所以它能进目录而不违反那条「不许带 URL」的红线。
    /// 空表示只认美元，行为和没有这一段之前一样。
    public var exchangeRates: ExchangeRates

    public init(
        schemaVersion: Int,
        updatedAt: Date,
        guides: [ProviderID: SetupGuide],
        plans: [SubscriptionPlan],
        notices: [Notice],
        exchangeRates: ExchangeRates = .usdOnly
    ) {
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.guides = guides
        self.plans = plans
        self.notices = notices
        self.exchangeRates = exchangeRates
    }

    /// 给界面用的这一份：当前语言填进规范字段，overlay 剥掉。缺列回落中文。
    public func localized(for language: CatalogLanguage) -> Catalog {
        Catalog(
            schemaVersion: schemaVersion,
            updatedAt: updatedAt,
            guides: guides.mapValues { $0.localized(for: language) },
            plans: plans.map { $0.localized(for: language) },
            notices: notices.map { $0.localized(for: language) },
            exchangeRates: exchangeRates
        )
    }

}

extension Catalog: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case updatedAt
        case guides
        case plans
        case notices
        case exchangeRates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        let keyedGuides = try container.decodeIfPresent([String: SetupGuide].self, forKey: .guides) ?? [:]
        guides = Dictionary(
            uniqueKeysWithValues: keyedGuides.map { (ProviderID($0.key), $0.value) }
        )
        plans = try container.decodeIfPresent([SubscriptionPlan].self, forKey: .plans) ?? []
        notices = try container.decodeIfPresent([Notice].self, forKey: .notices) ?? []
        // 金额一律走十进制字符串。汇率过 Double 会把 7.1043 变成 7.104299999…
        let rawRates = try container
            .decodeIfPresent([String: String].self, forKey: .exchangeRates) ?? [:]
        exchangeRates = ExchangeRates(
            usdPerUnit: rawRates.compactMapValues {
                Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX"))
            }
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(updatedAt, forKey: .updatedAt)
        let keyedGuides = Dictionary(uniqueKeysWithValues: guides.map { ($0.key.rawValue, $0.value) })
        try container.encode(keyedGuides, forKey: .guides)
        try container.encode(plans, forKey: .plans)
        try container.encode(notices, forKey: .notices)
        let encodedRates = Dictionary(
            uniqueKeysWithValues: exchangeRates.knownCurrencies
                .filter { $0 != ExchangeRates.usdCode }
                .compactMap { code -> (String, String)? in
                    guard let rate = exchangeRates.toUSD(1, from: code) else { return nil }
                    return (code, NSDecimalNumber(decimal: rate.usdPerUnit).stringValue)
                }
        )
        try container.encode(encodedRates, forKey: .exchangeRates)
    }
}
