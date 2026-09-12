import Foundation
import Testing
import MeterTips

struct TipModuleIsolationTests {
    /// 提交闸 `scripts/check-source-invariants.py` 扫同一套禁令。判据改了两边一起改。

    /// 四个叶子模块共用一个 Worker，但都不许认识账单模块。
    private static let leafModules = ["MeterTips", "MeterInbox", "MeterFeedback", "MeterUsage"]

    @Test("MeterProviders 不链接叶子模块，叶子也不碰账单 / 界面 / 存储")
    func dependencyGraphKeepsBillingOffTheWorker() throws {
        let sources = moduleSourcesDirectory
        let providerFiles = try swiftFiles(under: sources.appending(path: "MeterProviders"))
        #expect(!providerFiles.isEmpty)

        for file in providerFiles {
            let text = try String(contentsOf: file, encoding: .utf8)
            for leaf in Self.leafModules {
                #expect(
                    !text.contains("import \(leaf)"),
                    "\(file.lastPathComponent) imports \(leaf)"
                )
            }
        }

        // MeterInbox 可以 import MeterCore（它要产出 Snapshot），另两个不需要。
        // 除此之外三个模块的禁令一样：不认识目录、不认识界面、不落库。
        let forbidden = [
            "import MeterProviders",
            "import MeterFeatures",
            "import MeterPersistence",
            "import MeterTips",
            "import MeterInbox",
            "import MeterFeedback",
            "import MeterUsage",
            "import SwiftUI",
            "import SwiftData",
        ]
        for module in Self.leafModules {
            let files = try swiftFiles(under: sources.appending(path: module))
            #expect(!files.isEmpty, "\(module) 没有源文件")
            var tokens = forbidden.filter { !$0.hasSuffix(module) }
            // MeterFeedback / MeterUsage 连 MeterCore 都不许：不认识 Money，
            // 也就不可能把金额编进 payload。这一条比任何代码审查都可靠。
            if module == "MeterFeedback" || module == "MeterUsage" {
                tokens.append("import MeterCore")
            }
            for file in files {
                let text = try String(contentsOf: file, encoding: .utf8)
                for token in tokens {
                    #expect(!text.contains(token), "\(module)/\(file.lastPathComponent) contains \(token)")
                }
            }
        }
    }

    @Test("发请求的地方就这六处，Worker 的 host 只在五个 endpoint 常量里")
    func onlyDeclaredFilesTalkToTheNetwork() throws {
        let repoRoot = moduleSourcesDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let allowedURLSessionSuffixes = [
            "/Sources/MeterTips/TipWorkerClient.swift",
            "/Sources/MeterInbox/URLSessionInboxTransport.swift",
            "/Sources/MeterFeedback/URLSessionFeedbackSubmitter.swift",
            "/Sources/MeterUsage/URLSessionUsageSubmitter.swift",
            // 账单 API 的传输层。Worker 的 URL 不许出现在这里。
            "/Sources/MeterProviders/URLSessionHTTPClient.swift",
            // 在线目录。公开 JSON，没有凭据。
            "/Sources/MeterPersistence/LiveCatalogTransport.swift",
        ]
        // origin 在五个模块各写一份（不能互相 import），除此之外任何地方都不许出现。
        // OutboundHosts 里那条是 host 字符串不是 URL，靠下面的后缀判断放过。
        let allowedWorkerHostSuffixes = [
            "/Sources/MeterTips/TipWorkerEndpoint.swift",
            "/Sources/MeterInbox/InboxEndpoint.swift",
            "/Sources/MeterFeedback/FeedbackEndpoint.swift",
            "/Sources/MeterUsage/UsageEndpoint.swift",
            "/Sources/MeterPersistence/CatalogEndpoint.swift",
            "/Sources/MeterProviders/OutboundHosts.swift",
        ]
        var sessionOffenders: [String] = []
        var workerHostOffenders: [String] = []
        for folder in ["App", "Widget", "Packages/MeterKit/Sources"] {
            let files = try swiftFiles(under: repoRoot.appending(path: folder))
            for file in files {
                let text = try String(contentsOf: file, encoding: .utf8)
                if text.contains("URLSession"),
                   !allowedURLSessionSuffixes.contains(where: { file.path.hasSuffix($0) }) {
                    sessionOffenders.append(file.path)
                }
                if text.contains(Self.workerHost),
                   !allowedWorkerHostSuffixes.contains(where: { file.path.hasSuffix($0) }) {
                    workerHostOffenders.append(file.path)
                }
            }
        }
        #expect(sessionOffenders.isEmpty, "URLSession leaked: \(sessionOffenders)")
        #expect(workerHostOffenders.isEmpty, "Worker host leaked: \(workerHostOffenders)")
    }

    /// 写死一份字面量而不是从 `TipWorkerEndpoint` 读：这条断言要抓的就是
    /// 「有人把 host 抄到第四个文件里」，从常量读会让抄写行为自己通过检查。
    private static let workerHost = "api.tollcat.app"

    @Test("上面那份 host 字面量没有写错，和真正在用的那个一致")
    func hostLiteralMatchesEndpoint() {
        #expect(TipWorkerEndpoint.origin.host == Self.workerHost)
    }

    private var moduleSourcesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources")
    }

    private func swiftFiles(under root: URL) throws -> [URL] {
        var files: [URL] = []
        var stack = [root]
        while let directory = stack.popLast() {
            let children = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            for child in children {
                if (try child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    stack.append(child)
                } else if child.pathExtension == "swift" {
                    files.append(child)
                }
            }
        }
        return files
    }
}
