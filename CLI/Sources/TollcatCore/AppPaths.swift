import Foundation

struct AppPaths: Sendable {
    var ledgerFile: URL

    static func resolve(environment: [String: String], home: String?) -> AppPaths {
        let directory = dataDirectory(environment: environment, home: home)
        return AppPaths(ledgerFile: directory.appendingPathComponent("ledger.json"))
    }

    static func dataDirectory(environment: [String: String], home: String?) -> URL {
        if let override = environment["TOLLCAT_DATA_HOME"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        #if os(macOS)
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return support.appendingPathComponent("tollcat", isDirectory: true)
        }
        #endif
        if let xdg = environment["XDG_DATA_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg, isDirectory: true).appendingPathComponent("tollcat", isDirectory: true)
        }
        let homePath = home ?? environment["HOME"] ?? NSHomeDirectory()
        return URL(fileURLWithPath: homePath, isDirectory: true)
            .appendingPathComponent(".local/share/tollcat", isDirectory: true)
    }
}
