import Foundation
import MeterCore

/// 单家刷新结果。失败不能把上次成功的数清掉，只能在旁边标陈旧。
public enum ProviderDataMark: String, Sendable, Hashable {
    case current
    case stale
    case failed
}
