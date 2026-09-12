import Foundation
import MeterCore

/// 多币种钱包用字符串编 `Decimal`，避免 JSON 数字改分位。
enum WalletBalanceCodec {
    struct Entry: Codable {
        var currency: String
        var amount: String
        var usdPerUnit: String
        var usd: String
    }

    static func encode(_ wallets: [ConvertedAmount]?) throws -> Data? {
        guard let wallets, !wallets.isEmpty else { return nil }
        let entries = wallets.map { wallet in
            Entry(
                currency: wallet.currency,
                amount: decimalString(wallet.amount),
                usdPerUnit: decimalString(wallet.usdPerUnit),
                usd: decimalString(wallet.usd)
            )
        }
        return try JSONEncoder().encode(entries)
    }

    static func decode(_ data: Data?) throws -> [ConvertedAmount]? {
        guard let data else { return nil }
        do {
            let entries = try JSONDecoder().decode([Entry].self, from: data)
            let wallets = try entries.map { entry -> ConvertedAmount in
                guard
                    let amount = Decimal(string: entry.amount),
                    let usdPerUnit = Decimal(string: entry.usdPerUnit),
                    let usd = Decimal(string: entry.usd)
                else {
                    throw PersistenceError.corruptWalletBalances
                }
                return ConvertedAmount(
                    currency: entry.currency,
                    amount: amount,
                    usdPerUnit: usdPerUnit,
                    usd: usd
                )
            }
            return wallets.isEmpty ? nil : wallets
        } catch is PersistenceError {
            throw PersistenceError.corruptWalletBalances
        } catch {
            throw PersistenceError.corruptWalletBalances
        }
    }

    private static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}
