import Foundation
import MeterCore

/// 日粒度表的落盘编码。
///
/// 金额用字符串编 `Decimal`，避免 JSON 数字把 11.05 写成 11.04999。
///
/// **日期存 `yyyy-MM-dd`，不存时间戳。** 日桶的键是「厂商说的那一天」，是日历上的
/// 位置，不是某个时区的零点那一刻。存成时间戳的话，东京记下的 8 月 15 日零点在纽约
/// 读出来是 8 月 14 日——整张表错一天，同一天在两地各刷一次还会变成两个键被算两遍。
/// 见 `DayKey`。
///
/// 读的时候按调用方给的日历把分量还原成那一天的零点，所以域层的 `[Date: Money]`
/// 永远是「此刻这本日历上的那一天」。换了时区再读一次就对了，不需要迁移。
enum DailySpendCodec {
    /// 现在的格式。
    private struct Entry: Codable {
        var d: String
        var usd: String
    }

    /// 加 `DayKey` 之前写下的行：`day` 是 `timeIntervalSinceReferenceDate`。
    /// 只在读的时候认，按给的日历落日——那是当时写它的机器最可能的意思。
    private struct LegacyEntry: Codable {
        var day: TimeInterval
        var usd: String
    }

    static func encode(_ daily: [Date: Money]?, calendar: Calendar) throws -> Data? {
        guard let daily else { return nil }
        // 同一天两个瞬间（不该发生，但日历归一后可能撞上）：相加，不能静悄悄丢一笔。
        var merged: [DayKey: Decimal] = [:]
        for (date, money) in daily {
            merged[DayKey(date, calendar: calendar), default: 0] += money.usd
        }
        let entries = merged
            .map { key, usd in Entry(d: key.storageString, usd: NSDecimalNumber(decimal: usd).stringValue) }
            .sorted { $0.d < $1.d }
        return try JSONEncoder().encode(entries)
    }

    static func decode(_ data: Data?, calendar: Calendar) throws -> [Date: Money]? {
        guard let data else { return nil }
        let decoder = JSONDecoder()
        if let entries = try? decoder.decode([Entry].self, from: data) {
            var result: [Date: Money] = [:]
            result.reserveCapacity(entries.count)
            for entry in entries {
                guard
                    let key = DayKey(storageString: entry.d),
                    let day = key.date(in: calendar),
                    let decimal = Decimal(string: entry.usd)
                else {
                    throw PersistenceError.corruptDailySpend
                }
                result[day, default: .zero] += Money(usd: decimal)
            }
            return result
        }
        if let entries = try? decoder.decode([LegacyEntry].self, from: data) {
            var result: [Date: Money] = [:]
            result.reserveCapacity(entries.count)
            for entry in entries {
                guard let decimal = Decimal(string: entry.usd) else {
                    throw PersistenceError.corruptDailySpend
                }
                let day = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: entry.day))
                result[day, default: .zero] += Money(usd: decimal)
            }
            return result
        }
        throw PersistenceError.corruptDailySpend
    }
}
