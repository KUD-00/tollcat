// GENERATED — 由 scripts/generate-shared.py 从 shared/api-contract.json 生成。
// 不要手改：改 shared/api-contract.json 后重跑生成器。

import Foundation

/// 和 Worker 的常量同一份（shared/api-contract.json）。两边都截：
/// 客户端截是为了让用户当场看见字数，服务端截是因为客户端可以被绕过。
public enum FeedbackFieldLimits: Sendable {
    public static let message = 2000
    public static let contact = 120
    /// 服务名单拼平之后的上限。超了就整段不带——半截名单会误导诊断。
    public static let providers = 400
    /// 测试连接的 HTTP 摘要。用户显式打开才带；超了截断，不当整段丢掉。
    public static let exchange = 1200

    public static func clampMessage(_ raw: String?) -> String? {
        clamp(raw, limit: message)
    }

    public static func clampContact(_ raw: String?) -> String? {
        clamp(raw, limit: contact)
    }

    public static func clampExchange(_ raw: String?) -> String? {
        clamp(raw, limit: exchange)
    }

    private static func clamp(_ raw: String?, limit: Int) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return String(trimmed.prefix(limit))
    }
}
