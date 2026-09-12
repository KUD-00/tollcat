import Foundation

/// 反馈分类。rawValue 直接上线，Worker 那边有一份同名集合。
///
/// 「缺哪家服务」单独列一类，不是为了好看：这个 App 的价值上限就是接了多少家，
/// 而哪家值得接只有用户知道。把它从「想法」里拆出来，是为了让它好数。
public enum FeedbackCategory: String, CaseIterable, Hashable, Sendable, Codable {
    case bug
    case idea
    case provider
    case other

    public static let `default` = FeedbackCategory.bug
}
