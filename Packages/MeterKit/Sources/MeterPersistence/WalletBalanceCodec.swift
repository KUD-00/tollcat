import Foundation
import MeterCore

/// 多币种钱包用字符串编 `Decimal`，避免 JSON 数字改分位。
enum WalletBalanceCodec {
    /// 写出端是 NSDecimalNumber.stringValue，恒为点号小数。读也钉死 POSIX：默认 locale
    /// 在德语、法语等把点当千分位的设备上，会把存好的 "12.34" 读成 1234 或直接失败。
    private static let posix = Locale(identifier: "en_US_POSIX")

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
                    let amount = Decimal(string: entry.amount, locale: Self.posix),
                    let usdPerUnit = Decimal(string: entry.usdPerUnit, locale: Self.posix),
                    let usd = Decimal(string: entry.usd, locale: Self.posix)
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
