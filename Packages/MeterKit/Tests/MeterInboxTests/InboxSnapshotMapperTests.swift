import Foundation
import Testing
import MeterCore
@testable import MeterInbox

struct InboxSnapshotMapperTests {
    private let calendar = InboxHarness.calendar

    @Test("折出来的快照带 .inbox 来源，周期是投递方那个月")
    func mapsToInboxSourcedSnapshot() {
        let reading = InboxReading(
            providerID: .render,
            ingestKeyID: "key_render",
            periodStart: InboxHarness.date(2026, 8, 1),
            currentSpendUSD: Money(usd: Decimal(string: "12.34")!),
            reportedAt: InboxHarness.date(2026, 8, 17, 2)
        )
        let snapshot = InboxSnapshotMapper.snapshot(from: reading, kind: .usage, calendar: calendar)

        #expect(snapshot.source == .inbox)
        #expect(snapshot.providerID == .render)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.34")!))
        #expect(snapshot.periodStart == InboxHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == InboxHarness.date(2026, 8, 31))
        // fetchedAt 用投递时刻，界面上「多久前」才是投递的时间。
        #expect(snapshot.fetchedAt == InboxHarness.date(2026, 8, 17, 2))
        #expect(snapshot.hasBillableMetrics)
    }

    @Test("补投上个月的数不会被算成当月")
    func backfilledMonthKeepsItsOwnPeriod() {
        let reading = InboxReading(
            providerID: .expo,
            ingestKeyID: "key_expo",
            periodStart: InboxHarness.date(2026, 7, 14),
            currentSpendUSD: Money(usd: 5),
            reportedAt: InboxHarness.date(2026, 8, 2)
        )
        let snapshot = InboxSnapshotMapper.snapshot(from: reading, kind: .usage, calendar: calendar)
        #expect(snapshot.periodStart == InboxHarness.date(2026, 7, 1))
        #expect(snapshot.periodEnd == InboxHarness.date(2026, 7, 31))
    }

    @Test("来源不同的两条快照不相等，历史不会被去重成一条")
    func sourceParticipatesInEquality() {
        let base = InboxReading(
            providerID: .render,
            ingestKeyID: "key_render",
            periodStart: InboxHarness.date(2026, 8, 1),
            currentSpendUSD: Money(usd: 1),
            reportedAt: InboxHarness.date(2026, 8, 17)
        )
        let fromInbox = InboxSnapshotMapper.snapshot(from: base, kind: .usage, calendar: calendar)
        var fromAPI = fromInbox
        fromAPI.source = .api
        #expect(fromInbox != fromAPI)
    }

    @Test("只有用量型能用投递值表达：投的是月累计")
    func onlyUsageKindsCanBeRepresented() {
        #expect(InboxSnapshotMapper.canRepresent(.usage))
        #expect(InboxSnapshotMapper.canRepresent(.planAndUsage))
        #expect(!InboxSnapshotMapper.canRepresent(.prepaid))
        #expect(!InboxSnapshotMapper.canRepresent(.subscription))
        #expect(!InboxSnapshotMapper.canRepresent(.freeTier))
    }

    @Test("投递来的数不声称和官方后台对得上")
    func inboxDoesNotClaimReconciliation() {
        #expect(SnapshotSource.api.reconcilesWithVendorConsole)
        #expect(!SnapshotSource.inbox.reconcilesWithVendorConsole)
    }

    @Test("老库里没有来源字段的行按 api 读")
    func legacyRowsReadAsAPI() {
        #expect(SnapshotSource.fromStored(nil) == .api)
        #expect(SnapshotSource.fromStored("") == .api)
        #expect(SnapshotSource.fromStored("未来的新来源") == .api)
        #expect(SnapshotSource.fromStored("inbox") == .inbox)
        #expect(SnapshotSource.fromStored("manual") == .manual)
        #expect(!SnapshotSource.manual.reconcilesWithVendorConsole)
        #expect(SnapshotSource.manual.isUserSupplied)
    }
}
