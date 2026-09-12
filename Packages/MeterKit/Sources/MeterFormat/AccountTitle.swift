import Foundation
import MeterCore

// 用到 `LocalizedStringResource`，和这个 target 里别的文案文件一样不进 Android 的 .so。
#if !os(Android)

public struct AccountTitleContext: Equatable, Sendable {
    public var visual: String
    public var spoken: String
    public var siblingCount: Int
    public var identityHint: String?

    public init(visual: String, spoken: String, siblingCount: Int, identityHint: String? = nil) {
        self.visual = visual
        self.spoken = spoken
        self.siblingCount = siblingCount
        self.identityHint = identityHint
    }
}

/// 屏幕上那串账号标题。一份时是「Cloudflare」，多份时是「Cloudflare · 工作」。
public enum AccountTitle {
    public static func context(
        for accountID: AccountID,
        connections: [ProviderConnectionState],
        providerDisplayName: String
    ) -> AccountTitleContext {
        let match = connections.first { $0.accountID == accountID }
        let siblings = connections.filter { $0.providerID == match?.providerID }
        let siblingCount = siblings.isEmpty ? 1 : siblings.count
        let nickname = trimmed(match?.nickname)
        let hint = trimmed(match?.identityHint)

        let visual: String
        if let nickname {
            visual = "\(providerDisplayName) · \(nickname)"
        } else {
            visual = providerDisplayName
        }

        var spoken = visual
        if siblingCount > 1 {
            let spokenNick = nickname ?? String(localized: L("账号 1"))
            spoken = "\(providerDisplayName) · \(spokenNick)"
            let sameNickname = siblings.filter { trimmed($0.nickname) == nickname }
            if sameNickname.count > 1, let hint {
                spoken = "\(spoken) · \(hint)"
            }
        }

        return AccountTitleContext(
            visual: visual,
            spoken: spoken,
            siblingCount: siblingCount,
            identityHint: hint
        )
    }

    private static func trimmed(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
#endif
