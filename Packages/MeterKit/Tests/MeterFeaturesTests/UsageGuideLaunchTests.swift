import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
@testable import MeterFeatures

struct UsageGuideLaunchTests {
    @Test("指南 id 是稳定的落盘键")
    func idsAreStable() {
        #expect(UsageGuideID.heroExcludesSubscriptions.rawValue == "heroExcludesSubscriptions")
        #expect(UsageGuideID.awsRefreshCostsMoney.rawValue == "awsRefreshCostsMoney")
        #expect(UsageGuideID.keysStayOnThisDevice.rawValue == "keysStayOnThisDevice")
        #expect(UsageGuideID.inboxForMissingAPIs.rawValue == "inboxForMissingAPIs")
        #expect(UsageGuideID.widgetOnLockScreen.rawValue == "widgetOnLockScreen")
        #expect(UsageGuideID.allCases.count == 5)
        #expect(UsageGuide.all.map(\.id) == UsageGuideID.allCases)
    }

    @Test("没走完引导、刚走完引导、跳过抽屉、全部看过，都不弹")
    func nextUnseenGuards() {
        let first = UsageGuideID.allCases[0]
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: false,
                completedOnboardingThisLaunch: false,
                seenIDs: [],
                skipDrawer: false,
                presentsOnLaunch: true
            ) == nil
        )
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: true,
                seenIDs: [],
                skipDrawer: false,
                presentsOnLaunch: true
            ) == nil
        )
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: [],
                skipDrawer: true,
                presentsOnLaunch: true
            ) == nil
        )
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: Set(UsageGuideID.allCases.map(\.rawValue)),
                skipDrawer: false,
                presentsOnLaunch: true
            ) == nil
        )
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: [],
                skipDrawer: false,
                presentsOnLaunch: true
            ) == first
        )
    }

    @Test("冷启动抽屉暂时关掉，没强制钩子就不弹")
    func launchDrawerDisabledByDefault() {
        #expect(!UsageGuideLaunch.presentsOnLaunch)
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: [],
                skipDrawer: false
            ) == nil
        )
    }

    @Test("按目录顺序弹下一篇没看过的")
    func nextUnseenSkipsSeenAndUnknown() {
        let seen: Set<String> = [
            UsageGuideID.heroExcludesSubscriptions.rawValue,
            "retiredGuide",
        ]
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: seen,
                skipDrawer: false,
                presentsOnLaunch: true
            ) == .awsRefreshCostsMoney
        )
    }

    @Test("目录里还有没看过的才算有未读")
    func hasUnseenIgnoresUnknownIDs() {
        #expect(UsageGuideLaunch.hasUnseen(seenIDs: []))
        #expect(
            !UsageGuideLaunch.hasUnseen(
                seenIDs: Set(UsageGuideID.allCases.map(\.rawValue))
            )
        )
        #expect(
            UsageGuideLaunch.hasUnseen(
                seenIDs: [UsageGuideID.heroExcludesSubscriptions.rawValue]
            )
        )
    }
}

@MainActor
struct UsageGuidePersistenceTests {
    @Test("看过一篇之后下次冷启动弹下一篇")
    func markingSeenAdvancesQueue() throws {
        let model = DashboardModel.previewEmpty
        model.shell.completeOnboarding()
        #expect(model.shell.hasUnseenUsageGuides)
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: model.shell.seenUsageGuideIDs,
                skipDrawer: false,
                presentsOnLaunch: true
            ) == .heroExcludesSubscriptions
        )

        model.shell.markUsageGuideSeen(UsageGuideID.heroExcludesSubscriptions.rawValue)
        #expect(model.shell.seenUsageGuideIDs.contains(UsageGuideID.heroExcludesSubscriptions.rawValue))
        #expect(
            UsageGuideLaunch.nextUnseen(
                hasCompletedOnboarding: true,
                completedOnboardingThisLaunch: false,
                seenIDs: model.shell.seenUsageGuideIDs,
                skipDrawer: false,
                presentsOnLaunch: true
            ) == .awsRefreshCostsMoney
        )

        let stored = try AppPreferencesRecord.load(from: ModelContext(model.storeContainer))
        #expect(stored.seenUsageGuideIDs == ["heroExcludesSubscriptions"])

        model.shell.resetUsageGuides()
        #expect(model.shell.seenUsageGuideIDs.isEmpty)
        #expect(model.shell.hasUnseenUsageGuides)
    }

    @Test("同一篇看两次不会重复落盘")
    func markingSeenTwiceIsIdempotent() throws {
        let model = DashboardModel.previewEmpty
        model.shell.markUsageGuideSeen(UsageGuideID.heroExcludesSubscriptions.rawValue)
        model.shell.markUsageGuideSeen(UsageGuideID.heroExcludesSubscriptions.rawValue)
        let stored = try AppPreferencesRecord.load(from: ModelContext(model.storeContainer))
        #expect(stored.seenUsageGuideIDs == ["heroExcludesSubscriptions"])
    }
}
