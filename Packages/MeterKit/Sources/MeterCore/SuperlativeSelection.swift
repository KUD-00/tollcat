import Foundation

/// 「本月之最」三块各自挑谁。**只挑，不写字**——名字、色、怎么念是上面那层的事。
///
/// 这三条规则曾经有两份，而且两份挑的不是同一个东西：Android 桥拿整月的
/// `changeRatio` 配上构成里第一家，等于把「总共涨了 12%」安在了最大那家头上。
/// 规则搬到这里之后，两侧连顺序都只有一份。
public enum SuperlativeSelection: Sendable {
    /// 三块在屏幕上的固定顺序。
    public static let order: [SuperlativeKind] = [.biggestRise, .biggestShare, .stalest]

    /// 涨得最多的那一份。只看正增长；并列取靠前的那个（下标小者），
    /// 这样同一份数据每次挑出来的是同一个。
    public static func biggestRise(changeRatios: [Double?]) -> Int? {
        var best: (index: Int, ratio: Double)?
        for (index, ratio) in changeRatios.enumerated() {
            guard let ratio, ratio > 0 else { continue }
            if best == nil || ratio > best!.ratio {
                best = (index, ratio)
            }
        }
        return best?.index
    }

    /// 占比最大的那一份。占比为 0 的不算——「占比最大 0%」不是一句话。
    public static func biggestShare(fractions: [Double]) -> Int? {
        var best: (index: Int, fraction: Double)?
        for (index, fraction) in fractions.enumerated() {
            guard fraction > 0 else { continue }
            if best == nil || fraction > best!.fraction {
                best = (index, fraction)
            }
        }
        return best?.index
    }

    /// 最久没刷的那一份。**只有一份接入时不给**：唯一的那份自然是最久的，
    /// 说出来没有信息量。没刷过的（nil）排最前。
    public static func stalest(lastRefreshedAt: [Date?]) -> Int? {
        guard lastRefreshedAt.count > 1 else { return nil }
        var best: (index: Int, at: Date)?
        for (index, at) in lastRefreshedAt.enumerated() {
            let stamp = at ?? .distantPast
            if best == nil || stamp < best!.at {
                best = (index, stamp)
            }
        }
        return best?.index
    }
}

public enum SuperlativeKind: String, Sendable, CaseIterable {
    case biggestRise
    case biggestShare
    case stalest
}
