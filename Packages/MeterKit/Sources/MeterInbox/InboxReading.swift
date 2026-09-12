import Foundation
import MeterCore

/// 用户投递进来的一条读数。
///
/// `currentSpendUSD` 的含义是**本月至今累计**，不是「今天花了多少」。
/// 这一条不许改；以后要加日粒度就在 `/v1` 之上另开字段和另开路径。
public struct InboxReading: Hashable, Sendable {
    public var providerID: ProviderID
    /// 这条读数归哪把投递 key。归属的唯一事实源——分发只认它，不认 `providerID`。
    public var ingestKeyID: String
    public var periodStart: Date
    public var currentSpendUSD: Money?
    /// 投递方最后一次覆盖写的时刻，由服务端盖章。
    /// 用它当 `Snapshot.fetchedAt`，界面上「多久前」才是投递的时间而不是取回的时间。
    public var reportedAt: Date

    public init(
        providerID: ProviderID,
        ingestKeyID: String,
        periodStart: Date,
        currentSpendUSD: Money?,
        reportedAt: Date
    ) {
        self.providerID = providerID
        self.ingestKeyID = ingestKeyID
        self.periodStart = periodStart
        self.currentSpendUSD = currentSpendUSD
        self.reportedAt = reportedAt
    }
}

/// 线上 JSON 的形状。金额是十进制字符串，不是 number —— 分位不许过 Double。
struct InboxReadingPayload: Decodable, Sendable {
    var ingestKeyID: String?
    var provider: String?
    var periodStart: String?
    var currentSpendUSD: String?
    var reportedAt: String?
}

struct InboxReadingsResponse: Decodable, Sendable {
    var readings: [InboxReadingPayload]?
}

/// 建信箱 / 签 key 的应答和客户端同仓同发布，缺字段就该在解码时炸成
/// `.malformedResponse`，不值得逐个 guard。
struct InboxProvisioningResponse: Decodable, Sendable {
    var mailbox: String
    var readKey: String
    var ingestKey: String
    var ingestKeyID: String
}

struct InboxIngestKeyResponse: Decodable, Sendable {
    var ingestKey: String
    var ingestKeyID: String
}

struct InboxIngestKeyListResponse: Decodable, Sendable {
    var keys: [InboxIngestKeyPayload]?
}

struct InboxIngestKeyPayload: Decodable, Sendable {
    var id: String?
    var label: String?
    var createdAt: String?
    var lastUsedAt: String?
}
