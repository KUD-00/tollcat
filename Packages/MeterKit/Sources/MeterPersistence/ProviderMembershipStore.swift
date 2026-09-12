import Foundation
import SwiftData
import MeterCore

public enum ProviderMembershipStore: Sendable {
    public static func all(in context: ModelContext) throws -> [ProviderMembership] {
        try context.fetch(FetchDescriptor<ProviderMembershipRecord>())
            .map(\.membership)
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    @discardableResult
    public static func ensure(_ providerID: ProviderID, in context: ModelContext) throws -> ProviderMembershipRecord {
        if let record = try fetch(providerID, in: context) {
            return record
        }
        // 排尾要看全表的最大 sortIndex，这一次全量 fetch 躲不掉。
        let existing = try context.fetch(FetchDescriptor<ProviderMembershipRecord>())
        let sortIndex = (existing.map(\.sortIndex).max() ?? -1) + 1
        let record = ProviderMembershipRecord(providerID: providerID, sortIndex: sortIndex)
        context.insert(record)
        return record
    }

    public static func insertExact(
        _ membership: ProviderMembership,
        in context: ModelContext
    ) throws {
        if try fetch(membership.providerID, in: context) != nil {
            return
        }
        context.insert(
            ProviderMembershipRecord(providerID: membership.providerID, sortIndex: membership.sortIndex)
        )
    }

    public static func remove(_ providerID: ProviderID, in context: ModelContext) throws {
        let target = providerID.rawValue
        let descriptor = FetchDescriptor<ProviderMembershipRecord>(
            predicate: #Predicate { $0.providerIDRaw == target }
        )
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
    }

    private static func fetch(_ providerID: ProviderID, in context: ModelContext) throws -> ProviderMembershipRecord? {
        let target = providerID.rawValue
        var descriptor = FetchDescriptor<ProviderMembershipRecord>(
            predicate: #Predicate { $0.providerIDRaw == target }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
