import Foundation

struct ProviderDetailHistoryItem: Identifiable, Equatable, Sendable {
    var id: String
    var fetchedAt: Date
    var dateCaption: String
    var amountCaption: String
    var spokenAmount: String
}
