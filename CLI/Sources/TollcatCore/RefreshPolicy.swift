import Foundation
import MeterProviders

enum RefreshPolicy {
    static let defaultMaxAgeMinutes = 30

    static func shouldFetch(
        lastFetchedAt: Date?,
        now: Date,
        minimumRefreshInterval: TimeInterval,
        maxAge: TimeInterval,
        force: Bool
    ) -> Bool {
        if force { return true }
        let interval = RefreshCadence.autoInterval(
            minimumRefreshInterval: minimumRefreshInterval,
            defaultFreshness: maxAge
        )
        return RefreshCadence.shouldFetch(
            lastSuccessfulRefreshAt: lastFetchedAt,
            now: now,
            minimumInterval: interval
        )
    }
}
