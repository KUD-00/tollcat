import Foundation

/// 一次性转移码。只用来派生文件密钥，不入库、不写日志、不进剪贴板。
///
/// `characterCount` 是 10 位 Crockford base32，约 50 bit。
/// 改小到 6 位数字是把 50 bit 降到 20 bit：文件一旦落到别人手上，
/// 攻击者不用管 App、不用管过期时间，离线穷举 10^6 种可能。
/// 就算 PBKDF2 拉到 60 万轮，GPU 上也是几小时的事，而文件里是能直接花钱的 API key。
/// 只在通道绝对可信（当面 AirDrop、立刻导入）时才勉强可接受。
public struct TransferCode: Equatable, Hashable, Sendable {
    /// 改这一行等于改熵。见类型注释。
    public static let characterCount = 10

    /// Crockford base32，去掉 I L O U，避免和 1 / 0 读混。
    public static let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    /// 规范形：10 个大写字母/数字，没有连字符。
    public let rawValue: String

    public var displayString: String {
        let characters = Array(rawValue)
        return String(characters[0..<5]) + "-" + String(characters[5..<10])
    }

    public static func generate() -> TransferCode {
        var generator = SystemRandomNumberGenerator()
        return generate(using: &generator)
    }

    public static func generate(using generator: inout some RandomNumberGenerator) -> TransferCode {
        let symbols = Array(alphabet)
        var characters: [Character] = []
        characters.reserveCapacity(characterCount)
        for _ in 0..<characterCount {
            let index = Int.random(in: 0..<symbols.count, using: &generator)
            characters.append(symbols[index])
        }
        return TransferCode(validated: String(characters))
    }

    public init?(userInput: String) {
        var normalized = ""
        normalized.reserveCapacity(Self.characterCount)
        for character in userInput {
            if character == "-" || character.isWhitespace {
                continue
            }
            let uppercased = character.uppercased()
            guard uppercased.count == 1, let mapped = uppercased.first else {
                return nil
            }
            let canonical: Character
            switch mapped {
            case "I", "L":
                canonical = "1"
            case "O":
                canonical = "0"
            default:
                canonical = mapped
            }
            guard Self.alphabet.contains(canonical) else {
                return nil
            }
            normalized.append(canonical)
        }
        guard normalized.count == Self.characterCount else {
            return nil
        }
        self.rawValue = normalized
    }

    init(validated: String) {
        self.rawValue = validated
    }
}
