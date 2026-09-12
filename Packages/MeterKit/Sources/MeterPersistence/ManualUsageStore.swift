import Foundation
import SwiftData
import MeterCore

public enum ManualUsageStore: Sendable {
    @discardableResult
    public static func upsert(
        accountID: AccountID,
        providerID: ProviderID,
        periodYear: Int,
        periodMonth: Int,
        amount: Money,
        enteredAt: Date,
        kind: ProviderKind,
        in context: ModelContext
    ) throws -> ManualUsageRecord {
        if let record = try fetch(
            accountID: accountID,
            periodYear: periodYear,
            periodMonth: periodMonth,
            in: context
        ) {
            record.providerIDRaw = providerID.rawValue
            record.apply(
                periodYear: periodYear,
                periodMonth: periodMonth,
                amount: amount,
                enteredAt: enteredAt,
                kind: kind
            )
            return record
        }
        let record = ManualUsageRecord(
            accountID: accountID,
            providerID: providerID,
            periodYear: periodYear,
            periodMonth: periodMonth,
            amount: amount,
            enteredAt: enteredAt,
            kind: kind
        )
        context.insert(record)
        return record
    }

    public static func delete(accountID: AccountID, in context: ModelContext) throws {
        for record in try fetchAll(accountID: accountID, in: context) {
            context.delete(record)
        }
    }

    public static func delete(providerID: ProviderID, in context: ModelContext) throws {
        let target = providerID.rawValue
        let descriptor = FetchDescriptor<ManualUsageRecord>(
            predicate: #Predicate { $0.providerIDRaw == target }
        )
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
    }

    public static func all(in context: ModelContext) throws -> [ManualUsageRecord] {
        try context.fetch(FetchDescriptor<ManualUsageRecord>())
    }

    private static func fetch(
        accountID: AccountID,
        periodYear: Int,
        periodMonth: Int,
        in context: ModelContext
    ) throws -> ManualUsageRecord? {
        let target = accountID.rawValue.uuidString
        let year = periodYear
        let month = periodMonth
        var descriptor = FetchDescriptor<ManualUsageRecord>(
            predicate: #Predicate {
                $0.accountIDRaw == target
                    && $0.periodYear == year
                    && $0.periodMonth == month
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func fetchAll(
        accountID: AccountID,
        in context: ModelContext
    ) throws -> [ManualUsageRecord] {
        let target = accountID.rawValue.uuidString
        let descriptor = FetchDescriptor<ManualUsageRecord>(
            predicate: #Predicate { $0.accountIDRaw == target }
        )
        return try context.fetch(descriptor)
    }
}
