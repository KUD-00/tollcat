import Foundation
import SwiftData
import MeterCore

/// 物化账本的读写口。
///
/// **写**只发生在账本可能变了的时候：落了新快照、删了账号、手填了花费、
/// 导入迁移包、清库。每一次只重折**被触及的那个账号**（它的 12 个月），
/// 而不是整份重来——那正是这一层存在的意义。
///
/// **读**是一次全表取（行数上限 12 × 账号数），交给 `LedgerProjection` 投影。
///
/// 所有写路径都必须过这里。散在各处各自记得更新账本，迟早有一条忘了，
/// 而忘了的表现是"某个月的数字莫名不动"——没有人会想到去查缓存。
///
/// ## 输入从库里来
///
/// 这里的每个写口都拿 `Scope`（哪些账号、哪些结束了、此刻、日历），**自己**去
/// `SnapshotLog` 取要折的读数、自己算指纹。调用方不再需要在内存里攥着整份日志
/// 递进来——那份日志正是这一层要让人不必持有的东西。
///
/// 每一次写都会把 `LedgerStampRecord` 换成新的指纹，而且和账本行**同一个事务**。
/// 「账本还作不作数」于是变成一次等值比较，不再是几条经验判据（见
/// `LedgerFingerprint` 里那段为什么）。
public enum MonthlyLedgerStore {
    /// 折一次账本的取景：**哪些账号算数**、哪些结束了、此刻是几点、用哪本日历。
    ///
    /// `accountIDs` 给 nil 表示库里盖过章的全部账号。主 App 传「还在用的」那一组
    /// （结束的也在，历史要留；真删的不在，它们的行是孤儿）。
    public struct Scope: Sendable {
        public var accountIDs: Set<AccountID>?
        public var endedAccounts: [AccountID: Date]
        public var now: Date
        public var calendar: Calendar

        public init(
            accountIDs: Set<AccountID>? = nil,
            endedAccounts: [AccountID: Date] = [:],
            now: Date,
            calendar: Calendar
        ) {
            self.accountIDs = accountIDs
            self.endedAccounts = endedAccounts
            self.now = now
            self.calendar = calendar
        }
    }

    // MARK: - 读

    /// 账本行整份。**遇到解不出来的行就作废戳并抛。**
    ///
    /// 坏行不能当不存在读过去：指纹比的是**输入**，一行解不出来时输入没变，
    /// `isInSync` 照样说「还作数」——那个账号那个月于是从合计里永久消失，
    /// 而且没有任何提示。作废戳之后下一次同步必定判失效、整份重折，
    /// 「重折一次就有了」这句话才成立。
    public static func all(calendar: Calendar, in context: ModelContext) throws -> [MonthlyRollup] {
        let records = try context.fetch(FetchDescriptor<MonthlyRollupRecord>())
        var rollups: [MonthlyRollup] = []
        rollups.reserveCapacity(records.count)
        var corrupt = 0
        for record in records {
            if let rollup = record.toDomain(calendar: calendar) {
                rollups.append(rollup)
            } else {
                corrupt += 1
            }
        }
        try invalidateStampForCorruptRows(corrupt, in: context)
        return rollups
    }

    /// 每账号此刻的状态。**按账号 id 排序**——展示层不该因为数据库返回顺序变了
    /// 就把余额告急那几行换个位置。
    public static func latest(in context: ModelContext) throws -> [AccountLatest] {
        let records = try context.fetch(FetchDescriptor<AccountLatestRecord>())
        let rows = records.compactMap { $0.toDomain() }
        try invalidateStampForCorruptRows(records.count - rows.count, in: context)
        return rows.sorted { $0.accountID.rawValue.uuidString < $1.accountID.rawValue.uuidString }
    }

    /// 读到坏行：戳作废（同一个 context、当场落盘）并抛出去。
    /// 上层保留上一份读模型 + 亮「读不出最新数据」，同步那一趟会把账本重折干净。
    private static func invalidateStampForCorruptRows(
        _ count: Int,
        in context: ModelContext
    ) throws {
        guard count > 0 else { return }
        invalidateStamp(in: context)
        // 戳没落盘的话，下一次开门又会读到同一批坏行、又抛一次，永远出不来。
        try context.save()
        throw PersistenceError.corruptLedgerRow(count: count)
    }

