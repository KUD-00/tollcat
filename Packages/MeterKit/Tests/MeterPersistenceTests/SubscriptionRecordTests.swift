import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct SubscriptionRecordTests {
    @Test("年付近午夜跨时区：存的是日历分量，不会错到下个月")
    func annualAnchorDoesNotShiftWhenTimezoneCrossesMidnight() throws {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!

        // 洛杉矶 8 月 31 日 23:30 = UTC 9 月 1 日。若按 UTC 存零点，年付会记到 9 月。
        var late = DateComponents()
        late.year = 2026
        late.month = 8
        late.day = 31
        late.hour = 23
        late.minute = 30
        let anchor = losAngeles.date(from: late)!

        #expect(utc.component(.month, from: anchor) == 9)
        #expect(utc.component(.day, from: anchor) == 1)

        let subscription = MonthlySubscription(
            name: "年付",
            amount: Money(usd: Decimal(string: "200")!),
            period: .annual,
            anchorDate: anchor
        )
        let record = SubscriptionRecord(domain: subscription, calendar: losAngeles)

        #expect(record.anchorYear == 2026)
        #expect(record.anchorMonth == 8)
        #expect(record.anchorDay == 31)
        #expect(record.amountUSD == Decimal(string: "200"))

        let restoredInLA = try record.toDomain(calendar: losAngeles)
        #expect(losAngeles.component(.year, from: restoredInLA.anchorDate) == 2026)
        #expect(losAngeles.component(.month, from: restoredInLA.anchorDate) == 8)
        #expect(losAngeles.component(.day, from: restoredInLA.anchorDate) == 31)

        let restoredInTokyo = try record.toDomain(calendar: tokyo)
        #expect(tokyo.component(.month, from: restoredInTokyo.anchorDate) == 8)
        #expect(tokyo.component(.day, from: restoredInTokyo.anchorDate) == 31)

        let august = date(2026, 8, 16, 12, calendar: losAngeles)
        let september = date(2026, 9, 16, 12, calendar: losAngeles)
        #expect(
            MonthToDateCalculator.compute(
                snapshots: [],
                subscriptions: [restoredInLA],
                now: august,
                calendar: losAngeles
            ).totalUSD == Money(usd: 200)
        )
        #expect(
            MonthToDateCalculator.compute(
                snapshots: [],
                subscriptions: [restoredInLA],
                now: september,
                calendar: losAngeles
            ).totalUSD == .zero
        )
    }

    @Test("只持久化名称、金额周期、锚点、可选归属，没有提醒或 logo")
    func onlyFourDomainFieldsArePersisted() throws {
        guard let entity = PersistenceContainer.schema.entities.first(
            where: { $0.name == String(describing: SubscriptionRecord.self) }
        ) else {
            Issue.record("SubscriptionRecord is missing from the SwiftData schema")
            return
        }
        let names = Set(entity.attributesByName.keys)
        let allowed: Set<String> = [
            "name",
            "amountUSD",
            "periodRaw",
            "anchorYear",
            "anchorMonth",
            "anchorDay",
            "endYear",
            "endMonth",
            "endDay",
            "accountIDRaw",
            "providerIDRaw",
            "quantity",
        ]
        #expect(names.isSubset(of: allowed))
        #expect(allowed.isSubset(of: names))

        let forbidden = ["reminder", "logo", "pricehistory", "price_history", "notify"]
        for name in names {
            let folded = name.lowercased()
            for token in forbidden {
                #expect(!folded.contains(token), "\(name) looks like a subscription-manager field")
            }
        }
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }
}
