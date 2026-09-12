import Foundation

/// 总数能不能当账单信，取决于最弱的那一家，所以精度必须能合并。
/// 只做内部推理（估算名单、诚实性限定语），不再产生任何视觉标记。
public enum Confidence: String, Hashable, Sendable, Codable {
    case exact
    case estimated
    case partial

    /// 任一家估算，总数就降为估算；否则有一家不全就降为不全。
    public func merging(_ other: Confidence) -> Confidence {
        switch (self, other) {
        case (.estimated, _), (_, .estimated):
            return .estimated
        case (.partial, _), (_, .partial):
            return .partial
        case (.exact, .exact):
            return .exact
        }
    }
}
