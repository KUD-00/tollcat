import Foundation

enum CLIIdentity {
    static func line(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        if let commit = commit(environment: environment) {
            return "tollcat \(CLIVersion.marketing) (\(commit))"
        }
        return "tollcat \(CLIVersion.marketing)"
    }

    static func commit(environment: [String: String]) -> String? {
        if let baked = environment["TOLLCAT_COMMIT"], !baked.isEmpty {
            return baked
        }
        return gitRevParse()
    }

    private static func gitRevParse() -> String? {
        let here = URL(fileURLWithPath: #filePath)
        var directory = here.deletingLastPathComponent()
        for _ in 0..<8 {
            directory.deleteLastPathComponent()
            let git = directory.appendingPathComponent(".git")
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: git.path, isDirectory: &isDirectory) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                process.arguments = ["-C", directory.path, "rev-parse", "--short", "HEAD"]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    return nil
                }
                guard process.terminationStatus == 0 else { return nil }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let text = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return text?.isEmpty == false ? text : nil
            }
        }
        return nil
    }
}
