import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

struct ColorPolicy: Equatable, Sendable {
    var enabled: Bool

    static func resolve(
        noColorFlag: Bool,
        environment: [String: String],
        stdoutIsTTY: Bool
    ) -> ColorPolicy {
        if noColorFlag { return ColorPolicy(enabled: false) }
        if environment["NO_COLOR"] != nil { return ColorPolicy(enabled: false) }
        return ColorPolicy(enabled: stdoutIsTTY)
    }

    func wrap(_ text: String, _ code: String) -> String {
        guard enabled, !text.isEmpty else { return text }
        return code + text + ANSIColor.reset
    }
}

enum StandardStream {
    static func stdoutIsTTY() -> Bool {
        isatty(STDOUT_FILENO) != 0
    }

    static func stdinIsTTY() -> Bool {
        isatty(STDIN_FILENO) != 0
    }

    static func columns(environment: [String: String]) -> Int {
        if let raw = environment["COLUMNS"], let value = Int(raw), value > 0 {
            return value
        }
        #if canImport(Darwin)
        var size = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0, size.ws_col > 0 {
            return Int(size.ws_col)
        }
        #endif
        return 80
    }
}
