import Foundation

/// 保序去重的账号名单：按首次插入顺序输出，重复插入是 no-op。
/// 「哪几家是估的」这类名单要保持发现顺序，Set 会打乱，Array.contains 是 O(n²)。
struct OrderedAccountSet: Sendable {
    private var seen: Set<AccountID> = []
    private(set) var ordered: [AccountID] = []

    init() {}

    mutating func insert(_ id: AccountID) {
        if seen.insert(id).inserted {
            ordered.append(id)
        }
    }
}
