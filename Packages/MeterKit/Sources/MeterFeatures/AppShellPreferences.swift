import Foundation
import Observation
import SwiftUI
import MeterPersistence

/// 「壳」记着的那几件事：走没走过开场、看过哪几篇利用指南、更新说明看到哪一版、
/// 藏不藏猫、Mac 菜单栏露什么。
///
/// ## 为什么从 `DashboardModel` 里搬出来
///
/// 这五样和账单一个字的关系都没有：不读快照、不碰账本、不参与折算，
/// 落盘也只是 `AppPreferences` 里的五个格子。它们待在仪表模型里的唯一理由是
/// 「当时那儿有一个 `preferences`」——而每多一样这种东西，
/// 「测一个开场逻辑要先造 `ModelContainer` 加全部 provider」就更真一分。
///
/// 搬出来之后：这一组自己一个 `@Observable`，只依赖 `DashboardPreferences`；
/// 想验收「更新说明什么时候弹」不必先有一屏仪表盘。
///
/// ## 边界
///
/// 只收「壳的记忆」——一次性的、和钱无关的、用户不会去核对的那种状态。
/// 取景框、展示货币、版式**不在这里**：它们改的是屏幕上那个数怎么算、怎么写，
/// 属于仪表盘本身。判据是「改了它，账单数字会不会变」。
@MainActor
@Observable
public final class AppShellPreferences {
    private let preferences: DashboardPreferences

    /// 走完过开场。`-skip-onboarding` 也算走完（截图和 UI 冒烟要直接落到主屏）。
    public private(set) var hasCompletedOnboarding: Bool
    /// 已经看过的利用指南。冷启动弹窗读它。
    public private(set) var seenUsageGuideIDs: Set<String>
    /// 更新说明抽屉「看到哪一版」。空串 = 还没记过（首装）。只前进。
    public private(set) var lastSeenWhatsNewVersion: String
    /// 设置「打开猫猫」关着，或启动参数 `-hide-cat`。只藏猫。
    public private(set) var hidesCat: Bool
    /// Mac 菜单栏露什么。默认只露猫；金额点开才看得到。iPhone / iPad 不读它。
    public private(set) var menuBarStyle: MenuBarStyle

    init(preferences: DashboardPreferences) {
        self.preferences = preferences
        let stored = preferences.current
        self.hasCompletedOnboarding = stored.hasCompletedOnboarding
            || FeatureLaunchArguments.skipOnboarding
        self.seenUsageGuideIDs = Set(stored.seenUsageGuideIDs)
        self.lastSeenWhatsNewVersion = stored.lastSeenWhatsNewVersion
        self.hidesCat = FeatureLaunchArguments.hidesCat || stored.hidesCat
        self.menuBarStyle = FeatureLaunchArguments.menuBarStyle
            .flatMap(MenuBarStyle.init(rawValue:)) ?? stored.menuBarStyle
    }

    /// 迁移包导进来之后重读。启动参数的覆盖**不再套用**——那几个只服务这一次启动的验收，
    /// 而这时候用户手上是刚搬过来的真数据。
    func reload() {
        let stored = preferences.current
        hasCompletedOnboarding = stored.hasCompletedOnboarding
        seenUsageGuideIDs = Set(stored.seenUsageGuideIDs)
        lastSeenWhatsNewVersion = stored.lastSeenWhatsNewVersion
        hidesCat = stored.hidesCat
        menuBarStyle = stored.menuBarStyle
    }

    // MARK: - 开场

    public func completeOnboarding() {
        hasCompletedOnboarding = true
        preferences.update { $0.hasCompletedOnboarding = true }
    }

    public func replayOnboarding() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            hasCompletedOnboarding = false
        }
        preferences.update { $0.hasCompletedOnboarding = false }
    }

    // MARK: - 利用指南

    public var hasUnseenUsageGuides: Bool {
        UsageGuideLaunch.hasUnseen(seenIDs: seenUsageGuideIDs)
    }

    public func markUsageGuideSeen(_ id: String) {
        guard !id.isEmpty, !seenUsageGuideIDs.contains(id) else { return }
        preferences.update { $0.seenUsageGuideIDs.append(id) }
        seenUsageGuideIDs = Set(preferences.current.seenUsageGuideIDs)
    }

    public func resetUsageGuides() {
        preferences.update { $0.seenUsageGuideIDs = [] }
        seenUsageGuideIDs = []
    }

    // MARK: - 更新说明

    /// 抽屉的打断机会用掉了：把「看到哪一版」推到当前版本。
    ///
    /// **弹没弹都调。**语义是「这一版的机会用完了」，不是「读过了」——否则连着几个
    /// 安静的热修复会攒出一张多段抽屉，正好是最不该打断的那一次。
    public func markWhatsNewSeen(currentVersion: String) {
        let advanced = WhatsNewLaunch.advanced(
            lastSeenVersion: lastSeenWhatsNewVersion,
            currentVersion: currentVersion
        )
        guard advanced != lastSeenWhatsNewVersion else { return }
        preferences.update { $0.lastSeenWhatsNewVersion = advanced }
        lastSeenWhatsNewVersion = advanced
    }

    #if DEBUG
    /// 开发层的试验台用：把「看到哪一版」改成任意值，包括**改老**和清空。
    ///
    /// `markWhatsNewSeen` 只前进，那是线上的正确行为；但抽屉一年只有几次机会
    /// 自己出现，不能倒退就没法验收正常路径。所以倒退这条路只在 DEBUG 里存在。
    public func overrideLastSeenWhatsNewVersion(_ version: String) {
        preferences.update { $0.lastSeenWhatsNewVersion = version }
        lastSeenWhatsNewVersion = preferences.current.lastSeenWhatsNewVersion
    }
    #endif

    // MARK: - 猫和菜单栏

    public func setHidesCat(_ hidden: Bool) {
        hidesCat = hidden
        preferences.update { $0.hidesCat = hidden }
    }

    public func setMenuBarStyle(_ style: MenuBarStyle) {
        menuBarStyle = style
        preferences.update { $0.menuBarStyle = style }
    }
}
