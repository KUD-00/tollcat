import Foundation

/// 各次刷新里的日费用合成一张日表。同一天后取的覆盖先取的。
///
/// 日费用是「那天花了多少」这条读数，不是每次刷新再记一笔。把历次快照
/// 按天相加，刷新 80 次就把上月 $40 加成 $3200。详情柱图和上月同期必须
/// 走这一份，不能各写各的。
///
/// ## 日期钥匙是「此刻这本日历上的那一天」
///
/// 快照里的日期是「厂商说的那一天」在读它那本日历上的零点：落盘存的是年月日分量
/// （`DayKey`），读的时候按此刻的日历还原，所以换过时区之后同一个厂商日仍然是同一个键，
/// **不会**挪位、也不会变成两天。这里的 `startOfDay` 只是把同一本日历下已经对齐的键
/// 再归一次，正常情况下什么也不做。
///
/// 同一条快照里两个键归到同一天时（不该发生，但发生了就是一笔钱被拆成两半）**相加**；
/// 不同快照落在同一天时后取覆盖先取——那是同一天的两次观测，不是两笔钱。
public enum SnapshotDailyMap {
    public static func merged(from snapshots: [Snapshot], calendar: Calendar) -> [Date: Money] {
        // 排序键是（取数时刻, 在数组里的位置）。同一秒里写两条的情况存在，
        // 光比时刻分不出先后，而位置能——也正因为它能，才认得出
        // 「这两笔来自同一条快照」，那是唯一该相加的情形。
        var latest: [Date: (order: (Date, Int), amount: Money)] = [:]
        for (index, snapshot) in snapshots.enumerated() {
            guard snapshot.kind.contributesUsageComparison, let map = snapshot.dailyUSD else {
                continue
            }
            let order = (snapshot.fetchedAt, index)
            for (day, amount) in map {
                let key = calendar.startOfDay(for: day)
                if let existing = latest[key] {
                    if existing.order > order { continue }
                    if existing.order == order {
                        latest[key] = (order, existing.amount + amount)
                        continue
                    }
                }
                latest[key] = (order, amount)
            }
        }
        return latest.mapValues(\.amount)
    }
}
