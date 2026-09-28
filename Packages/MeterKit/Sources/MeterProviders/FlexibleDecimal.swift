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
        // 不走 Double：19.99 这类金额在二进制里存不准，数一大误差还会漏到分位。
        // 系统的 JSONDecoder 解 Decimal 是直接读数字原文，和后台账本同一个十进制值。
        // 仍截到 8 位：有的序列化器会把 0.07 写成 0.07000000000000001，那一截不是金额。
        if var raw = try? container.decode(Decimal.self) {
            var rounded = Decimal()
            NSDecimalRound(&rounded, &raw, 8, .plain)
            value = rounded
            return
        }
        // 个别数字形态解不成 Decimal 时退回 Double，至少不比原来差。
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