    /// 读模型整份。仪表盘那一屏的全部输入就是它——**没有 `[Snapshot]`**。
    public static func view(
        subscriptions: [MonthlySubscription],
        calendar: Calendar,
        in context: ModelContext
    ) throws -> LedgerView {
        LedgerView(
            rollups: try all(calendar: calendar, in: context),
            latest: try latest(in: context),
            subscriptions: subscriptions
        )
    }

    public static func isEmpty(in context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<MonthlyRollupRecord>()
        descriptor.fetchLimit = 1
        return ((try? context.fetch(descriptor)) ?? []).isEmpty
    }

    /// 账本还作不作数，以及**不作数到什么程度**。
    ///
    /// 分两档不是为了好看，是因为两档的代价差一个数量级：
    ///
    /// - `.staleInputs`：读数集合、结束账号、或者日历时区变了。月份边界、日桶、
    ///   每一行的钱都可能跟着变——只能整份重折。
    /// - `.staleToday`：**只有「今天」翻了页，而且还在同一个月**。过去月份的行不依赖
    ///   今天（`foldedAsOf` 是那个月的最后一瞬，同期窗口也在那个月里），只有当月
    ///   那一行要重折。每天第一次打开是这条路，而它以前走的是整份重折：解全库快照的
    ///   三个 blob、每账号 12 个月各折一遍——代价正比于刷新总次数。
    ///
    /// **跨月那一次不算 `.staleToday`。** 昨天的「上个月」是当月，折的是「本月至今」
    /// （`asOf = now`，只折到 17 号）；今天它成了过去月份，`asOf` 挪到月末最后一瞬，
    /// 数也从半个月变成整月——**每个账号的上月行都要重折**，不是只重折当月。
    /// 而且能回看的窗口整体前移一格，最老那个月的行要清掉。一年 12 次整份重折
    /// 换这两件事，值。
    ///
    /// 时区变了同样**不算** `.staleToday`：那会挪动月份边界和日桶，过去几个月的行
    /// 全都要重折。
    public enum SyncVerdict: Sendable, Equatable {
        case inSync
        case staleToday
        case staleInputs
    }

    /// **一次等值比较**：库里那份戳记着上次折叠吃进去的东西，这里从库里现算一份
    /// 同样的指纹比一比。指纹包含什么、为什么，见 `LedgerFingerprint`。
    ///
    /// 读库失败当**对不上**：宁可多折一次。
    public static func verdict(_ scope: Scope, in context: ModelContext) -> SyncVerdict {
        guard let wanted = try? fingerprint(scope, in: context) else { return .staleInputs }
        let hasReadings = !wanted.inputDigest.hasPrefix("\(LedgerFingerprint.format):0.")
        guard let stamp = stampRecord(in: context) else {
            // 没有戳：要么是空库（首装那一刻确实没有东西要折，算一致），
            // 要么是有行没戳（半边状态），后者一律当作不一致重折一遍。
            return (!hasReadings && isEmpty(in: context)) ? .inSync : .staleInputs
        }
        let stamped = stamp.fingerprint
        guard stamped.inputDigest == wanted.inputDigest, stamped.zone == wanted.zone else {
            return .staleInputs
        }
        guard stamped.day == wanted.day else {
            // 跨月要整份重折，见上面那段。同一个月里翻一天才走便宜的那条。
            let sameMonth = scope.calendar.isDate(
                stamped.day,
                equalTo: wanted.day,
                toGranularity: .month
            )
            return sameMonth ? .staleToday : .staleInputs
        }
        // 戳在、指纹也对，但一行都没有而库里有读数：只可能是撕裂的写入。
        // 白重折一次比留一份空账本便宜得多。
        if hasReadings, isEmpty(in: context) { return .staleInputs }
        return .inSync
    }

    /// 还作不作数。三档里只有 `.inSync` 算数——调用方要分档去问 `verdict`。
    public static func isInSync(_ scope: Scope, in context: ModelContext) -> Bool {
        verdict(scope, in: context) == .inSync
    }

    // MARK: - 写

