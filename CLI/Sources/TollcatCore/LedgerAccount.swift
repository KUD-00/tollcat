struct LedgerAccount: Codable, Equatable, Sendable {
    var accountId: String
    var providerId: String
    var credentialReference: String
    var sortIndex: Int
}
