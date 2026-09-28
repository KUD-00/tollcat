struct CatalogProvider: Equatable, Sendable {
    var id: String
    var displayName: String
    var kind: String
    var summary: String
    var accessStatus: String
    var declineReason: String
    var hasLiveFetch: Bool
    var costsMoneyToRefresh: Bool
    var minimumRefreshInterval: Int
    var credentialSetupURL: String
    var fields: [CatalogField]
    var searchKeywords: [String]

    var isOffered: Bool { accessStatus != "declined" }
}
