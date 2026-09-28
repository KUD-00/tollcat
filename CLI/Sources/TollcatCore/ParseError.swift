enum ParseError: Error, Equatable, Sendable {
    case unknownFlag(String)
    case unknownCommand(String)
    case missingValue(String)
    case invalidMaxAge(String)
    case conflictingOutput
}
