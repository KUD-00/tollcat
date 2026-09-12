import Foundation

/// 冷启动要不要弹、弹哪一篇。时间以外的条件都从参数进来，方便测。
enum UsageGuideLaunch {
    /// 冷启动弹一篇。暂时关：设置里还能回看全文，截图钩子 `-open-usage-guide=` 仍能强制弹。
    static let presentsOnLaunch = false

    static func nextUnseen(
        hasCompletedOnboarding: Bool,
        completedOnboardingThisLaunch: Bool,
        seenIDs: Set<String>,
        skipDrawer: Bool,
        presentsOnLaunch: Bool = Self.presentsOnLaunch
    ) -> UsageGuideID? {
        guard hasCompletedOnboarding else { return nil }
        guard !completedOnboardingThisLaunch else { return nil }
        guard presentsOnLaunch else { return nil }
        guard !skipDrawer else { return nil }
        return UsageGuideID.allCases.first { !seenIDs.contains($0.rawValue) }
    }

    static func hasUnseen(seenIDs: Set<String>) -> Bool {
        UsageGuideID.allCases.contains { !seenIDs.contains($0.rawValue) }
    }
}
