import Foundation
import MeterCore

/// 账单金额在文档里既可能是 JSON number，也可能是字符串。两种都收。
struct FlexibleDecimal: Decodable, Sendable, Hashable {
    var value: Decimal

    init(_ value: Decimal) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let parsed = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "not a decimal string"
                )
            }
            value = parsed
            return
        }
        if let int = try? container.decode(Int64.self) {
            value = Decimal(int)
            return
        }
        // 待核对：JSON 小数走 Double 会有二进制误差。真账号对账时看分位是否和后台一致。
        if let double = try? container.decode(Double.self) {
            var raw = Decimal(double)
            var rounded = Decimal()
            NSDecimalRound(&rounded, &raw, 8, .plain)
            value = rounded
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "not a number")
    }

    var money: Money { Money(usd: value) }
}
