import Foundation
import Testing

/// 和 `scripts/check-source-invariants.py` 同一套架构禁令。改了两边一起改。
struct ArchitectureGuardrailTests {
    @Test("MeterCore 只 import Foundation，也不碰 Date() / Calendar.current")
    func meterCoreStaysPure() throws {
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterCore"]
        )
        #expect(!files.isEmpty)
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            let masked = GuardrailSourceScan.maskCommentsAndStrings(text)
            for line in text.split(separator: "\n") {
                let stripped = line.trimmingCharacters(in: .whitespaces)
                if stripped.hasPrefix("import ") {
                    #expect(
                        stripped == "import Foundation",
                        "\(file.lastPathComponent) \(stripped)"
                    )
                }
            }
            // 墙钟进入这一层只有一个入口：`MeterClock`。规矩要的是「时间从参数进来」，
            // 不是「这一层不知道现在几点」——时钟以前为了守字面禁令住在 MeterFeatures，
            // 结果 Modules / Persistence / Widget 拿不到它，各自去捡 `Calendar.current`。
            //
            // `MeterClock` 同时是 Locale 那条禁令的**唯一豁免**：它带 locale 不是为了
            // 产出话，是因为「历法 + 时区 + locale」三样合起来才是格式化缓存的钥匙
            // （见 `FormatterCache`）。和 `check-source-invariants.py` 的
            // `LOCALE_EXEMPT_CORE_FILES` 同一份名单，改了两边一起改。
            guard file.lastPathComponent != "MeterClock.swift" else {
                #expect(masked.contains("autoupdatingCurrent"), "MeterClock live 时钟要跟系统时区")
                continue
            }
            #expect(!masked.contains("Date()"), "\(file.lastPathComponent) Date()")
            #expect(!masked.contains("Date.now"), "\(file.lastPathComponent) Date.now")
            #expect(!masked.contains("Calendar.current"), "\(file.lastPathComponent) Calendar.current")
            // 隐式成员写法（`calendar.locale = .autoupdatingCurrent`）字面量匹配不到，
            // 而 `MeterClock` 里就是这么写的——这条禁令过去是靠拼写通过的。
            #expect(
                !masked.contains("Locale.current"),
                "\(file.lastPathComponent) Locale.current"
            )
            #expect(
                !masked.contains("autoupdatingCurrent"),
                "\(file.lastPathComponent) autoupdatingCurrent"
            )
        }
    }

    /// 宽度档由容器声明（`meterModuleStyle`），模块只读。模块自己量宽再据此改版式，
    /// 是「量自身宽 → 改内容 → 内容改变理想宽」的反馈环——仪表盘实验室第一版就是
    /// 这样把主线程转死的（列宽 12pt 一步涨到无限）。
    @Test("模块视图不许自己量宽")
    func modulesDoNotMeasureThemselves() throws {
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterModules"]
        )
        #expect(!files.isEmpty)
        for file in files {
            let masked = GuardrailSourceScan.maskCommentsAndStrings(
                try String(contentsOf: file, encoding: .utf8)
            )
            for token in ["GeometryReader", "onGeometryChange"] {
                #expect(!masked.contains(token), "\(file.lastPathComponent) \(token)")
            }
        }
    }

    /// 这张依赖表就是 widget 的安全说明书：MeterModules 一旦长出新的边，
    /// widget 想复用模块视图就得把那条边一起链进扩展。
    ///
    /// MeterGlance 是零依赖叶子（下面那条测试守着它），链进 widget 的只是
    /// 一份值类型和几块锁屏视图——`GlanceBuilder` 得住在这边才读得到仪表内容。
    /// MeterDashboard 是模块读的那些值和算它们的 builder，它自己只认 MeterCore / MeterFormat。
    @Test("MeterModules 只依赖 MeterCore / MeterDesign / MeterFormat / MeterDashboard / MeterGlance")
    func moduleTargetStaysThin() throws {
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterModules"]
        )
        let allowed: Set<String> = [
            "import Foundation", "import SwiftUI", "import CoreGraphics",
            "import MeterCore", "import MeterDesign", "import MeterFormat", "import MeterDashboard",
            "import MeterGlance",
        ]
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for line in text.split(separator: "\n") {
                let stripped = line.trimmingCharacters(in: .whitespaces)
                guard stripped.hasPrefix("import ") else { continue }
                #expect(allowed.contains(stripped), "\(file.lastPathComponent) \(stripped)")
            }
        }
    }

    /// MeterDashboard 的源码被 Android / Windows / CLI 的桥软链进去直接编。
    /// 这里一出现 SwiftUI、MeterDesign 或 Android 的 Foundation 没有的类型，
    /// 桥就编不过——而上一次编不过的结果，是桥里抄了一份 builder、抄的那份漂走了。
    /// 和 `check-source-invariants.py` 的 `check_dashboard_portable` 同一条判据。
    @Test("MeterDashboard 只依赖 MeterCore / MeterFormat，四个平台都能编")
    func dashboardTargetStaysPortable() throws {
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterDashboard"]
        )
        #expect(!files.isEmpty)
        let allowed: Set<String> = ["import Foundation", "import MeterCore", "import MeterFormat"]
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for line in text.split(separator: "\n") {
                let stripped = line.trimmingCharacters(in: .whitespaces)
                guard stripped.hasPrefix("import ") else { continue }
                #expect(allowed.contains(stripped), "\(file.lastPathComponent) \(stripped)")
            }
            // 两处例外都在 `#if canImport(Darwin)` 里：`StaleSinceText` 用系统的相对时间，
            // 生成的 `MeterDashboardCopy` 在 Apple 平台把 String Catalog 的包交给 `PortableCatalog`。
            guard !["StaleSinceText.swift", "MeterDashboardCopy.swift"].contains(file.lastPathComponent) else {
                continue
            }
            let masked = GuardrailSourceScan.maskCommentsAndStrings(text)
            for token in ["LocalizedStringResource", "RelativeDateTimeFormatter", "String(localized:", "Bundle.module"] {
                #expect(!masked.contains(token), "\(file.lastPathComponent) \(token)")
            }
        }
    }

    /// 手表上看到的每一个数都是 iPhone 推过去的。依赖表是这件事的证明：
    /// MeterGlance 一 import 别的 Meter 模块，手表壳就跟着链上它，凭据和账本就有了上手表的路。
    /// 和 `check-source-invariants.py` 的 `check_watch_linkage` 同一条判据。
    @Test("MeterGlance 和手表壳不认识别的 Meter 模块")
    func watchSideStaysLeaf() throws {
        let glance = try GuardrailSourceScan.swiftFiles(under: ["Packages/MeterKit/Sources/MeterGlance"])
        #expect(!glance.isEmpty)
        for file in glance {
            let text = try String(contentsOf: file, encoding: .utf8)
            for line in text.split(separator: "\n") where line.hasPrefix("import Meter") {
                Issue.record("MeterGlance/\(file.lastPathComponent) \(line)")
            }
        }
        let shells = try GuardrailSourceScan.swiftFiles(under: ["Watch", "WatchWidget"])
        #expect(!shells.isEmpty)
        for file in shells {
            let text = try String(contentsOf: file, encoding: .utf8)
            for line in text.split(separator: "\n") where line.hasPrefix("import Meter") && line != "import MeterGlance" {
                Issue.record("\(file.lastPathComponent) \(line)：手表壳只准认 MeterGlance")
            }
        }
    }

    @Test("Widget 不 import MeterProviders；两份 spec 也都不链")
    func widgetDoesNotLinkProviders() throws {
        let files = try GuardrailSourceScan.swiftFiles(under: ["Widget"])
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            #expect(
                !text.contains("import MeterProviders"),
                "\(file.lastPathComponent) import MeterProviders"
            )
        }
        let yml = try Self.spec("project.yml")
        // Mac 的 target 在自己那份 spec 里（拆开的理由见 project.yml 顶上）。
        let macYML = try Self.spec("project-mac.yml")
        let widget = try Self.block(named: "TollCatWidget", in: yml)
        #expect(!widget.contains("MeterProviders"))
        let widgetMac = try Self.block(named: "TollCatWidgetMac", in: macYML)
        #expect(!widgetMac.contains("MeterProviders"))
        let app = try Self.block(named: "TollCat", in: yml)
        let linksStoreKitTest = app.split(separator: "\n").contains {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("- sdk: StoreKitTest.framework")
        }
        #expect(!linksStoreKitTest)
    }

    @Test("第三方包只准进 Mac 那份 spec：iOS 工程不该为它联网解析")
    func thirdPartyPackagesLiveOnlyInTheMacSpec() throws {
        // SPM 的包解析是工程级的：Sparkle 写进 iOS 那份 spec，
        // `xcodebuild -scheme TollCat` 也会先 fetch / checkout 一遍它永远不链的东西。
        // 和 scripts/check-source-invariants.py 的 check_xcode_specs 同一条规则。
        for name in ["project.yml", "project-common.yml"] {
            let text = try Self.spec(name)
            for line in text.split(separator: "\n") {
                let stripped = line.trimmingCharacters(in: .whitespaces)
                #expect(!stripped.hasPrefix("url: https://"), "\(name) 有远程 package")
                #expect(!stripped.hasPrefix("Sparkle:"), "\(name) 出现 Sparkle")
            }
        }
        let mac = try Self.spec("project-mac.yml")
        let macLines = mac.split(separator: "\n").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        #expect(macLines.contains("Sparkle:"))
        // 团队 ID 和版本号只有一处：Mac 那份靠 include 拿。
        #expect(mac.contains("project-common.yml"))
    }

    @Test("Package.swift 没有第三方包")
    func packageHasNoThirdParty() throws {
        let text = try String(
            contentsOf: GuardrailSourceScan.repoRoot.appending(path: "Packages/MeterKit/Package.swift"),
            encoding: .utf8
        )
        #expect(!text.contains(".package("))
    }

    @Test("Keychain 档位是 ThisDeviceOnly；转移码 10 位，PBKDF2 60 万轮")
    func secretsStayOnThisDevice() throws {
        let keychain = try GuardrailSourceScan.sourceText(named: "KeychainCredentialStore.swift")
        #expect(keychain.contains("kSecAttrAccessibleWhenUnlockedThisDeviceOnly"))
        #expect(!keychain.contains("kSecAttrAccessibleAfterFirstUnlock"))
        let code = try GuardrailSourceScan.sourceText(named: "TransferCode.swift")
        #expect(code.contains("static let characterCount = 10"))
        let deriver = try GuardrailSourceScan.sourceText(named: "TransferKeyDeriver.swift")
        #expect(deriver.contains("static let iterationCount = 600_000"))
        #expect(deriver.contains("static let minimumIterationCount = 600_000"))
        let masked = GuardrailSourceScan.maskCommentsAndStrings(deriver)
        #expect(!masked.contains("HKDF"))
    }

    @Test("生产路径没有 URLSession.shared、手搓玻璃、≈、MockBillingProvider")
    func productionNetworkAndCopyBans() throws {
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["App", "Mac", "Widget", "Packages/MeterKit/Sources"]
        )
        #expect(!files.isEmpty)
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            let masked = GuardrailSourceScan.maskCommentsAndStrings(text)
            #expect(!masked.contains("URLSession.shared"), "\(file.lastPathComponent)")
            #expect(!text.contains("import ActivityKit"), "\(file.lastPathComponent)")
            #expect(!masked.contains("MockBillingProvider"), "\(file.lastPathComponent)")
            for token in ["ultraThinMaterial", "thinMaterial", "regularMaterial", "thickMaterial"] {
                #expect(!masked.contains(token), "\(file.lastPathComponent) \(token)")
            }
            #expect(!masked.contains("≈"), "\(file.lastPathComponent) ≈")
        }
    }

    @Test("允许发请求的文件必须给 URLSession 装重定向委托")
    func urlSessionsRecheckRedirects() throws {
        let names = [
            "URLSessionHTTPClient.swift",
            "TipWorkerClient.swift",
            "URLSessionInboxTransport.swift",
            "URLSessionFeedbackSubmitter.swift",
            "URLSessionUsageSubmitter.swift",
            "LiveCatalogTransport.swift",
        ]
        for name in names {
            let text = try GuardrailSourceScan.sourceText(named: name)
            #expect(text.contains("URLSession("), "\(name) 应构造 URLSession")
            #expect(text.contains("delegate:"), "\(name) 重定向必须再过 host")
            #expect(!text.contains("URLSession.shared"), "\(name)")
        }
    }

    private static func block(named name: String, in yml: String) throws -> String {
        let lines = yml.split(separator: "\n", omittingEmptySubsequences: false)
        var collecting = false
        var body: [String] = []
        for line in lines {
            let text = String(line)
            if text.hasPrefix("  \(name):") {
                collecting = true
                continue
            }
            if collecting {
                if text.hasPrefix("  "), !text.hasPrefix("    "), !text.hasPrefix("  #") {
                    if text.range(of: "^  [A-Za-z]", options: .regularExpression) != nil {
                        break
                    }
                }
                body.append(text)
            }
        }
        if body.isEmpty {
            throw GuardrailScanError(message: "\(name) 读不出目标块")
        }
        return body.joined(separator: "\n")
    }

    /// 仓库根上的 XcodeGen spec。
    private static func spec(_ name: String) throws -> String {
        try String(
            contentsOf: GuardrailSourceScan.repoRoot.appending(path: name),
            encoding: .utf8
        )
    }
}

