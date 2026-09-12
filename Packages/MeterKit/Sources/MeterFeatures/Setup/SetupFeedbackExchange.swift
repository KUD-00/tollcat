import Foundation
import MeterFeedback
import MeterProviders

/// 把测试连接的 HTTP 往返收成一段能出站的字。
///
/// 开发页那份摘要已经打过密钥。出站还要把账单数字打掉——Worker
/// 不许碰账单数据，用户打开开关也不等于授权把金额存到我们这边。
enum SetupFeedbackExchange {
    static func outboundText(_ exchanges: [HTTPExchange]) -> String? {
        let chunks = exchanges.map(dump).filter { !$0.isEmpty }
        guard !chunks.isEmpty else { return nil }
        return FeedbackFieldLimits.clampExchange(chunks.joined(separator: "\n\n"))
    }

    private static func dump(_ exchange: HTTPExchange) -> String {
        let body = redactMoney(in: exchange.body)
        if body.isEmpty { return exchange.summary }
        return exchange.summary + "\n" + body
    }

    /// JSON 里像金额的字段打成 `***`。解析不了就原样，错误字符串通常没有账。
    static func redactMoney(in text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let pretty = try? JSONSerialization.data(
                withJSONObject: redactMoneyJSON(object),
                options: [.prettyPrinted, .sortedKeys]
              ),
              let out = String(data: pretty, encoding: .utf8)
        else {
            return text
        }
        return out
    }

    static func redactMoneyJSON(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            var out: [String: Any] = [:]
            for (key, nested) in dictionary {
                if isMoneyKey(key) {
                    out[key] = "***"
                } else {
                    out[key] = redactMoneyJSON(nested)
                }
            }
            return out
        }
        if let array = value as? [Any] {
            return array.map(redactMoneyJSON)
        }
        return value
    }

    private static func isMoneyKey(_ key: String) -> Bool {
        let name = key.lowercased()
        for token in [
            "amount", "spend", "balance", "cost", "price",
            "fee", "usd", "invoice", "charge", "billed", "payment",
        ] {
            if name == token || name.contains(token) { return true }
        }
        return false
    }
}