    /// 整份重建。首次启动、清库之后、以及开发页那个「重建账本」按钮走它。
    ///
    /// **先折完再动库**，删和插在同一个事务里。反过来（先清空、再一行行插、
    /// 中间失败）会留下一份空账本，而空账本在屏幕上长得和「这个月花了 $0」
    /// 一模一样。
    @discardableResult
    public static func rebuildAll(_ scope: Scope, in context: ModelContext) throws -> Int {
        let snapshots = try SnapshotLog.snapshots(
            accountIDs: scope.accountIDs,
            calendar: scope.calendar,
            in: context
        )
        let rollups = LedgerSelfCheck.foldAll(
            snapshots: snapshots,
            now: scope.now,
            calendar: scope.calendar,
            endedAccounts: scope.endedAccounts
        )
        let latest = AccountLatest.reduceAll(
            snapshots: snapshots,
            calendar: scope.calendar
        ).values.sorted { $0.accountID.rawValue.uuidString < $1.accountID.rawValue.uuidString }
        let fingerprint = try fingerprint(scope, in: context)
        try inTransaction(context) {
            purgeWithoutSaving(in: context)
            for rollup in rollups {
                context.insert(try MonthlyRollupRecord(domain: rollup, calendar: scope.calendar))
            }
            for row in latest {
                context.insert(AccountLatestRecord(domain: row))
            }
            context.insert(LedgerStampRecord(fingerprint: fingerprint))
        }
        return rollups.count
    }

    /// 增量：一条新快照**落库之后**，只重折**它那个账号**——全部 12 个月。
    ///
    /// 省的是别的账号，不是月份。曾经只折「这条快照触及的那几个月」，结果增量和整份重折
    /// 对不上：没被触及的月份也依赖这个账号**最新那条**读数（没有账期覆盖的月份回落到它、
    /// `foldedThrough` 记的是它），换了最新一条它们就该变。逐月挑会在这里留一个「说对其实错」
    /// 的口子，而一个账号 12 个月的折叠在后台是几十毫秒的事，不值得为它冒这个险。
    /// 「增量 == 全量」于是是构造上成立的，有测试逐行比。
    ///
    /// 快照必须已经在库里——戳记的是库里整份输入的指纹，这条还没落就去戳，
    /// 戳会记成一份不存在的库，下一次开门立刻判成对不上、白重折一遍。
    public static func apply(_ snapshot: Snapshot, scope: Scope, in context: ModelContext) throws {
        guard let accountID = snapshot.accountID else { return }
        try rebuild(accountID: accountID, scope: scope, in: context)
    }

    /// 只重折**当月那一行**（每个账号一行）。跨天走这条。
    ///
    /// 过去月份的行不依赖「今天」，一行都不碰——它们的 `foldedAsOf` 是那个月的
    /// 最后一瞬，同期窗口也整个落在那个月里。折完统一盖一次戳：新的戳带着新的
    /// 「今天」，下一次开门才判得出 `.inSync`。
    @discardableResult
    public static func refoldCurrentMonth(_ scope: Scope, in context: ModelContext) throws -> Int {
        guard
            let thisMonthStart = scope.calendar.date(
                from: scope.calendar.dateComponents([.year, .month], from: scope.now)
            )
        else {
            return 0
        }
        let accountIDs = try scope.accountIDs ?? SnapshotLog.accountIDs(in: context)
        // **指纹只算一次。** 它是一次全表扫（快照表是全库最大的一张），
        // 每个账号各算一遍就是 N 倍——那会让「只重折当月」比整份重折还贵，
        // 而这条路存在的全部理由就是它更便宜。
        let fingerprint = try fingerprint(scope, in: context)
        var folded: [(accountID: AccountID, rollups: [MonthlyRollup], own: [Snapshot])] = []
        for accountID in accountIDs.sorted(by: { $0.rawValue.uuidString < $1.rawValue.uuidString }) {
            let own = try ownSnapshots(accountID: accountID, scope: scope, in: context)
            let rollups = LedgerFolder.fold(
                accountID: accountID,
                snapshots: own,
                now: scope.now,
                calendar: scope.calendar,
                months: [thisMonthStart],
                endedAccounts: scope.endedAccounts
            )
            guard !rollups.isEmpty else { continue }
            folded.append((accountID, rollups, own))
        }
        // 全部账号一个事务。逐账号各开一次的话，跨天那一趟中间任何一步失败都会留下
        // 「一半是今天折的、一半是昨天的」——而戳只有一个，说不清那是哪一份。
        try inTransaction(context) {
            // 跨月那一天窗口前移一格，最老那个月的行掉出去了。见 `purgeRowsOutOfWindow`。
            try purgeRowsOutOfWindow(scope, in: context)
            for entry in folded {
                try writeRows(entry.rollups, accountID: entry.accountID, scope: scope, in: context)
                try upsertLatest(
                    accountID: entry.accountID,
                    snapshots: entry.own,
                    scope: scope,
                    in: context
                )
            }
            // 一个账号都没有（或者都没有读数）时上面一次也没写，戳照样要盖：
            // 不盖的话每次开门都会再判一次 `.staleToday`、再空跑一遍。
            stamp(fingerprint, in: context)
        }
        return folded.count
    }

