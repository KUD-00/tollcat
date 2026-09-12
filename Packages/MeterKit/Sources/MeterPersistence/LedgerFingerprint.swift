import Foundation
import MeterCore

/// 账本这份缓存**是从什么折出来的**。
///
/// ## 为什么不是几条经验判据
///
/// 以前「账本还作不作数」靠三条代理去猜：最新那条快照的 `fetchedAt`、账号集合、
/// 当月那一行是不是今天折的。三条各有一个漏，而且都漏在同一个方向上——
/// **说对，其实错**：
///
/// - 补一条**更老**的读数（回填历史、信箱送来一条过去时刻的），最大时间戳不变；
/// - 当月**还没有行**（月初第一次打开、时区一改月份边界整体挪位），
///   第三条 `allSatisfy` 在空集合上恒真；
/// - 时区变了，月首、日桶、「今天」全都换了位置，三条一条都察觉不到。
///
/// 这三种情况下屏幕上的数字全是错的，而且看起来完全正常。
/// 代理判据的毛病不是不够多，是**它们不是输入本身**——再加一条只会再多一个漏。
///
/// ## 所以这里不猜
///
/// 把折叠真正吃进去的东西摘要下来，比对的是输入本身。输入只有四样：读数集合、
/// 结束过的账号、当作「今天」的那一天、以及日历时区（同期窗口按它切）。
/// 订阅**不在**里面——它不进折叠，是读的时候现算的。
///
/// ## 从库里算，不从内存里算
///
/// 指纹的输入是 `Entry`——一条读数在折叠眼里的身份，只有几列标量，**没有 blob**。
/// `SnapshotLog.fingerprintEntries` 用 `propertiesToFetch` 只取这几列，于是算一次
/// 指纹不需要把几千条快照的日表解出来，也不需要谁在内存里攥着整份日志。
/// 戳的时候和比的时候都从同一张表算，两边不可能各说各话。
///
/// 新增一种会影响折叠结果的输入时，加进 `make` 里；漏加的表现是「某个数字莫名
/// 不动」，不是崩溃，所以那份清单要跟着折叠一起改。
public struct LedgerFingerprint: Equatable, Sendable {
    /// 摘要格式版本。改了 `Entry` 里进摘要的字段、或者账本行的落盘形状，就把它加一——
    /// 旧戳从此永远对不上，账本会被整份重折，而不是拿一份按旧规矩折的账当数。
    ///
    /// `v2` → `v3`：账期端点改按日历分量进摘要（不再是瞬间）、同期窗口的终点
    /// 改成按日截断。两样都会改变折出来的钱，旧戳一律作废。
    public static let format = "v3"

    /// 一条读数在折叠眼里的身份。
    ///
    /// **金额本身不进摘要**，只进「有没有」。快照表是只增不改的：`SnapshotWriter`
    /// 是唯一的门，而它只 `insert`。要改一条读数的金额只能删了重写，
    /// 而那会同时改掉条数和取数时刻——摘要照样会变。
    ///
    /// 不含任何 blob（日表、钱包、明细）：它们是「这条读数带了什么」，不是「这是哪条读数」，
    /// 而只增不改的表里前者由后者唯一决定。不读 blob 才能让指纹便宜到每次开门都算一遍。
    public struct Entry: Sendable {
        public var accountID: UUID?
        public var providerID: String
        public var kind: String
        public var source: String
        public var fetchedAt: Date
        /// 账期端点按**日历分量**进摘要，不按瞬间。
        ///
        /// 摘要要回答的是「这条读数在折叠眼里变没变」，而折叠看的是账期落在
        /// 日历上的哪一天（见 `Snapshot.periodStart`）。混进时刻的话，同一份
        /// 数据在换时区之后摘要会变、而它本该只随日历分量变；分量解不出来
        /// （旧行的坏值）是 nil，`fold` 会把它和「有分量」区分开。
        public var periodStart: DayKey?
        public var periodEnd: DayKey?
        public var chargeDayOfMonth: Int?
        public var freeQuotaUsedRatio: Double?
        public var hasCurrentSpend: Bool
        public var hasBalance: Bool
        public var hasCommitted: Bool
        public var hasConverted: Bool

