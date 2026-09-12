import Foundation
import Testing
import MeterFeedback

struct FeedbackPayloadTests {
    private func payload(
        message: String = "登录页转圈",
        contact: String? = nil,
        providers: [String]? = nil
    ) -> FeedbackPayload {
        FeedbackPayload(
            id: "11111111-2222-3333-4444-555555555555",
            category: .bug,
            message: message,
            contact: contact,
            appVersion: "0.1.0 (1)",
            osVersion: "iOS 26.0",
            locale: "zh-Hans_CN",
            deviceModel: "iPhone17,1",
            providers: providers
        )
    }

    // MARK: - 截断

    @Test("正文超上限就截断，不是整条丢掉")
    func messageIsClamped() {
        let long = String(repeating: "字", count: FeedbackFieldLimits.message + 50)
        #expect(payload(message: long).message.count == FeedbackFieldLimits.message)
    }

    @Test("只有空白的联系方式当成没填")
    func blankContactBecomesNil() {
        #expect(payload(contact: "   \n ").contact == nil)
        #expect(payload(contact: "").contact == nil)
        #expect(payload(contact: "  a@b.c  ").contact == "a@b.c")
    }

    @Test("空服务名单编码成不带这个字段，不是空数组")
    func emptyProviderListIsOmitted() throws {
        #expect(payload(providers: []).providers == nil)
        #expect(payload(providers: ["  ", ""]).providers == nil)
        #expect(payload(providers: nil).providers == nil)

        let json = try encoded(payload(providers: nil))
        #expect(json["providers"] == nil)
    }

    @Test("服务名单拼平超限就整段不带——半截名单会误导诊断")
    func oversizeProviderListIsDroppedWhole() {
        let many = (0..<200).map { "Provider\($0)" }
        #expect(many.joined(separator: ",").count > FeedbackFieldLimits.providers)
        #expect(payload(providers: many).providers == nil)
    }

    @Test("正常的服务名单原样带上，顺序不变")
    func providerListSurvives() {
        #expect(payload(providers: ["AWS", "OpenAI"]).providers == ["AWS", "OpenAI"])
    }

    // MARK: - 出站字段

    @Test("离开设备的字段就这些，一个都不多")
    func payloadCarriesNothingElse() throws {
        let json = try encoded(payload(contact: "a@b.c", providers: ["AWS"]))
        let expected: Set<String> = [
            "id", "category", "message", "contact",
            "appVersion", "osVersion", "locale", "deviceModel", "providers",
        ]
        #expect(Set(json.keys) == expected)
    }

    @Test("HTTP 摘要默认不带；打开才进 payload")
    func exchangeIsOmittedUntilSet() throws {
        let json = try encoded(payload())
        #expect(json["exchange"] == nil)

        let withDump = payload()
        let attached = FeedbackPayload(
            id: withDump.id,
            category: withDump.category,
            message: withDump.message,
            contact: withDump.contact,
            appVersion: withDump.appVersion,
            osVersion: withDump.osVersion,
            locale: withDump.locale,
            deviceModel: withDump.deviceModel,
            providers: withDump.providers,
            exchange: "GET https://api.example/v1\nHTTP 403"
        )
        let encodedDump = try encoded(attached)
        #expect(encodedDump["exchange"] as? String == "GET https://api.example/v1\nHTTP 403")
    }

    @Test("HTTP 摘要超上限就截断")
    func exchangeIsClamped() {
        let long = String(repeating: "a", count: FeedbackFieldLimits.exchange + 50)
        let attached = FeedbackPayload(
            id: "11111111-2222-3333-4444-555555555555",
            category: .bug,
            message: "x",
            appVersion: "0.1.0 (1)",
            osVersion: "iOS 26.0",
            locale: "zh-Hans_CN",
            exchange: long
        )
        #expect(attached.exchange?.count == FeedbackFieldLimits.exchange)
    }

    @Test("分类编码成 Worker 认的那几个字符串")
    func categoryEncodesAsRawString() throws {
        #expect(FeedbackCategory.allCases.map(\.rawValue).sorted()
            == ["bug", "idea", "other", "provider"])
        let json = try encoded(payload())
        #expect(json["category"] as? String == "bug")
    }

    /// 金额、余额、用量、key 这些词一个都不该出现在这个模块的公开面上。
    /// 类型层面已经保证了（MeterFeedback 不 import MeterCore，拿不到 `Money`），
    /// 这条只是把「有人手写一个 `amount: Double` 字段」也堵住。
    @Test("payload 里没有任何和钱有关的字段名")
    func noMoneyShapedFields() throws {
        let keys = try encoded(payload(providers: ["AWS"])).keys.map { $0.lowercased() }
        for banned in ["amount", "usd", "spend", "balance", "cost", "usage", "key", "token", "credential"] {
            #expect(!keys.contains { $0.contains(banned) }, "payload 里出现了 \(banned)")
        }
    }

    private func encoded(_ payload: FeedbackPayload) throws -> [String: Any] {
        let data = try JSONEncoder().encode(payload)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }
}
