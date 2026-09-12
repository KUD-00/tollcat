import Testing
@testable import MeterFeatures

/// 抽屉只有一次机会：更新后第一次冷启动。所以判据必须能脱离时间、Bundle 和偏好单测。
struct WhatsNewLaunchTests {
    private let loud = WhatsNewEntry.preview          // 1.1.0，drawer 开
    private let older = WhatsNewEntry.previewOlder    // 1.0.1，drawer 开

    private var quiet: WhatsNewEntry {
        var entry = WhatsNewEntry.previewOlder
        entry.showsDrawer = false
        return entry
    }

    private var macOnly: WhatsNewEntry {
        var entry = WhatsNewEntry.preview
        entry.platforms = [.mac]
        return entry
    }

    private func pending(
        _ entries: [WhatsNewEntry],
        current: String,
        lastSeen: String,
        platform: WhatsNewPlatform = .ios,
        hasCompletedOnboarding: Bool = true,
        completedOnboardingThisLaunch: Bool = false,
        skipDrawer: Bool = false
    ) -> [String] {
        WhatsNewLaunch.pending(
            entries: entries,
            currentVersion: current,
            lastSeenVersion: lastSeen,
            platform: platform,
            hasCompletedOnboarding: hasCompletedOnboarding,
            completedOnboardingThisLaunch: completedOnboardingThisLaunch,
            skipDrawer: skipDrawer
        ).map(\.version)
    }

    @Test("首装不弹：没用过的 App 谈不上变化")
    func freshInstallStaysQuiet() {
        #expect(pending([loud], current: "1.1.0", lastSeen: "").isEmpty)
    }

    @Test("刚走完开场引导那一次不弹")
    func onboardingLaunchStaysQuiet() {
        #expect(
            pending(
                [loud],
                current: "1.1.0",
                lastSeen: "1.0.0",
                completedOnboardingThisLaunch: true
            ).isEmpty
        )
    }

    @Test("没走完开场引导不弹")
    func beforeOnboardingStaysQuiet() {
        #expect(
            pending([loud], current: "1.1.0", lastSeen: "1.0.0", hasCompletedOnboarding: false)
                .isEmpty
        )
    }

    @Test("同一版再启动不弹")
    func sameVersionStaysQuiet() {
        #expect(pending([loud], current: "1.1.0", lastSeen: "1.1.0").isEmpty)
    }

    @Test("降级安装不把说明再放一遍")
    func downgradeStaysQuiet() {
        #expect(pending([loud], current: "1.0.1", lastSeen: "1.1.0").isEmpty)
    }

    @Test("更新过就弹这一版")
    func updateShowsEntry() {
        #expect(pending([loud], current: "1.1.0", lastSeen: "1.0.1") == ["1.1.0"])
    }

    @Test("跳版合并成一张，新的在上")
    func skippedVersionsMergeNewestFirst() {
        #expect(pending([loud, older], current: "1.1.0", lastSeen: "1.0.0") == ["1.1.0", "1.0.1"])
    }

    @Test("drawer:false 的条目不进抽屉")
    func quietEntryStaysOutOfDrawer() {
        #expect(pending([quiet], current: "1.0.1", lastSeen: "1.0.0").isEmpty)
    }

    @Test("安静的热修复不会攒进下一张抽屉")
    func quietEntriesDoNotAccumulate() {
        #expect(pending([loud, quiet], current: "1.1.0", lastSeen: "1.0.0") == ["1.1.0"])
    }

    @Test("这一端没上车就不弹")
    func otherPlatformTrainStaysQuiet() {
        #expect(pending([macOnly], current: "1.1.0", lastSeen: "1.0.0", platform: .ios).isEmpty)
        #expect(pending([macOnly], current: "1.1.0", lastSeen: "1.0.0", platform: .mac) == ["1.1.0"])
    }

    @Test("比当前版本还新的条目不提前弹")
    func futureEntryStaysQuiet() {
        #expect(pending([loud], current: "1.0.1", lastSeen: "1.0.0").isEmpty)
    }

    @Test("截图钩子那条路不经过判据：skipDrawer 一律不弹")
    func skipDrawerStaysQuiet() {
        #expect(pending([loud], current: "1.1.0", lastSeen: "1.0.0", skipDrawer: true).isEmpty)
    }

    @Test("版本号读不出来时宁可不弹")
    func unparsableVersionStaysQuiet() {
        #expect(pending([loud], current: "毛线", lastSeen: "1.0.0").isEmpty)
        #expect(pending([loud], current: "1.1.0", lastSeen: "毛线").isEmpty)
    }

    @Test("看到哪一版只前进")
    func lastSeenOnlyMovesForward() {
        #expect(WhatsNewLaunch.advanced(lastSeenVersion: "", currentVersion: "1.1.0") == "1.1.0")
        #expect(
            WhatsNewLaunch.advanced(lastSeenVersion: "1.0.0", currentVersion: "1.1.0") == "1.1.0"
        )
        // 降级安装：不回退，否则老版本会把说明再放一遍。
        #expect(
            WhatsNewLaunch.advanced(lastSeenVersion: "1.1.0", currentVersion: "1.0.1") == "1.1.0"
        )
        #expect(
            WhatsNewLaunch.advanced(lastSeenVersion: "1.1.0", currentVersion: "1.1.0") == "1.1.0"
        )
    }

    @Test("当前版本号读不出来时不动已记的那一版")
    func advanceKeepsLastSeenWhenCurrentIsGarbage() {
        #expect(WhatsNewLaunch.advanced(lastSeenVersion: "1.1.0", currentVersion: "?") == "1.1.0")
    }

    @Test("全量列表只按端筛，不管弹没弹")
    func historyKeepsQuietEntries() {
        let history = WhatsNewLaunch.history(entries: [loud, quiet, macOnly], platform: .ios)
        #expect(history.map(\.version) == ["1.1.0", "1.0.1"])
    }

    @Test("版本号按数字比，不按字符串")
    func versionComparesNumerically() {
        #expect(ReleaseVersion("1.9.0")! < ReleaseVersion("1.10.0")!)
        #expect(ReleaseVersion("1.0.0")! < ReleaseVersion("1.0.1")!)
        #expect(ReleaseVersion("2.0.0")! > ReleaseVersion("1.99.99")!)
        #expect(ReleaseVersion("1.0") == nil)
        #expect(ReleaseVersion("1.0.0.1") == nil)
        #expect(ReleaseVersion("1.0.x") == nil)
        #expect(ReleaseVersion("-1.0.0") == nil)
    }
}