/// 展示版本的**单写入方**纪律。绕过这几处的写路径会让派生缓存吐旧数字，
/// 表现是「不崩、不报错，屏幕上那个数停在上一次」——正是缓存类 bug 最难查的那一种。
@MainActor
struct PresentationRevisionGuardrailTests {
    @Test("推进展示版本的地方只有 DashboardModel 和它的定义文件")
    func presentationRevisionHasOneWriter() throws {
        let allowed: Set<String> = ["DashboardModel.swift", "PresentationRevision.swift"]
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterFeatures"]
        )
        #expect(!files.isEmpty)
        var offenders: [String] = []
        for file in files where !allowed.contains(file.lastPathComponent) {
            let masked = GuardrailSourceScan.maskCommentsAndStrings(
                try String(contentsOf: file, encoding: .utf8)
            )
            for token in ["noteGlobalChange", "noteReading"] where masked.contains(token) {
                offenders.append("\(file.lastPathComponent) \(token)")
            }
        }
        #expect(
            offenders.isEmpty,
            "展示版本只能在 DashboardModel 里推进，见 PresentationRevision 的「纪律」一节：\(offenders)"
        )
    }

    @Test("扔掉内存里那份读数的地方只有 DashboardModel 和它的定义文件")
    func readingCacheHasOneInvalidator() throws {
        let allowed: Set<String> = ["DashboardModel.swift", "ReadingCache.swift"]
        let files = try GuardrailSourceScan.swiftFiles(
            under: ["Packages/MeterKit/Sources/MeterFeatures"]
        )
        var offenders: [String] = []
        for file in files where !allowed.contains(file.lastPathComponent) {
            let masked = GuardrailSourceScan.maskCommentsAndStrings(
                try String(contentsOf: file, encoding: .utf8)
            )
            for token in ["readingCache", "ReadingCache("] where masked.contains(token) {
                offenders.append("\(file.lastPathComponent) \(token)")
            }
        }
        #expect(offenders.isEmpty, "读数缓存的生命周期只归 DashboardModel 管：\(offenders)")
    }

    @Test("详情页的派生缓存钥匙必须是分格的，不许退回全局那一个数")
    func detailKeysStayScoped() throws {
        let masked = GuardrailSourceScan.maskCommentsAndStrings(
            try GuardrailSourceScan.sourceText(named: "ProviderDetailModel.swift")
        )
        // 钥匙从 `scope` 取，而 `scope` 只有一个出处。
        #expect(masked.contains("dashboard.revision.scoped(to: providerID)"))
        #expect(!masked.contains("presentationToken"))
        // 7 / 30 天共用一条日线。钥匙只记天/月，漏掉会让切档位数字不变。
        #expect(masked.contains("granularity"))
        #expect(!masked.contains("historyOffset"))
        #expect(masked.contains("ChartKey"))
    }
}
