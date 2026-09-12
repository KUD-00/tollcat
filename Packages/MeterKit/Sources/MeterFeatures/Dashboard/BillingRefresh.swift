import Foundation
import MeterCore
import MeterProviders

/// 用户点刷新、演示种子取数，都走这一份 `BillingProvider.fetch`。
enum BillingRefresh: Sendable {
    static func fetchOne(_ job: BillingRefreshJob) async -> BillingRefreshOutcome {
        let id = job.id.rawValue.uuidString
        #if DEBUG
        TollCatLog.event("refresh", "fetch start \(job.providerID.rawValue) \(id)")
        #endif
        do {
            var snapshot = try await job.provider.fetch(credential: job.credential)
            snapshot.accountID = job.id
            #if DEBUG
            TollCatLog.event(
                "refresh",
                "fetch ok \(job.providerID.rawValue) \(id) spend=\(debugAmount(snapshot.currentSpendUSD)) balance=\(debugAmount(snapshot.balanceUSD))"
            )
            #endif
            return .success(id: job.id, snapshot: snapshot)
        } catch {
            #if DEBUG
            TollCatLog.event("refresh", "fetch fail \(job.providerID.rawValue) \(id) \(String(describing: error))")
            #endif
            return .failure(id: job.id)
        }
    }

    #if DEBUG
    private static func debugAmount(_ money: Money?) -> String {
        guard let money else { return "-" }
        return NSDecimalNumber(decimal: money.usd).stringValue
    }
    #endif

    static func fetch(_ jobs: [BillingRefreshJob]) async -> [BillingRefreshOutcome] {
        await withTaskGroup(of: BillingRefreshOutcome.self) { group in
            for job in jobs {
                group.addTask {
                    await fetchOne(job)
                }
            }
            var outcomes: [BillingRefreshOutcome] = []
            for await outcome in group {
                outcomes.append(outcome)
            }
            return outcomes
        }
    }
}
