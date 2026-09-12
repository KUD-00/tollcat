import Foundation

/// 更新后第一次冷启动要不要弹抽屉、弹哪几条。
///
/// 判据全部从参数进来：这里不许出现 `Date()`、`Bundle.main`、`UserDefaults`——
/// `scripts/check-source-invariants.py` 的 `check_changelog` 按这三个词扫。
/// 抽屉只有一次机会，测不住就会漂。
enum WhatsNewLaunch {
    /// 待弹的条目，新的在上。空数组 = 不弹。
    ///
    /// 跳版会合并成一张：从 1.1.0 一路到 1.3.0，这里返回 1.2.0 和 1.3.0 里
    /// **值得打断**且**这一端上过车**的那些，由抽屉决定谁当 hero。
    static func pending(
        entries: [WhatsNewEntry] = WhatsNewCatalog.entries,
        currentVersion: String,
        lastSeenVersion: String,
        platform: WhatsNewPlatform = .current,
        hasCompletedOnboarding: Bool,
        completedOnboardingThisLaunch: Bool,
        skipDrawer: Bool
    ) -> [WhatsNewEntry] {
        guard hasCompletedOnboarding, !completedOnboardingThisLaunch, !skipDrawer else {
            return []
        }
        // 首装不弹：没用过的 App 谈不上「变化」。冷启动那次会静默把 lastSeen 推到当前版本。
        guard !lastSeenVersion.isEmpty else { return [] }
        guard let current = ReleaseVersion(currentVersion),
              let lastSeen = ReleaseVersion(lastSeenVersion),
              lastSeen < current
        else { return [] }
        return entries.filter { entry in
            guard entry.showsDrawer, entry.platforms.contains(platform) else { return false }
            guard let version = ReleaseVersion(entry.version) else { return false }
            return version > lastSeen && version <= current
        }
    }

    /// 这一版的打断机会用掉了，把「看到哪一版」推到当前版本。
    ///
    /// **弹没弹都推进。**它的语义是「机会用掉了」，不是「读过了」：否则连着三个
    /// 安静的热修复会攒出一张三段的抽屉，正好是最不该打断的那一次。
    /// 只前进——降级安装不会把说明再放一遍。
    static func advanced(lastSeenVersion: String, currentVersion: String) -> String {
        guard let current = ReleaseVersion(currentVersion) else { return lastSeenVersion }
        guard let lastSeen = ReleaseVersion(lastSeenVersion) else { return currentVersion }
        return lastSeen >= current ? lastSeenVersion : currentVersion
    }

    /// 设置 → 关于 → 更新说明 的全量列表：这一端能看到的所有条目，不管弹没弹。
    static func history(
        entries: [WhatsNewEntry] = WhatsNewCatalog.entries,
        platform: WhatsNewPlatform = .current
    ) -> [WhatsNewEntry] {
        entries.filter { $0.platforms.contains(platform) }
    }
}
