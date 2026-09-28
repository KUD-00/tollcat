struct FetchOutcome: Equatable, Sendable {
    var ok: Bool
    var snapshot: LedgerSnapshot?
    var error: String?
}
