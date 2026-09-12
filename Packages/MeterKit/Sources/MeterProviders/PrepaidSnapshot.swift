import Foundation
import MeterCore

enum PrepaidSnapshot: Sendable {
    static func make(
        providerID: ProviderID,
        now: Date,
        calendar: Calendar,
        balance: Money,
        converted: ConvertedAmount? = nil,
        wallets: [ConvertedAmount]? = nil
    ) -> Snapshot {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        return Snapshot(
            providerID: providerID,
            kind: .prepaid,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            balanceUSD: balance,
            converted: converted,
            wallets: wallets
        )
    }
}
