import Foundation
import Testing
@testable import TollcatCore

struct RefreshPolicyTests {
    @Test func forceAlwaysFetches() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(
            RefreshPolicy.shouldFetch(
                lastFetchedAt: now,
                now: now,
                minimumRefreshInterval: 86_400,
                maxAge: 1_800,
                force: true
            )
        )
    }

    @Test func respectsMaxAge() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fresh = now.addingTimeInterval(-60)
        #expect(
            !RefreshPolicy.shouldFetch(
                lastFetchedAt: fresh,
                now: now,
                minimumRefreshInterval: 0,
                maxAge: 1_800,
                force: false
            )
        )
        let stale = now.addingTimeInterval(-2_000)
        #expect(
            RefreshPolicy.shouldFetch(
                lastFetchedAt: stale,
                now: now,
                minimumRefreshInterval: 0,
                maxAge: 1_800,
                force: false
            )
        )
    }
}
