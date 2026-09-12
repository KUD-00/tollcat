import Foundation

/// 目录里的套餐：名称 + 价格 + 周期。金额用字符串编解码，保住分位。
public struct SubscriptionPlan: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var name: String?

        public init(name: String? = nil) {
            self.name = name
        }
    }

    public var name: String
    public var amount: Money
    public var period: SubscriptionPeriod
    public var providerID: ProviderID?
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        name: String,
        amount: Money,
        period: SubscriptionPeriod,
        providerID: ProviderID? = nil,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.name = name
        self.amount = amount
        self.period = period
        self.providerID = providerID
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> SubscriptionPlan {
        let copy = language.pick(en: en, ja: ja)
        return SubscriptionPlan(
            name: catalogOverlay(copy?.name, fallback: name),
            amount: amount,
            period: period,
            providerID: providerID
        )
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case amountUSD
        case period
        case providerID
        case en
        case ja
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        period = try container.decode(SubscriptionPeriod.self, forKey: .period)
        providerID = try container.decodeIfPresent(ProviderID.self, forKey: .providerID)
        amount = Money(usd: try Self.decodeDecimal(from: container))
        en = try container.decodeIfPresent(LocalizedCopy.self, forKey: .en)
        ja = try container.decodeIfPresent(LocalizedCopy.self, forKey: .ja)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(NSDecimalNumber(decimal: amount.usd).stringValue, forKey: .amountUSD)
        try container.encode(period, forKey: .period)
        try container.encodeIfPresent(providerID, forKey: .providerID)
        try container.encodeIfPresent(en, forKey: .en)
        try container.encodeIfPresent(ja, forKey: .ja)
    }

    private static func decodeDecimal(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> Decimal {
        if let string = try? container.decode(String.self, forKey: .amountUSD),
           let decimal = Decimal(string: string) {
            return decimal
        }
        if let decimal = try? container.decode(Decimal.self, forKey: .amountUSD) {
            return decimal
        }
        throw DecodingError.dataCorruptedError(
            forKey: .amountUSD,
            in: container,
            debugDescription: "amountUSD must be a decimal string or number"
        )
    }
}
