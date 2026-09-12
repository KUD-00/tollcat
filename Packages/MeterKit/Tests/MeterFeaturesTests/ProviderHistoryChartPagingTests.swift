import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct ProviderHistoryChartPagingTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("7 天和 30 天是同一条日线，起点是 12 个月回看")
    func dayChartsShareLookbackSeries() throws {
        let model = try seededModel()
        model.setHistoryRange(.days7)
        guard case .spend(let weekPoints, let weekStart, let weekEnd, .day, _) = model.chartContent else {
            Issue.record("expected day spend chart")
            return
        }
        let lookback = ProviderHistoryChartBuilder.window(
            range: .months12,
            now: date(2026, 8, 16),
            calendar: calendar
        )
        #expect(calendar.isDate(weekStart, inSameDayAs: lookback.start))
        #expect(calendar.isDate(weekEnd, inSameDayAs: date(2026, 8, 16)))
        #expect(weekPoints.contains { calendar.isDate($0.date, inSameDayAs: date(2026, 8, 1)) })
        #expect(weekPoints.contains { calendar.isDate($0.date, inSameDayAs: date(2026, 8, 16)) })

        model.setHistoryRange(.days30)
        guard case .spend(let monthPoints, let monthStart, _, .day, _) = model.chartContent else {
            Issue.record("expected day spend chart")
            return
        }
        #expect(monthStart == weekStart)
        #expect(monthPoints.map(\.date) == weekPoints.map(\.date))
    }

    @Test("读数明细仍按今天这一档，不跟图上滑到哪一段")
    func historyListStaysPinnedToToday() throws {
        let model = try seededModel()
        model.setHistoryRange(.days7)
        let window = ProviderHistoryChartBuilder.window(
            range: .days7,
            now: date(2026, 8, 16),
            calendar: calendar
        )
        #expect(model.history.allSatisfy { $0.fetchedAt >= window.start })
        #expect(model.chartContent.hasPlot)
    }

    @Test("12 个月不滑，仍是月柱")
    func twelveMonthsStaysMonthly() throws {
        let model = try seededModel()
        model.setHistoryRange(.months12)
        guard case .spend(_, _, _, .month, _) = model.chartContent else {
            Issue.record("expected monthly spend chart")
            return
        }
        #expect(model.historyRange.visibleDayCount == nil)
    }

    private func seededModel() throws -> ProviderDetailModel {
        let dashboard = try makeDashboard()
        let accountID = AccountID.fixture(for: .cloudflare)
        try dashboard.applyConnection(
            accountID: accountID,
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: "test-cf-scroll",
            fields: [
                CredentialField.apiToken.rawValue: "tok",
                CredentialField.accountID.rawValue: "acct",
            ],
            snapshots: [
                dailySnapshot(accountID, day: date(2026, 8, 16), amount: 2.2),
                dailySnapshot(accountID, day: date(2026, 8, 1), amount: 1.4),
            ],
            mode: .create
        )
        return ProviderDetailModel(providerID: .cloudflare, dashboard: dashboard)
    }

    private func dailySnapshot(_ accountID: AccountID, day: Date, amount: Double) -> Snapshot {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: day))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        return Snapshot(
            providerID: .cloudflare,
            accountID: accountID,
            kind: .usage,
            fetchedAt: day,
            periodStart: monthStart,
            periodEnd: monthEnd,
            currentSpendUSD: Money(usd: Decimal(amount)),
            dailyUSD: [calendar.startOfDay(for: day): Money(usd: Decimal(amount))]
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeDashboard() throws -> DashboardModel {
        DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: InMemoryCredentialStore(),
            clock: MeterClock(now: date(2026, 8, 16), calendar: calendar),
            httpClient: StubHTTPClient()
        )
    }
}
