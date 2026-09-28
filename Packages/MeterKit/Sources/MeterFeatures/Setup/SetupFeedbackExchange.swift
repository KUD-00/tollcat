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
        // 摘要也要过一遍：错误行和 URL 里同样可能带金额（`?amount=12.50`、
        // 上游错误串里的「余额 $3.20」），以前只洗正文，摘要原样拼上去。
        let summary = redactMoneyInFreeText(exchange.summary)
        let body = redactMoney(in: exchange.body)
        if body.isEmpty { return summary }
        return summary + "\n" + body
    }

    /// JSON 里像金额的字段打成 `***`，字符串值里的金额也打。
    ///
    /// 解析不了的正文（HTML 错误页、XML、表单、纯文本）**不再原样放行**：
    /// 以前的假设是「错误字符串通常没有账」，但 XML / 表单账单接口的正文就是账，
    /// 原样出站等于 Worker 收到金额。这类正文按文本规则打掉像金额的数字。
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
            return redactMoneyInFreeText(text)
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
        // 键名看着无害的字符串值也可能是一句带金额的话（`"message": "Balance $3.20"`）。
        if let string = value as? String {
            return redactMoneyInFreeText(string)
        }
        return value
    }

    // MARK: - 键名

    /// 子串命中就算：这些词拼进别的键名里也几乎总是钱（`currentSpendUSD`、`unit_price`）。
    private static let moneySubstrings = [
        "amount", "spend", "balance", "cost", "price",
        "fee", "usd", "invoice", "charge", "billed", "payment", "tariff",
    ]

    /// 只按**整词**认的别名。`total` / `due` / `credit` 这类词太短，按子串会误伤
    /// （`residue`、`creditorName`、`totally_fine`），所以拆词后比对。
    private static let moneyWords: Set<String> = [
        "bill", "bills", "billing", "total", "totals", "subtotal", "grandtotal",
        "credit", "credits", "debit", "debits", "due", "owing", "owed", "outstanding",
        "tariffs", "tax", "taxes", "vat", "refund", "refunds", "overage", "prepaid",
        "arrears", "revenue", "money", "cents", "eur", "gbp", "jpy", "cny", "rmb",
    ]

    /// 键名以这些词收尾时，整词别名不算钱：`total_tokens`、`totalCount`、`due_date`
    /// 是计数或时间，打掉它们抓包就没法用了。子串那一档不受这条豁免。
    private static let nonMoneyTails: Set<String> = [
        "tokens", "token", "count", "counts", "requests", "calls", "items", "pages",
        "results", "records", "rows", "bytes", "seconds", "ms", "minutes", "hours",
        "days", "date", "at", "time", "timestamp", "id", "ids",
    ]

    static func isMoneyKey(_ key: String) -> Bool {
        let name = key.lowercased()
        if moneySubstrings.contains(where: { name.contains($0) }) { return true }
        let words = keyWords(key)
        guard words.contains(where: { moneyWords.contains($0) }) else { return false }
        if let last = words.last, nonMoneyTails.contains(last) { return false }
        return true
    }

    /// `currentBill` / `current_bill` / `current-bill` 一律拆成 `["current", "bill"]`。
    private static func keyWords(_ key: String) -> [String] {
        var words: [String] = []
        var current = ""
        var previousWasLower = false
        for character in key {
            guard character.isLetter || character.isNumber else {
                if !current.isEmpty { words.append(current) }
                current = ""
                previousWasLower = false
                continue
            }
            if character.isUppercase, previousWasLower, !current.isEmpty {
                words.append(current)
                current = ""
            }
            current.append(character)
            previousWasLower = character.isLowercase || character.isNumber
        }
        if !current.isEmpty { words.append(current) }
        return words.map { $0.lowercased() }
    }

    // MARK: - 自由文本

    /// 带币种记号的数（`$12`、`12.50 USD`、`€ 3`）。
    ///
    /// 这几条只存模式串、用时再编：`NSRegularExpression` 做静态常量在 Swift 6
    /// 严格并发下要论证 Sendable，为省那一点编译开销不值得。
    private static let currencyAdjacentPattern =
        #"(?:[$€£¥￥]|\b(?:usd|eur|gbp|jpy|cny|rmb|cad|aud)\b)\s*-?\d[\d,]*(?:\.\d+)?"#
        + #"|-?\d[\d,]*(?:\.\d+)?\s*(?:[$€£¥￥]|\b(?:usd|eur|gbp|jpy|cny|rmb|cad|aud)\b)"#

    /// 表单 / YAML / XML 里「钱的键 → 数」：`total=142`、`bill: 142`、`<due>142</due>`。
    /// 键名判定和 JSON 那条共用 `isMoneyKey`。XML 那一支限定在一行两百字内找 `>`，
    /// 免得每个单词都往后扫到文末。
    private static let keyedNumberPattern =
        #"([A-Za-z_][A-Za-z0-9_.\-]*)(\s*[:=]\s*["']?|[^<>\n]{0,200}>\s*)(-?\d[\d,]*(?:\.\d+)?)"#

    /// 带小数的数一律当成可能的金额：账单接口的数字几乎都有两位小数，
    /// 而状态码、token 计数这些排障真正要看的都是整数。版本号 / IP 会被一并打掉，
    /// 这是有意的取舍——宁可少一点排障信息，也不让金额出站。
    private static let decimalNumberPattern = #"\d+(?:[.,]\d+)+"#

    static func redactMoneyInFreeText(_ text: String) -> String {
        guard text.contains(where: \.isNumber) else { return text }
        guard var out = replace(currencyAdjacentPattern, caseInsensitive: true, in: text, transform: { _ in "***" }),
              let keyed = replace(keyedNumberPattern, in: out, transform: { match in
                  guard isMoneyKey(match[1]) else { return match[0] }
                  return match[1] + match[2] + "***"
              })
        else {
            return "***"
        }
        out = keyed
        return replace(decimalNumberPattern, in: out, transform: { _ in "***" }) ?? "***"
    }

    /// 逐个匹配交给 `transform`（拿到整段与各捕获组），顺序拼出新串。
    /// 模式编不过回 `nil`，调用方整段打掉——出站这条路不许因为出错而放行原文。
    private static func replace(
        _ pattern: String,
        caseInsensitive: Bool = false,
        in text: String,
        transform: ([String]) -> String
    ) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: caseInsensitive ? [.caseInsensitive] : []
        ) else {
            return nil
        }
        var result = ""
        var cursor = text.startIndex
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text) else { continue }
            let groups = (0..<match.numberOfRanges).map { index -> String in
                guard let groupRange = Range(match.range(at: index), in: text) else { return "" }
                return String(text[groupRange])
            }
            result += text[cursor..<range.lowerBound]
            result += transform(groups)
            cursor = range.upperBound
        }
        result += text[cursor...]
        return result
    }
}