    /// 重折一个账号的指定月份（`months` 给 nil 折它的全部月份）。
    /// 这个账号的读数从库里取；折一个月仍然要看它的完整历史
    /// （「最新一条带明细的是哪条」「日表怎么压平」都依赖它）。
    ///
    /// **取数带下界。**「完整历史」里真正用得上的只有能回看的那 12 个月，再往前
    /// 一个月给日表和账期留余量；而这条路每次刷新每家都走一遍，不设下界的话
    /// 代价正比于这个账号刷过多少回。
    ///
    /// 下界之前**再补一条**：`prepaidConsumption` 的「月初锚点」和「最近一条带明细的」
    /// 都是 `last(where: fetchedAt <= …)`，各自只用得上一条。补上它，带下界折和
    /// 全史折逐行相同（`MonthlyLedgerStoreTests` 里有一条随机账本的等价测试）。
    public static func rebuild(
        accountID: AccountID,
        months: Set<Date>? = nil,
        scope: Scope,
        in context: ModelContext
    ) throws {
        let own = try ownSnapshots(accountID: accountID, scope: scope, in: context)
        let rollups = LedgerFolder.fold(
            accountID: accountID,
            snapshots: own,
            now: scope.now,
            calendar: scope.calendar,
            months: months,
            endedAccounts: scope.endedAccounts
        )
        guard !rollups.isEmpty else { return }
        let fingerprint = try fingerprint(scope, in: context)
        // **跨月那一次不盖章。** 这条路只重折**一个**账号，而跨月要重折的是每个账号的
        // 上月行（从「本月至今」变成整月）。盖了章 `isInSync` 就说是，随后那趟同步
        // 不会再来，别的账号的上月行会一直停在半个月——而屏幕上完全正常。
        // 不盖章的代价只是下一次同步整份重折一遍。
        let crossedMonth = stampRecord(in: context).map {
            !scope.calendar.isDate($0.day, equalTo: fingerprint.day, toGranularity: .month)
        } ?? false
        try inTransaction(context) {
            // 这一条也要清：刷新走的是这里，而它**会盖新的戳**——跨月之后第一次刷新
            // 若抢在同步之前，戳一盖就判成 `.inSync`，`refoldCurrentMonth` 再也不会跑，
            // 掉出窗口的行于是留到下一次 `.staleInputs` 为止。表只有 12 × 账号数行，
            // 多扫一遍不值一提。
            try purgeRowsOutOfWindow(scope, in: context)
            try writeRows(rollups, accountID: accountID, scope: scope, in: context)
            try upsertLatest(accountID: accountID, snapshots: own, scope: scope, in: context)
            // 增量重折的**只是这一个账号**，但戳记的是整份输入。
            // 这一步之后 `isInSync` 必须说是——否则每次刷新完都会紧接着白重折一次。
            // 跨月那一次除外（见上面）：那时宁可白重折，也不能说「都对得上」。
            if !crossedMonth {
                stamp(fingerprint, in: context)
            }
        }
    }