        public init(
            accountID: UUID?,
            providerID: String,
            kind: String,
            source: String,
            fetchedAt: Date,
            periodStart: DayKey?,
            periodEnd: DayKey?,
            chargeDayOfMonth: Int?,
            freeQuotaUsedRatio: Double?,
            hasCurrentSpend: Bool,
            hasBalance: Bool,
            hasCommitted: Bool,
            hasConverted: Bool
        ) {
            self.accountID = accountID
            self.providerID = providerID
            self.kind = kind
            self.source = source
            self.fetchedAt = fetchedAt
            self.periodStart = periodStart
            self.periodEnd = periodEnd
            self.chargeDayOfMonth = chargeDayOfMonth
            self.freeQuotaUsedRatio = freeQuotaUsedRatio
            self.hasCurrentSpend = hasCurrentSpend
            self.hasBalance = hasBalance
            self.hasCommitted = hasCommitted
            self.hasConverted = hasConverted
        }

        /// `calendar` 是把域层那两个 `Date` 翻回日历分量用的——和落盘时那本一致，
        /// 于是「从库里算」和「从内存里算」给出同一个摘要。
        public init(_ snapshot: Snapshot, calendar: Calendar) {
            self.init(
                accountID: snapshot.accountID?.rawValue,
                providerID: snapshot.providerID.rawValue,
                kind: snapshot.kind.rawValue,
                source: snapshot.source.rawValue,
                fetchedAt: snapshot.fetchedAt,
                periodStart: DayKey(snapshot.periodStart, calendar: calendar),
                periodEnd: DayKey(snapshot.periodEnd, calendar: calendar),
                chargeDayOfMonth: snapshot.chargeDayOfMonth,
                freeQuotaUsedRatio: snapshot.freeQuotaUsedRatio,
                hasCurrentSpend: snapshot.currentSpendUSD != nil,
                hasBalance: snapshot.balanceUSD != nil,
                hasCommitted: snapshot.committedMonthlyUSD != nil,
                hasConverted: snapshot.converted != nil
            )
        }
    }

    /// 读数集合 + 结束账号的摘要，带格式版本。
    public let inputDigest: String
    /// 折的时候把哪一天当「今天」。同期比的是「上个月到今天为止」，跨天就过期。
    public let day: Date
    /// 历法 + 时区。同期窗口、「今天」都按它切。日桶和月份存的是分量（`DayKey`），
    /// 不随它变，但折叠时那些分量落到哪一刻仍由它决定。
    public let zone: String

    public init(inputDigest: String, day: Date, zone: String) {
        self.inputDigest = inputDigest
        self.day = day
        self.zone = zone
    }

    /// 这一步**每次读账本都要跑**（`isInSync`），而快照表是全库最大的一张，
    /// 装久了几万条。所以它必须是：一趟、不排序、不建字符串、不分配。
    ///
    /// 做法是把每条读数折成一个 64 位数，再用（条数, 异或, 求和）三样聚起来。
    /// 三样合起来对顺序不敏感（拿到读数的顺序不该改变结论），
    /// 而增删改任何一条都会同时动到求和与条数。
    public static func make(
        entries: [Entry],
        endedAccounts: [AccountID: Date],
        now: Date,
        calendar: Calendar
    ) -> LedgerFingerprint {
        var count: UInt64 = 0
        var xor: UInt64 = 0
        var sum: UInt64 = 0
        for entry in entries {
            let hash = fold(entry)
            count &+= 1
            xor ^= hash
            sum = sum &+ hash
        }
        var endedCount: UInt64 = 0
        var endedXor: UInt64 = 0
        var endedSum: UInt64 = 0
        for (accountID, endedAt) in endedAccounts {
            var hash: UInt64 = 0x9e3779b97f4a7c15
            mix(&hash, accountID.rawValue)
            mix(&hash, endedAt.timeIntervalSinceReferenceDate.bitPattern)
            endedCount &+= 1
            endedXor ^= hash
            endedSum = endedSum &+ hash
        }
        return LedgerFingerprint(
            inputDigest: "\(format):\(count).\(hex(xor)).\(hex(sum))"
                + "/\(endedCount).\(hex(endedXor)).\(hex(endedSum))",
            day: calendar.startOfDay(for: now),
            zone: "\(calendar.identifier)|\(calendar.timeZone.identifier)"
        )
    }

