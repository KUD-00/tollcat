#if DEBUG
import Foundation
import MeterCore
import MeterProviders

/// 只给验收用：`-meter-refresh-bump` 时把用量抬一截，主屏数字才看得出「跟着变了」。
/// Release 不包这一层——`fetchedAt` 和账期由各适配器按注入的时钟自己写对。
struct StampedBillingProvider: BillingProvider {
    var provider: any BillingProvider
    var calendar: Calendar
    var refreshBumpUSD: Decimal

    func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        var snapshot = try await provider.fetch(credential: credential, horizon: horizon)
        applyRefreshBump(to: &snapshot)
        return snapshot
    }

    private func applyRefreshBump(to snapshot: inout Snapshot) {
        guard snapshot.kind == .usage else { return }
        let extra = Money(usd: refreshBumpUSD)
        if var daily = snapshot.dailyUSD {
            let day = calendar.startOfDay(for: snapshot.fetchedAt)
            daily[day, default: .zero] += extra
            snapshot.dailyUSD = daily
        } else if let spend = snapshot.currentSpendUSD {
            snapshot.currentSpendUSD = spend + extra
        }
    }
}
#endif
