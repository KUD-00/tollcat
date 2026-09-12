import Foundation
import SwiftData
import Testing
@testable import MeterPersistence

@MainActor
struct TipRecordTests {
    @Test("同一笔交易不会写成两行")
    func upsertIsIdempotent() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let purchasedAt = Date(timeIntervalSince1970: 1_787_000_000)

        try TipRecord.upsert(
            transactionID: "tx-1",
            productID: "com.zhechengqi.tollcat.tip.small",
            displayPrice: "6.00",
            purchasedAt: purchasedAt,
            jws: "jws-1",
            appVersion: "0.1.0",
            in: context
        )
        try TipRecord.upsert(
            transactionID: "tx-1",
            productID: "com.zhechengqi.tollcat.tip.small",
            displayPrice: "6.00",
            purchasedAt: purchasedAt,
            name: "陈",
            message: "好用",
            jws: "jws-1",
            appVersion: "0.1.0",
            in: context
        )

        let stored = try TipRecord.all(from: context)
        #expect(stored.count == 1)
        #expect(stored[0].name == "陈")
        #expect(stored[0].message == "好用")
        #expect(stored[0].isSubmitted == false)
    }

    @Test("未上报的记录能单独取出来重试")
    func unsyncedQuery() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let purchasedAt = Date(timeIntervalSince1970: 1_787_000_000)

        try TipRecord.upsert(
            transactionID: "pending",
            productID: "com.zhechengqi.tollcat.tip.medium",
            displayPrice: "18.00",
            purchasedAt: purchasedAt,
            jws: "jws-pending",
            appVersion: "0.1.0",
            in: context
        )
        let done = try TipRecord.upsert(
            transactionID: "done",
            productID: "com.zhechengqi.tollcat.tip.large",
            displayPrice: "45.00",
            purchasedAt: purchasedAt,
            jws: "jws-done",
            appVersion: "0.1.0",
            in: context
        )
        done.isSubmitted = true
        try context.save()

        let pending = try TipRecord.unsynced(from: context)
        #expect(pending.map(\.transactionID) == ["pending"])
    }
}
