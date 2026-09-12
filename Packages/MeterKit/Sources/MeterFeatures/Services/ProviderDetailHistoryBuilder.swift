import Foundation
import MeterCore

enum ProviderDetailHistoryBuilder {
    /// 收**原始读数**。这一列表就是历次刷新各报了什么，最新在上。
    static func items(
        from readings: ReadingSeries,
        now: Date,
        calendar: Calendar,
        presentation: MoneyPresentation = .usd
    ) -> [ProviderDetailHistoryItem] {
        // `ReadingSeries` 是时间升序的；这一页最新在上，所以反过来。
        let ordered = Array(readings.reversed())
        return ordered.enumerated().map { index, snapshot in
            let amount = amountCaption(for: snapshot, presentation: presentation)
            return ProviderDetailHistoryItem(
                id: "\(snapshot.fetchedAt.timeIntervalSince1970)-\(index)",
                fetchedAt: snapshot.fetchedAt,
                dateCaption: dateCaption(snapshot.fetchedAt, now: now, calendar: calendar),
                amountCaption: amount.text,
                spokenAmount: amount.spoken
            )
        }
    }

    private static func amountCaption(
        for snapshot: Snapshot,
        presentation: MoneyPresentation
    ) -> (text: String, spoken: String) {
        switch snapshot.kind {
        case .usage:
            if let amount = snapshot.currentSpendUSD {
                return (
                    presentation.string(from: amount, original: snapshot.converted),
                    SpokenMoney.label(for: amount, presentation: presentation)
                )
            }
        case .prepaid:
            if let amount = snapshot.balanceUSD {
                return (
                    presentation.string(from: amount, original: snapshot.converted),
                    SpokenMoney.label(for: amount, presentation: presentation)
                )
            }
        case .subscription:
            if let amount = snapshot.committedMonthlyUSD {
                return (
                    amount.formatted(using: presentation),
                    SpokenMoney.label(for: amount, presentation: presentation)
                )
            }
        case .freeTier:
            if let ratio = snapshot.freeQuotaUsedRatio {
                let percent = Int((ratio * 100).rounded())
                return (
                    String(localized: L("额度 \(percent)%")),
                    String(localized: L("免费额度用了百分之 \(percent)"))
                )
            }
        case .planAndUsage:
            let committed = snapshot.committedMonthlyUSD ?? .zero
            let spend = snapshot.currentSpendUSD ?? .zero
            let total = committed + spend
            if snapshot.committedMonthlyUSD != nil || snapshot.currentSpendUSD != nil {
                return (
                    total.formatted(using: presentation),
                    SpokenMoney.label(for: total, presentation: presentation)
                )
            }
        }
        return ("—", String(localized: L("暂无读数")))
    }

    private static func dateCaption(_ date: Date, now: Date, calendar: Calendar) -> String {
        if now.timeIntervalSince(date) < 86_400 {
            return MeterDateFormat.relative(from: date, now: now, calendar: calendar)
        }
        return MeterDateFormat.monthDayTime(date, calendar: calendar)
    }
}
