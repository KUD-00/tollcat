struct Invocation: Equatable, Sendable {
    var verb: Verb?
    var positional: [String]
    var oneline: Bool
    var json: Bool
    var noColor: Bool
    var locale: String?
    var maxAgeMinutes: Int?
    var version: Bool
    var help: Bool

    static let empty = Invocation(
        verb: nil,
        positional: [],
        oneline: false,
        json: false,
        noColor: false,
        locale: nil,
        maxAgeMinutes: nil,
        version: false,
        help: false
    )
}