    /// 内存里已经有域对象时的便利入口。和从库里取的 `Entry` 走同一个 `fold`，
    /// 所以两条路对同一批读数给出同一个指纹。
    public static func make(
        snapshots: [Snapshot],
        endedAccounts: [AccountID: Date],
        now: Date,
        calendar: Calendar
    ) -> LedgerFingerprint {
        make(
            entries: snapshots.map { Entry($0, calendar: calendar) },
            endedAccounts: endedAccounts,
            now: now,
            calendar: calendar
        )
    }

    private static func fold(_ entry: Entry) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        if let accountID = entry.accountID {
            mix(&hash, accountID)
        } else {
            mix(&hash, 0xdead_beef_dead_beef)
        }
        mix(&hash, text: entry.providerID)
        mix(&hash, text: entry.kind)
        mix(&hash, text: entry.source)
        mix(&hash, entry.fetchedAt.timeIntervalSinceReferenceDate.bitPattern)
        // 账期端点混的是年月日三个整数，不是瞬间：见 `Entry.periodStart`。
        mix(&hash, day: entry.periodStart)
        mix(&hash, day: entry.periodEnd)
        mix(&hash, UInt64(bitPattern: Int64(entry.chargeDayOfMonth ?? -1)))
        mix(&hash, (entry.freeQuotaUsedRatio ?? .nan).bitPattern)
        // 「有没有这一格」和「这一格是多少」是两件事——前者会改变折出哪几类事实。
        var presence: UInt64 = 0
        if entry.hasCurrentSpend { presence |= 1 }
        if entry.hasBalance { presence |= 2 }
        if entry.hasCommitted { presence |= 4 }
        if entry.hasConverted { presence |= 8 }
        mix(&hash, presence)
        return hash
    }

    /// splitmix64。要的是「一位变，整片变」，而且**跨进程稳定**——
    /// 不能用 `Hasher`：它每次启动换种子，戳写下去下次开就对不上了。
    @inline(__always)
    private static func mix(_ hash: inout UInt64, _ value: UInt64) {
        var z = (hash ^ value) &+ 0x9e37_79b9_7f4a_7c15
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        hash = z ^ (z >> 31)
    }

    /// 分量解不出来（旧行的坏值）用一个不可能是合法日期的哨兵，
    /// 免得「没有分量」和「1970-01-01」撞成同一个摘要。
    @inline(__always)
    private static func mix(_ hash: inout UInt64, day: DayKey?) {
        guard let day else {
            mix(&hash, 0xffff_ffff_ffff_ffff)
            return
        }
        mix(&hash, UInt64(bitPattern: Int64(day.year)))
        mix(&hash, UInt64(bitPattern: Int64(day.month)))
        mix(&hash, UInt64(bitPattern: Int64(day.day)))
    }

    @inline(__always)
    private static func mix(_ hash: inout UInt64, _ uuid: UUID) {
        let bytes = uuid.uuid
        var low: UInt64 = 0
        var high: UInt64 = 0
        withUnsafeBytes(of: bytes) { raw in
            low = raw.loadUnaligned(fromByteOffset: 0, as: UInt64.self)
            high = raw.loadUnaligned(fromByteOffset: 8, as: UInt64.self)
        }
        mix(&hash, low)
        mix(&hash, high)
    }

    /// 短字符串（rawValue）走 FNV-1a：只遍历 UTF-8，不分配。
    @inline(__always)
    private static func mix(_ hash: inout UInt64, text: String) {
        var value: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
        }
        mix(&hash, value)
    }

    private static func hex(_ value: UInt64) -> String {
        String(value, radix: 16)
    }
}