    /// 清掉**掉出能回看窗口**的行。**调用方负责事务。**
    ///
    /// `rebuildAll` 是「先清空再重铺」，所以它天然不会留下窗口外的行；增量那两条
    /// （`rebuild` / `refoldCurrentMonth`）只 upsert，不删。跨月那一天窗口整体前移一格，
    /// 最老那个月的行就此没人再碰——而它**读得出来**：
    ///
    /// - `LedgerView.dailyTotals()` 和 `dailySpend(for:)` 不按窗口筛，热力图会多出一张
    ///   13 个月前的月卡片；
    /// - `LedgerProjection.earliestMonthsBack` 拿它当「最老有读数的月」，「全期间」
    ///   于是写成「自 12 个月前起」，而真实数据只有三个月；
    /// - 预充值跑道的基准日在 `dailyBalanceUSD` 里挑「7 天前或更早最近的一天」，
    ///   多留几个月就多几个候选。
    ///
    /// 合计不受影响（`LedgerProjection` 按月首筛过一遍），所以这件事只会在
    /// 那三处露头——正是最不容易联想到「账本里有孤儿行」的地方。
    ///
    /// 按月删而不按账号删：真删掉的账号留下的孤儿行也一起走。
    private static func purgeRowsOutOfWindow(_ scope: Scope, in context: ModelContext) throws {
        guard
            let oldestMonthStart = LedgerFolder.allMonthStarts(
                now: scope.now,
                calendar: scope.calendar
            ).first
        else {
            return
        }
        let oldest = MonthKey(oldestMonthStart, calendar: scope.calendar)
        let year = oldest.year
        let month = oldest.month
        let predicate = #Predicate<MonthlyRollupRecord> { row in
            row.monthYear < year || (row.monthYear == year && row.monthOfYear < month)
        }
        for row in try context.fetch(FetchDescriptor<MonthlyRollupRecord>(predicate: predicate)) {
            context.delete(row)
        }
    }

    /// 把折好的行写回这个账号名下。**调用方负责事务。**
    private static func writeRows(
        _ rollups: [MonthlyRollup],
        accountID: AccountID,
        scope: Scope,
        in context: ModelContext
    ) throws {
        let raw = accountID.rawValue.uuidString
        let existing = try context.fetch(
            FetchDescriptor<MonthlyRollupRecord>(
                predicate: #Predicate { $0.accountIDRaw == raw }
            )
        )
        var byMonth = Dictionary(grouping: existing, by: \.monthKey)
        for rollup in rollups {
            let key = MonthKey(rollup.monthStart, calendar: scope.calendar)
            if let matches = byMonth[key], let first = matches.first {
                try first.apply(rollup, calendar: scope.calendar)
                // 同一个 (账号, 月) 只该有一行。真出现重复就地清掉，
                // 留着会让读出来的总数凭空翻倍——而那看起来完全正常。
                for extra in matches.dropFirst() { context.delete(extra) }
                byMonth[key] = [first]
            } else {
                context.insert(try MonthlyRollupRecord(domain: rollup, calendar: scope.calendar))
            }
        }
    }

    /// 这个账号要折的那一段读数：下界 + 下界之前最近的那一条。见 `rebuild`。
    private static func ownSnapshots(
        accountID: AccountID,
        scope: Scope,
        in context: ModelContext
    ) throws -> [Snapshot] {
        guard let since = foldLowerBound(now: scope.now, calendar: scope.calendar) else {
            return try SnapshotLog.snapshots(
                accountIDs: [accountID],
                calendar: scope.calendar,
                in: context
            )
        }
        var own = try SnapshotLog.snapshots(
            accountIDs: [accountID],
            since: since,
            calendar: scope.calendar,
            in: context
        )
        if let anchor = try SnapshotLog.latestBefore(
            accountID: accountID,
            before: since,
            calendar: scope.calendar,
            in: context
        ) {
            own.insert(anchor, at: 0)
        }
        return own
    }

    /// 折叠取数的下界：能回看的最老那个月的月首，再往前一个月。
    ///
    /// 往前一个月是给账期和日表留余量（一条跨月的读数、月初那几天的日桶）。
    /// 再往前的那一条由 `latestBefore` 单独补，不用把整段历史都拉进来。
    static func foldLowerBound(now: Date, calendar: Calendar) -> Date? {
        guard let oldest = LedgerFolder.allMonthStarts(now: now, calendar: calendar).first else {
            return nil
        }
        return calendar.date(byAdding: .month, value: -1, to: oldest)
    }

    /// 「此刻的状态」跟着一起更新。**和账本行同一次写入**——分成两步、靠调用方
    /// 记得配对，迟早有一条路只做了一半，而那时界面完全正常，只是余额停在昨天。
    private static func upsertLatest(
        accountID: AccountID,
        snapshots: [Snapshot],
        scope: Scope,
        in context: ModelContext
    ) throws {
        guard
            let latest = AccountLatest.reduce(
                accountID: accountID,
                snapshots: snapshots,
                calendar: scope.calendar
            )
        else {
            return
        }
        let raw = accountID.rawValue.uuidString
        let existing = try context.fetch(
            FetchDescriptor<AccountLatestRecord>(predicate: #Predicate { $0.accountIDRaw == raw })
        )
        if let first = existing.first {
            first.apply(latest)
            for extra in existing.dropFirst() { context.delete(extra) }
        } else {
            context.insert(AccountLatestRecord(domain: latest))
        }
    }

    /// 账号没了，它的账也跟着没。留着会变成一笔查无此人的钱。
    ///
    /// 戳一起作废：这里不重算指纹，而记着一个已经不成立的指纹比没有戳危险得多。
    /// 下一次读会重折一遍。
    public static func delete(accountID: AccountID, in context: ModelContext) throws {
        try inTransaction(context) {
            removeWithoutSaving(accountIDs: [accountID], in: context)
        }
    }

    public static func deleteAll(in context: ModelContext) throws {
        try inTransaction(context) {
            purgeWithoutSaving(in: context)
        }
    }

    /// 不 save 的删账号行。给自己管事务的调用方（清空一家、导入迁移包）用：
    /// 它们删快照的那一刻账本就该跟着走，而且要和那次删除落在同一个 save 里。
    public static func removeWithoutSaving(accountIDs: Set<AccountID>, in context: ModelContext) {
        let raws = Array(accountIDs.map(\.rawValue.uuidString))
        let rows = (try? context.fetch(
            FetchDescriptor<MonthlyRollupRecord>(predicate: #Predicate { raws.contains($0.accountIDRaw) })
        )) ?? []
        let latestRows = (try? context.fetch(
            FetchDescriptor<AccountLatestRecord>(predicate: #Predicate { raws.contains($0.accountIDRaw) })
        )) ?? []
        for row in rows { context.delete(row) }
        for row in latestRows { context.delete(row) }
        invalidateStamp(in: context)
    }

    /// 不 save 的清空。同上，只在调用方自己的事务里用。
    public static func purgeWithoutSaving(in context: ModelContext) {
        for row in (try? context.fetch(FetchDescriptor<MonthlyRollupRecord>())) ?? [] {
            context.delete(row)
        }
        for row in (try? context.fetch(FetchDescriptor<AccountLatestRecord>())) ?? [] {
            context.delete(row)
        }
        invalidateStamp(in: context)
    }

    // MARK: - 指纹与戳

    /// 库里此刻这份输入的指纹。戳和比都从这里算，两边不可能各说各话。
    static func fingerprint(_ scope: Scope, in context: ModelContext) throws -> LedgerFingerprint {
        LedgerFingerprint.make(
            entries: try SnapshotLog.fingerprintEntries(
                accountIDs: scope.accountIDs,
                calendar: scope.calendar,
                in: context
            ),
            endedAccounts: scope.endedAccounts,
            now: scope.now,
            calendar: scope.calendar
        )
    }

    /// 全库一行。多于一行只可能是并发写撕出来的——当作「没有戳」，重折一遍。
    ///
    /// 写路串行化（见 `LedgerCache` 里那个单写者）之后**正常路径到不了这里**；
    /// 这一支留着是因为库文件是上一版写的时候可能已经撕过一次。
    private static func stampRecord(in context: ModelContext) -> LedgerStampRecord? {
        let rows = (try? context.fetch(FetchDescriptor<LedgerStampRecord>())) ?? []
        guard rows.count <= 1 else { return nil }
        return rows.first
    }

    private static func stamp(_ fingerprint: LedgerFingerprint, in context: ModelContext) {
        let rows = (try? context.fetch(FetchDescriptor<LedgerStampRecord>())) ?? []
        if let first = rows.first {
            first.apply(fingerprint)
            for extra in rows.dropFirst() { context.delete(extra) }
        } else {
            context.insert(LedgerStampRecord(fingerprint: fingerprint))
        }
    }

    /// 不 save 的作废戳。给自己管事务的调用方（压缩）用。
    static func invalidateStampWithoutSaving(in context: ModelContext) {
        invalidateStamp(in: context)
    }

    private static func invalidateStamp(in context: ModelContext) {
        for row in (try? context.fetch(FetchDescriptor<LedgerStampRecord>())) ?? [] {
            context.delete(row)
        }
    }

    // MARK: - 事务

    /// 账本三张表（行、此刻、戳）**必须一起落**。中途失败就整块回滚，
    /// 留一份旧的、对不上的账本——下一次读会发现指纹不符再重折一遍——
    /// 而不是留一份空的。空账本在屏幕上和「这个月花了 $0」长得一模一样。
    private static func inTransaction(
        _ context: ModelContext,
        _ body: () throws -> Void
    ) throws {
        do {
            try context.transaction(block: body)
        } catch {
            context.rollback()
            throw error
        }
    }
}
