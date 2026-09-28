struct LedgerSubscription: Codable, Equatable, Sendable {
    var name: String
    var amountUsd: String
    var period: String
    var anchorYear: Int
    var anchorMonth: Int
    var anchorDay: Int
    var providerId: String?
    var accountId: String?
}
