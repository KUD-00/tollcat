import Foundation
import Testing
@testable import MeterProviders

struct RefreshCadenceTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("间隔 0 表示不另限，上次刚成功也打")
    func zeroIntervalAlwaysFetches() {
        #expect(
            RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: now,
                now: now,
                minimumInterval: 0
            )
        )
    }

    @Test("从没成功过一律要打")
    func neverSucceededAlwaysFetches() {
        #expect(
            RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: nil,
                now: now,
                minimumInterval: 86_400
            )
        )
    }

    @Test("间隔内已成功的不打")
    func skipsWithinInterval() {
        #expect(
            !RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: now.addingTimeInterval(-3_600),
                now: now,
                minimumInterval: 86_400
            )
        )
    }

    @Test("过了间隔再打")
    func fetchesAfterInterval() {
        #expect(
            RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: now.addingTimeInterval(-86_400),
                now: now,
                minimumInterval: 86_400
            )
        )
    }

    @Test("盖在未来的章当成要打，避免冻住")
    func futureStampDoesNotFreeze() {
        #expect(
            RefreshCadence.shouldFetch(
                lastSuccessfulRefreshAt: now.addingTimeInterval(86_400),
                now: now,
                minimumInterval: 86_400
            )
        )
    }

    @Test("自动刷新取全局保鲜期和这家间隔里更严的")
    func autoIntervalPicksTheStricter() {
        #expect(
            RefreshCadence.autoInterval(
                minimumRefreshInterval: 86_400,
                defaultFreshness: 15 * 60
            ) == 86_400
        )
        #expect(
            RefreshCadence.autoInterval(
                minimumRefreshInterval: 0,
                defaultFreshness: 15 * 60
            ) == 15 * 60
        )
    }
}
