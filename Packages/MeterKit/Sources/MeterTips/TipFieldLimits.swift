// GENERATED — 由 scripts/generate-shared.py 从 shared/api-contract.json 生成。
// 不要手改：改 shared/api-contract.json 后重跑生成器。

import Foundation

/// 和 Worker 的常量同一份（shared/api-contract.json）。两边都截：
/// 客户端截是为了让用户当场看见字数，服务端截是因为客户端可以被绕过。
public enum TipFieldLimits: Sendable {
    public static let name = 40
    public static let message = 500

    public static func clampName(_ raw: String?) -> String? {
        clamp(raw, limit: name)
    }

    public static func clampMessage(_ raw: String?) -> String? {
        clamp(raw, limit: message)
    }

    private static func clamp(_ raw: String?, limit: Int) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return String(trimmed.prefix(limit))
    }
}
