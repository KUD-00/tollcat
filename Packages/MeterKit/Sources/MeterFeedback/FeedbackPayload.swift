import Foundation

/// 一条反馈离开设备时**只带这些字段**。
///
/// 不在这里、以后也不该加进来的东西：
/// - 任何 provider 凭据（这条红线和 `TipMessagePayload` 一样）
/// - 任何金额、用量、余额
/// - 任何设备或用户标识（`id` 是这条反馈自己的 UUID，不是设备的）
/// - 读数信箱的 id 或 key
///
/// `providers` 是唯一带一点用户信息的字段，所以它由界面上一个默认关掉的
/// 开关控制，而且只有服务名——「我接了 AWS 和 OpenAI」这个事实，
/// 换来的是能看懂「这家的数字不对」到底说的是哪家。
///
/// `exchange` 是第二条要用户按的开关：测试连接那次 HTTP 的摘要。
/// 密钥和账单数字在 Features 里打码之后才进这里；本模块只当它是一段字。
public struct FeedbackPayload: Hashable, Sendable, Encodable {
    /// 客户端生成。重发同一条走 Worker 的 `INSERT OR IGNORE`，不会变成两条。
    public var id: String
    public var category: FeedbackCategory
    public var message: String
    public var contact: String?
    public var appVersion: String
    public var osVersion: String
    public var locale: String
    public var deviceModel: String?
    public var providers: [String]?
    public var exchange: String?

    public init(
        id: String,
        category: FeedbackCategory,
        message: String,
        contact: String? = nil,
        appVersion: String,
        osVersion: String,
        locale: String,
        deviceModel: String? = nil,
        providers: [String]? = nil,
        exchange: String? = nil
    ) {
        self.id = id
        self.category = category
        self.message = FeedbackFieldLimits.clampMessage(message) ?? ""
        self.contact = FeedbackFieldLimits.clampContact(contact)
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.locale = locale
        self.deviceModel = deviceModel
        self.providers = Self.clampProviders(providers)
        self.exchange = FeedbackFieldLimits.clampExchange(exchange)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(contact, forKey: .contact)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(locale, forKey: .locale)
        try container.encodeIfPresent(deviceModel, forKey: .deviceModel)
        try container.encodeIfPresent(providers, forKey: .providers)
        try container.encodeIfPresent(exchange, forKey: .exchange)
    }

    private enum CodingKeys: String, CodingKey {
        case id, category, message, contact
        case appVersion, osVersion, locale, deviceModel
        case providers, exchange
    }

    /// 空数组和 nil 一样都编码成不带这个字段，Worker 那边少一个分支。
    private static func clampProviders(_ raw: [String]?) -> [String]? {
        guard let raw else { return nil }
        let names = raw
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        guard names.joined(separator: ",").count <= FeedbackFieldLimits.providers else { return nil }
        return names
    }
}
