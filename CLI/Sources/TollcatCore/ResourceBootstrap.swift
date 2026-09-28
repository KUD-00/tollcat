import Foundation
import MeterBridge
import MeterProviders

package enum ResourceBootstrap {
    package static func install(environment: [String: String] = ProcessInfo.processInfo.environment) {
        if JNIResourceRoot.url != nil { return }
        for candidate in candidates(environment: environment) {
            let catalog = candidate.appendingPathComponent("catalog.json")
            if FileManager.default.isReadableFile(atPath: catalog.path) {
                JNIResourceRoot.set(candidate)
                return
            }
        }
    }

    static func candidates(environment: [String: String]) -> [URL] {
        var urls: [URL] = []
        if let override = environment["TOLLCAT_RESOURCE_ROOT"], !override.isEmpty {
            urls.append(URL(fileURLWithPath: override, isDirectory: true))
        }
        let executable = URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        urls.append(executable)
        urls.append(executable.appendingPathComponent("MeterCoreCLI_MeterBridge.bundle"))
        urls.append(executable.appendingPathComponent("MeterCoreCLI_MeterBridge.resources"))
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        urls.append(cwd.appendingPathComponent("Android/native/Sources/MeterBridge/Resources"))
        urls.append(cwd.appendingPathComponent("CLI/Sources/MeterBridge/Resources"))
        let here = URL(fileURLWithPath: #filePath)
        let repo = here
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        urls.append(repo.appendingPathComponent("Android/native/Sources/MeterBridge/Resources"))
        urls.append(repo.appendingPathComponent("Packages/MeterKit/Sources/MeterPersistence/Catalog"))
        return urls
    }
}
