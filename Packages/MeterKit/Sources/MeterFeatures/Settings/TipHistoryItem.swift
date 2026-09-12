import Foundation
import MeterTips

struct TipHistoryItem: Identifiable, Hashable, Sendable {
    var transactionID: String
    var productID: String
    var displayPrice: String
    var purchasedAt: Date
    var name: String?
    var message: String?
    var isSubmitted: Bool

    var id: String { transactionID }

    var productTitle: String {
        TipProductID(rawValue: productID)?.listTitle ?? productID
    }
}
