import Foundation
import SwiftData
import MeterCore

/// 快照表的压缩。SPEC 第 12.5 节「快照压缩策略」的实现。
///
/// ## 为什么必须有
///
/// 「永不删除」是**读取契约**（趋势图能重算历史），不是存储契约。两条放在一起
/// 是无界增长：每家每次刷新落一条，而能回看的只有 12 个月——13 个月以前的行
/// **任何一屏都读不到**，却一直占着全库最大的那张表。一个刷得勤的用户两年后
/// 是几万行；那时候再加压缩，就是给一张写满真实历史的表写第一条数据迁移。
///
/// SPEC 里这条曾经写着「实现可以晚」，那句话建立在「写侧已经和刷新次数脱钩」
/// 的假设上，而那个假设当时不成立。现在两件事一起做完。
///
/// ## 规则
///
/// - **保留窗口 = 能回看的月份 + 1 个月**（`DashboardPeriod.maxMonthsBack` + 当月 + 1）。
///   窗口内一条都不删：月内的多次刷新是日表压平和「最新一条带明细的是哪条」的依据。
/// - **窗口以外，每（账号, 月）只留 `fetchedAt` 最大的那一条。** 留最后一条而不是
///   第一条：账期累计型的家（`currentSpendUSD` 是本月至今）最后一条才是那个月的终值。
/// - **这里的「月」是 `fetchedAt` 所在的月，不是账期所在的月**（SPEC 12.5 写明了）。
///   两者只在**补录**时岔开：九月给八月手填一笔，归进九月那一组。取 `fetchedAt` 是因为
///   窗口本身按 `fetchedAt` 切、那一列上有索引，两处用同一把尺；也因为
///   `SnapshotLog.latestBefore`（预充值的月初锚点）按 `fetchedAt` 挑，按取数月分组
///   能保证它一定还在。
/// - **手填和信箱来的读数一视同仁**：`source` 不进判据。
/// - **先折后删。** 调用方保证压缩发生在同步之后（见 `LedgerSync`），
///   于是账本里那些月份的行是从压缩**之前**的完整历史折出来的。
///
/// 删除和作废戳在同一个事务里：戳留着的话下一次开门会拿一份「按更多读数折出来的」
/// 账本当数，而它和现在库里的内容已经对不上了。
public enum SnapshotCompactor: Sendable {
    /// 保留窗口有多少个月。**唯一出处是 `DashboardPeriod`**，别在这里再写一个数字。
    /// `maxMonthsBack` 是 11（能往前翻 11 个月），加当月是 12，再加 1 个月余量。
    public static let windowMonths = DashboardPeriod.maxMonthsBack + 2

    /// 窗口起点：`now` 所在月的月首往前 `windowMonths - 1` 个月。
    /// 这一天（含）之后的行一条都不删。
    public static func windowStart(now: Date, calendar: Calendar) -> Date? {
        guard let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return nil
        }
        return calendar.date(byAdding: .month, value: -(windowMonths - 1), to: thisMonth)
    }

    /// 删掉窗口以外多余的行。回删了多少条。
    ///
    /// 一条都不用删时**什么都不写**——戳也不动，免得每天白重折一次。
    @discardableResult
    public static func compact(
        now: Date,
        calendar: Calendar,
        in context: ModelContext
    ) throws -> Int {
        guard let start = windowStart(now: now, calendar: calendar) else { return 0 }
        // 窗口内一条都不碰，所以只取窗口之前的行。`fetchedAt` 上有索引。
        let descriptor = FetchDescriptor<SnapshotRecord>(
            predicate: #Predicate { $0.fetchedAt < start },
            sortBy: [SortDescriptor(\.fetchedAt)]
        )
        let old = try context.fetch(descriptor)
        guard !old.isEmpty else { return 0 }

        // 每（账号, 月）留 `fetchedAt` 最大的那一条。上面按 `fetchedAt` 升序取，
        // 所以后来的覆盖先来的，留下的就是最后一条。
        struct Key: Hashable {
            var account: String
            var month: MonthKey
        }
        var keep: [Key: SnapshotRecord] = [:]
        var doomed: [SnapshotRecord] = []
        for record in old {
            let key = Key(
                account: record.accountIDRaw,
                month: MonthKey(record.fetchedAt, calendar: calendar)
            )
            if let previous = keep[key] {
                doomed.append(previous)
            }
            keep[key] = record
        }
        guard !doomed.isEmpty else { return 0 }

        do {
            try context.transaction {
                for record in doomed {
                    context.delete(record)
                }
                // 删了读数，指纹就变了。戳作废，下一次同步整份重折。
                MonthlyLedgerStore.invalidateStampWithoutSaving(in: context)
            }
        } catch {
            // 中途失败就整块回滚：删了一半读数、戳却还在，下一次开门会拿一份
            // 「按更多读数折出来的」账本当数，而它已经对不上库里的内容了。
            context.rollback()
            throw error
        }
        return doomed.count
    }
}
