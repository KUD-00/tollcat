import Foundation
import MeterCore

/// 明细和钱包同一套路：`Decimal` 编成字符串，别让 JSON 数字改掉分位。
enum SpendLineCodec {
    struct Entry: Codable {
        var category: String
        var label: String
        var scope: String?
        var amount: String
        var list: String?
        var quantity: String?
        var unit: String?
        var allowanceNote: String?
    }

    static func encode(_ lines: [SpendLine]?) throws -> Data? {
        guard let lines, !lines.isEmpty else { return nil }
        let entries = lines.map { line in
            Entry(
                category: line.category,
                label: line.label,
                scope: line.scope,
                amount: decimalString(line.amountUSD.usd),
                list: line.listUSD.map { decimalString($0.usd) },
                quantity: line.quantity.map(decimalString),
                unit: line.unit,
                allowanceNote: line.allowanceNote
            )
        }
        return try JSONEncoder().encode(entries)
    }

    static func decode(_ data: Data?) throws -> [SpendLine]? {
        guard let data else { return nil }
        do {
            let entries = try JSONDecoder().decode([Entry].self, from: data)
            let lines = try entries.map { entry -> SpendLine in
                guard let amount = Decimal(string: entry.amount) else {
                    throw PersistenceError.corruptSpendLines
                }
                return SpendLine(
                    category: entry.category,
                    label: entry.label,
                    scope: entry.scope,
                    amountUSD: Money(usd: amount),
                    listUSD: try entry.list.map { raw in
                        guard let value = Decimal(string: raw) else {
                            throw PersistenceError.corruptSpendLines
                        }
                        return Money(usd: value)
                    },
                    quantity: try entry.quantity.map { raw in
                        guard let value = Decimal(string: raw) else {
                            throw PersistenceError.corruptSpendLines
                        }
                        return value
                    },
                    unit: entry.unit,
                    allowanceNote: entry.allowanceNote
                )
            }
            return lines.isEmpty ? nil : lines
        } catch {
            throw PersistenceError.corruptSpendLines
        }
    }

    private static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}
