import Foundation
import SwiftData

/// 本机打赏记录。上报失败也要留着，下次打开再发；所以交易凭据一起落库。
@Model
public final class TipRecord {
    @Attribute(.unique) public var transactionID: String
    public var productID: String
    public var displayPrice: String
    public var purchasedAt: Date
    public var name: String?
    public var message: String?
    public var isSubmitted: Bool
    public var jws: String
    public var appVersion: String

    public init(
        transactionID: String,
        productID: String,
        displayPrice: String,
        purchasedAt: Date,
        name: String? = nil,
        message: String? = nil,
        isSubmitted: Bool = false,
        jws: String,
        appVersion: String
    ) {
        self.transactionID = transactionID
        self.productID = productID
        self.displayPrice = displayPrice
        self.purchasedAt = purchasedAt
        self.name = name
        self.message = message
        self.isSubmitted = isSubmitted
        self.jws = jws
        self.appVersion = appVersion
    }

    public static func all(from context: ModelContext) throws -> [TipRecord] {
        try context.fetch(
            FetchDescriptor<TipRecord>(
                sortBy: [SortDescriptor(\.purchasedAt, order: .reverse)]
            )
        )
    }

    public static func unsynced(from context: ModelContext) throws -> [TipRecord] {
        try context.fetch(
            FetchDescriptor<TipRecord>(
                predicate: #Predicate { !$0.isSubmitted }
            )
        )
    }

    public static func fetch(
        transactionID: String,
        from context: ModelContext
    ) throws -> TipRecord? {
        let target = transactionID
        var descriptor = FetchDescriptor<TipRecord>(
            predicate: #Predicate { $0.transactionID == target }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @discardableResult
    public static func upsert(
        transactionID: String,
        productID: String,
        displayPrice: String,
        purchasedAt: Date,
        name: String? = nil,
        message: String? = nil,
        jws: String,
        appVersion: String,
        in context: ModelContext
    ) throws -> TipRecord {
        if let existing = try fetch(transactionID: transactionID, from: context) {
            if let name {
                existing.name = name
            }
            if let message {
                existing.message = message
            }
            if existing.displayPrice.isEmpty, !displayPrice.isEmpty {
                existing.displayPrice = displayPrice
            }
            try context.save()
            return existing
        }

        let record = TipRecord(
            transactionID: transactionID,
            productID: productID,
            displayPrice: displayPrice,
            purchasedAt: purchasedAt,
            name: name,
            message: message,
            isSubmitted: false,
            jws: jws,
            appVersion: appVersion
        )
        context.insert(record)
        try context.save()
        return record
    }
}
