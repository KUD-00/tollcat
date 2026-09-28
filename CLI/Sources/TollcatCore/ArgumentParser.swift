enum ArgumentParser {
    static func parse(_ arguments: [String]) throws -> Invocation {
        var invocation = Invocation.empty
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--" {
                invocation.positional.append(contentsOf: arguments[(index + 1)...])
                break
            }
            if argument == "--version" || argument == "-V" {
                invocation.version = true
                index += 1
                continue
            }
            if argument == "--help" || argument == "-h" {
                invocation.help = true
                index += 1
                continue
            }
            if argument == "--oneline" {
                invocation.oneline = true
                index += 1
                continue
            }
            if argument == "--json" {
                invocation.json = true
                index += 1
                continue
            }
            if argument == "--no-color" {
                invocation.noColor = true
                index += 1
                continue
            }
            if arguments[index] == "--locale" || arguments[index].hasPrefix("--locale=") {
                guard let value = value(for: "--locale", at: index, in: arguments) else {
                    throw ParseError.missingValue("--locale")
                }
                invocation.locale = value.value
                index = value.next
                continue
            }
            if arguments[index] == "--max-age" || arguments[index].hasPrefix("--max-age=") {
                guard let value = value(for: "--max-age", at: index, in: arguments) else {
                    throw ParseError.missingValue("--max-age")
                }
                guard let minutes = Int(value.value), minutes >= 0 else {
                    throw ParseError.invalidMaxAge(value.value)
                }
                invocation.maxAgeMinutes = minutes
                index = value.next
                continue
            }
            if argument.hasPrefix("-"), argument != "-" {
                throw ParseError.unknownFlag(argument)
            }
            if invocation.verb == nil, let verb = Verb(rawValue: argument) {
                invocation.verb = verb
                index += 1
                continue
            }
            if invocation.verb == nil, argument.hasPrefix("-") == false,
               Verb(rawValue: argument) == nil, invocation.positional.isEmpty
            {
                throw ParseError.unknownCommand(argument)
            }
            invocation.positional.append(argument)
            index += 1
        }
        if invocation.oneline, invocation.json {
            throw ParseError.conflictingOutput
        }
        return invocation
    }

    private static func value(
        for flag: String,
        at index: Int,
        in arguments: [String]
    ) -> (value: String, next: Int)? {
        let argument = arguments[index]
        let prefix = flag + "="
        if argument.hasPrefix(prefix) {
            return (String(argument.dropFirst(prefix.count)), index + 1)
        }
        guard argument == flag else { return nil }
        guard index + 1 < arguments.count else {
            return nil
        }
        let next = arguments[index + 1]
        if next.hasPrefix("-") {
            return nil
        }
        return (next, index + 2)
    }
}
