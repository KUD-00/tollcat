import Foundation

/// 一个账号的**原始读数**，按范围取出来的一段。
///
/// ## 这是门上明确开的那个口，不是漏洞
///
/// 展示路径拿不到快照日志——除了这里。区别在于它有名字、有范围、有理由：
/// 详情页那几张图展示的就是「这家自己报过什么」，那是原始观测，不是折算结果。
/// 物化账本回答不了这个问题，**也不该回答**：账本是把观测压平之后的账，
/// 而这一页要看的正是被压平之前的样子。
///
/// 开口和漏洞的差别只有一条：**范围由门决定，不由调用方决定**。
/// `dashboard.snapshots` 是「全都给你，自己挑」；`readings(for:range:)` 是
/// 「你问的那一段，给你」。前者让每个调用方各自决定"哪条算数"，那条规则于是有了
/// 十几个出处；后者只有一个。
///
/// 做成集合而不是裸数组，是为了让这份"已经限定过范围"的事实跟着值一起走——
/// 拿到它的人看得见自己拿到的是哪一段，也没法顺手把它当成全部。
public struct ReadingSeries: RandomAccessCollection, Sendable {
    /// 问的是哪几个账号。同一家有两份账号时，详情页看的是两份的并集——
    /// 用单个账号会把「两份账号」过滤成空，整段历史消失。
    public let accountIDs: Set<AccountID>
    /// 问的是哪一段，已经解析成具体日期。`nil` 表示「这个账号手上的全部读数」——
    /// 详情页那份「历史读数」列表要的就是它。
    ///
    /// 存解析后的区间而不是 `7 天 / 30 天` 那个枚举：那个枚举住在持久化层，
    /// 而这里是领域层；更重要的是，日期把「到底取了哪一段」写在了值上面，
    /// 而枚举还要再解析一次才知道。
    public let interval: DateInterval?

    private let readings: [Snapshot]

    public init(accountIDs: Set<AccountID>, interval: DateInterval?, readings: [Snapshot]) {
        self.accountIDs = accountIDs
        self.interval = interval
        // 时间升序落定在这里，调用方不必各排各的——排序方向不一致过一次，
        // 「最新一条」就会在两个页面上指向不同的读数。
        self.readings = readings.sorted { $0.fetchedAt < $1.fetchedAt }
    }

    public var startIndex: Int { readings.startIndex }
    public var endIndex: Int { readings.endIndex }
    public subscript(position: Int) -> Snapshot { readings[position] }
    public func index(after i: Int) -> Int { readings.index(after: i) }
    public func index(before i: Int) -> Int { readings.index(before: i) }
}
