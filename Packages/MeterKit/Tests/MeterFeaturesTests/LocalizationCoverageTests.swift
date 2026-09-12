import Foundation
import Testing

/// 每一条会被用户看到的字都得有英文和日文。
///
/// 这条以前只靠人记着，于是漏了 148 条——两轮功能做完才被发现。
/// 漏译不会让任何东西崩，编译也过，只有把设备语言切过去才看得见，
/// 所以它必须由机器盯着。
///
/// 目录**不是**权威。SPM 包里的 catalog，xcodebuild 增量编译经常不重新抽取：
/// 改了中文源串，旧键就地变孤儿（或被标 stale），新键根本不会出现。
/// 所以下面分两层：目录里已有的条目不能缺译文；源码里的 `L(…)` 必须能对上
/// 目录里的一条。`shouldTranslate: false` 刻意不翻，跳过。
///
/// 同一套判据还跑在 `scripts/check-i18n-coverage.py`：pre-commit 和 CI
/// 用那份，避免只靠 xcodebuild 测试才发现漏译。判据改了两边一起改。
/// Info.plist 权限用途说明另有 `InfoPlist.xcstrings`，不走 `L()`。
///
/// 用词闸（`copyTerms`）和 `scripts/check-source-invariants.py` 的
/// `COPY_TERMS` 同步。以后加禁止项，两边一起加。
struct LocalizationCoverageTests {
    private static let languages = ["en", "ja"]
    private static let interpolationSentinel = "«»"

    private static let catalogs = [
        "MeterCore",         // 没有目录，下面会跳过
        "MeterDesign",
        "MeterProviders",
        "MeterPersistence",
        "MeterTips",
        "MeterInbox",        // 叶子模块，现在没有目录
        "MeterFeedback",     // 同上
        "MeterUsage",        // 同上
        "MeterFeatures",
    ]

    @Test("每个模块的 String Catalog 里没有缺英文或日文的条目")
    func everyStringIsTranslated() throws {
        var gaps: [String] = []
        var checked = 0

        for module in Self.catalogs {
            let path = sourcesRoot
                .appending(path: module)
                .appending(path: "Resources/Localizable.xcstrings")
            guard FileManager.default.fileExists(atPath: path.path) else { continue }

            let catalog = try decode(path)
            #expect(
                catalog.sourceLanguage == "zh-Hans",
                "\(module) 的源语言变了，这条测试的假设要跟着改"
            )

            for (key, entry) in catalog.strings {
                if entry.extractionState == "stale" { continue }
                if entry.shouldTranslate == false { continue }
                checked += 1
                for language in Self.languages {
                    let value = entry.localizations?[language]?.stringUnit?.value
                    if value?.isEmpty ?? true {
                        gaps.append("[\(module)][\(language)] \(key)")
                    }
                }
            }
        }

        #expect(checked > 0, "一条都没检查到，说明路径或解析错了")
        let gapReport = "缺 \(gaps.count) 条译文:\n" + gaps.sorted().joined(separator: "\n")
        #expect(gaps.isEmpty, Comment(rawValue: gapReport))
    }

    /// 系统权限弹窗不查 Localizable.xcstrings。漏译时英文机弹出中文。
    @Test("Info.plist 权限用途说明有中英日")
    func infoPlistUsageDescriptionsAreTranslated() throws {
        let yml = try String(
            contentsOf: repoRoot.appending(path: "project.yml"),
            encoding: .utf8
        )
        var keys: [String] = []
        for line in yml.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("INFOPLIST_KEY_"),
                  trimmed.contains("UsageDescription") else { continue }
            let rest = trimmed.dropFirst("INFOPLIST_KEY_".count)
            guard let colon = rest.firstIndex(of: ":") else { continue }
            let key = String(rest[..<colon]).trimmingCharacters(in: .whitespaces)
            if key.hasSuffix("UsageDescription") {
                keys.append(key)
            }
        }

        let catalogURL = repoRoot.appending(path: "App/Resources/InfoPlist.xcstrings")
        if keys.isEmpty {
            if FileManager.default.fileExists(atPath: catalogURL.path) {
                let leftovers = try decode(catalogURL).strings.keys.filter {
                    $0.hasSuffix("UsageDescription")
                }
                #expect(
                    leftovers.isEmpty,
                    "project.yml 没有用途说明，InfoPlist.xcstrings 却还留着 \(leftovers.sorted())"
                )
            }
            return
        }

        let catalog = try decode(catalogURL)
        #expect(
            catalog.sourceLanguage == "zh-Hans",
            "InfoPlist.xcstrings 的源语言变了，这条测试的假设要跟着改"
        )
        var gaps: [String] = []
        for key in keys {
            guard let entry = catalog.strings[key] else {
                gaps.append("[InfoPlist] 没有目录条目：\(key)")
                continue
            }
            for language in ["zh-Hans"] + Self.languages {
                let value = entry.localizations?[language]?.stringUnit?.value
                if value?.isEmpty ?? true {
                    gaps.append("[InfoPlist][\(language)] \(key)")
                }
            }
        }
        #expect(gaps.isEmpty, Comment(rawValue: gaps.joined(separator: "\n")))
    }

    /// 译文里占位符的**类型序列**必须和源串一致。
    ///
    /// 这条不要求一律写成位置参数（`%1$@`）。仓库里已有十几条多参数译文语序
    /// 和中文一致，非位置写法在那儿是正确的，为了统一去动它们是纯churn。
    /// 真正会坏的是**类型顺序变了**：源串 `%@ … %lld`、译文写成 `%lld … %@`，
    /// 取参数时按位置读，读出来的是错类型——那会拿一个整数当字符串指针用。
    ///
    /// 用了位置参数的跳过：那种写法本来就允许语序自由。
    ///
    /// 同类型之间被调换（两个 `%@` 互换）这里查不出来——那需要语义。
    /// 所以新写多参数串时仍然应该用位置参数，只是不由这条测试强制。
    @Test("译文里占位符的类型序列和中文源串一致")
    func placeholderTypesKeepTheirOrder() throws {
        var offenders: [String] = []
        for module in Self.catalogs {
            let path = sourcesRoot
                .appending(path: module)
                .appending(path: "Resources/Localizable.xcstrings")
            guard FileManager.default.fileExists(atPath: path.path) else { continue }
            let catalog = try decode(path)
            for (key, entry) in catalog.strings {
                if entry.extractionState == "stale" { continue }
                let expected = Self.placeholderTypes(in: key)
                guard expected.count >= 2 else { continue }
                for language in Self.languages {
                    guard let value = entry.localizations?[language]?.stringUnit?.value,
                          !value.isEmpty else { continue }
                    // 位置参数把顺序显式写出来了，顺序自由。
                    if value.contains("$") { continue }
                    let actual = Self.placeholderTypes(in: value)
                    if actual != expected {
                        offenders.append(
                            "[\(module)][\(language)] \(key)\n    源 \(expected) → 译 \(actual)：\(value)"
                        )
                    }
                }
            }
        }
        let report = "占位符类型序列对不上:\n" + offenders.joined(separator: "\n")
        #expect(offenders.isEmpty, Comment(rawValue: report))
    }

    /// 译文里占位符的个数必须和源串一致。多一个取到垃圾，少一个静默丢数字。
    @Test("译文的占位符个数和中文源串一致")
    func placeholderCountsMatchTheSource() throws {
        var offenders: [String] = []
        for module in Self.catalogs {
            let path = sourcesRoot
                .appending(path: module)
                .appending(path: "Resources/Localizable.xcstrings")
            guard FileManager.default.fileExists(atPath: path.path) else { continue }
            let catalog = try decode(path)
            for (key, entry) in catalog.strings {
                if entry.extractionState == "stale" { continue }
                let expected = Self.placeholderCount(in: key)
                for language in Self.languages {
                    guard let value = entry.localizations?[language]?.stringUnit?.value,
                          !value.isEmpty else { continue }
                    let actual = Self.placeholderCount(in: value)
                    if actual != expected {
                        offenders.append("[\(module)][\(language)] \(key) 要 \(expected) 个，译文有 \(actual) 个：\(value)")
                    }
                }
            }
        }
        let report = "占位符个数对不上:\n" + offenders.joined(separator: "\n")
        #expect(offenders.isEmpty, Comment(rawValue: report))
    }

    /// 源码才是「有哪些字」的权威。目录漏抽、改源串没改键，这一条会抓到。
    @Test("源码里的 L() 在目录里都有英文和日文")
    func everySourceCallHasATranslation() throws {
        var gaps: [String] = []
        var checked = 0

        for module in Self.catalogs {
            let moduleRoot = sourcesRoot.appending(path: module)
            guard FileManager.default.fileExists(atPath: moduleRoot.path) else { continue }

            let catalogPath = moduleRoot.appending(path: "Resources/Localizable.xcstrings")
            let catalog: Catalog
            if FileManager.default.fileExists(atPath: catalogPath.path) {
                catalog = try decode(catalogPath)
            } else {
                catalog = Catalog(sourceLanguage: "zh-Hans", strings: [:])
            }

            var normalizedToKeys: [String: [String]] = [:]
            for key in catalog.strings.keys {
                normalizedToKeys[Self.replacingFormatSpecifiers(in: key), default: []].append(key)
            }

            for file in Self.swiftFiles(in: moduleRoot) {
                let text = try String(contentsOf: file, encoding: .utf8)
                let relative = String(file.path.dropFirst(sourcesRoot.path.count + 1))
                for call in Self.extractLCalls(from: text) {
                    checked += 1
                    let catalogKey: String?
                    if call.interpolated {
                        catalogKey = normalizedToKeys[call.normalized]?.first
                    } else if catalog.strings[call.normalized] != nil {
                        catalogKey = call.normalized
                    } else {
                        catalogKey = nil
                    }

                    guard let catalogKey, let entry = catalog.strings[catalogKey] else {
                        gaps.append("[\(module)] \(relative) 没有目录条目：\(call.normalized)")
                        continue
                    }
                    if entry.shouldTranslate == false { continue }
                    for language in Self.languages {
                        let value = entry.localizations?[language]?.stringUnit?.value
                        if value?.isEmpty ?? true {
                            gaps.append("[\(module)][\(language)] \(relative)：\(catalogKey)")
                        }
                    }
                }
            }
        }

        #expect(checked > 0, "一条都没检查到，说明源码扫描错了")
        let gapReport = "源码对不上目录，缺 \(gaps.count) 条:\n" + gaps.sorted().joined(separator: "\n")
        #expect(gaps.isEmpty, Comment(rawValue: gapReport))
    }

    static func placeholderCount(in text: String) -> Int {
        placeholderTypes(in: text).count
    }

    /// 抽出格式说明符的类型序列，例如 `["@", "lld"]`。
    ///
    /// **不能把每个 `%` 都当占位符。** 日文译文里有「1社100%を切り替え」这种
    /// 字面百分号——`を` 不是格式转换符，那个 `%` 就是个百分号。早先的版本
    /// 把它数成占位符，于是误报，而「照它说的改成 `%%`」会让界面真的显示出
    /// `100%%`：无参数的串根本不走 format 处理。
    static func placeholderTypes(in text: String) -> [String] {
        // 长度修饰符要先匹配长的（lld 在 ld 之前，否则 lld 会被切成 ld + d）
        let lengths = ["hh", "ll", "h", "l", "q", "z", "t", "j", "L"]
        let conversions = Set("@diuoxXeEfgGaAcspn%")
        var types: [String] = []
        var index = text.startIndex

        while index < text.endIndex {
            guard text[index] == "%" else {
                index = text.index(after: index)
                continue
            }
            var cursor = text.index(after: index)
            guard cursor < text.endIndex else { break }

            // %% 是字面百分号
            if text[cursor] == "%" {
                index = text.index(after: cursor)
                continue
            }
            // 位置参数 n$
            var positional = ""
            var probe = cursor
            while probe < text.endIndex, text[probe].isNumber {
                positional.append(text[probe])
                probe = text.index(after: probe)
            }
            if !positional.isEmpty, probe < text.endIndex, text[probe] == "$" {
                cursor = text.index(after: probe)
            }
            // 标志位和宽度 / 精度
            while cursor < text.endIndex, "-+ #0".contains(text[cursor]) {
                cursor = text.index(after: cursor)
            }
            while cursor < text.endIndex, text[cursor].isNumber || text[cursor] == "." {
                cursor = text.index(after: cursor)
            }
            guard cursor < text.endIndex else { break }
            // 长度修饰符
            var length = ""
            for candidate in lengths where text[cursor...].hasPrefix(candidate) {
                length = candidate
                cursor = text.index(cursor, offsetBy: candidate.count)
                break
            }
            guard cursor < text.endIndex, conversions.contains(text[cursor]) else {
                // 不是合法说明符 —— 这个 % 是字面百分号，跳过它继续找。
                index = text.index(after: index)
                continue
            }
            types.append(length + String(text[cursor]))
            index = text.index(after: cursor)
        }
        return types
    }

    /// 把 `%@` / `%lld` / `%%` 收成和源码插值同一套记号，才能对上 `L("共 \(n) 家")`。
    static func replacingFormatSpecifiers(in text: String) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            guard text[index] == "%" else {
                result.append(text[index])
                index = text.index(after: index)
                continue
            }
            var cursor = text.index(after: index)
            guard cursor < text.endIndex else {
                result.append("%")
                break
            }
            if text[cursor] == "%" {
                result.append("%")
                index = text.index(after: cursor)
                continue
            }
            var probe = cursor
            while probe < text.endIndex, text[probe].isNumber {
                probe = text.index(after: probe)
            }
            if probe != cursor, probe < text.endIndex, text[probe] == "$" {
                cursor = text.index(after: probe)
            }
            while cursor < text.endIndex, "-+ #0".contains(text[cursor]) {
                cursor = text.index(after: cursor)
            }
            while cursor < text.endIndex, text[cursor].isNumber || text[cursor] == "." {
                cursor = text.index(after: cursor)
            }
            let lengths = ["hh", "ll", "h", "l", "q", "z", "t", "j", "L"]
            for candidate in lengths where text[cursor...].hasPrefix(candidate) {
                cursor = text.index(cursor, offsetBy: candidate.count)
                break
            }
            let conversions = Set("@diuoxXeEfgGaAcspn%")
            if cursor < text.endIndex, conversions.contains(text[cursor]) {
                result.append(contentsOf: interpolationSentinel)
                index = text.index(after: cursor)
                continue
            }
            result.append("%")
            index = text.index(after: index)
        }
        return result
    }

    private struct SourceCall {
        var normalized: String
        var interpolated: Bool
    }

    private static func extractLCalls(from text: String) -> [SourceCall] {
        var calls: [SourceCall] = []
        var searchStart = text.startIndex
        while searchStart < text.endIndex,
              let range = text[searchStart...].range(of: "L(") {
            let start = range.lowerBound
            if start > text.startIndex {
                let previous = text[text.index(before: start)]
                if previous.isLetter || previous.isNumber || previous == "_" {
                    searchStart = range.upperBound
                    continue
                }
            }
            var cursor = range.upperBound
            while cursor < text.endIndex, text[cursor].isWhitespace {
                cursor = text.index(after: cursor)
            }
            guard cursor < text.endIndex, text[cursor] == "\"" else {
                searchStart = range.upperBound
                continue
            }
            guard let parsed = parseQuotedString(text, startingAt: cursor) else {
                searchStart = range.upperBound
                continue
            }
            if !parsed.normalized.isEmpty || parsed.interpolated {
                calls.append(SourceCall(normalized: parsed.normalized, interpolated: parsed.interpolated))
            }
            searchStart = parsed.end
        }
        return calls
    }

    private static func parseQuotedString(
        _ text: String,
        startingAt start: String.Index
    ) -> (normalized: String, interpolated: Bool, end: String.Index)? {
        var index = text.index(after: start)
        var normalized = ""
        var interpolated = false
        while index < text.endIndex {
            let character = text[index]
            if character == "\\" {
                let next = text.index(after: index)
                guard next < text.endIndex else { return nil }
                if text[next] == "(" {
                    interpolated = true
                    normalized.append(contentsOf: interpolationSentinel)
                    guard let after = skipInterpolation(text, from: text.index(after: next)) else {
                        return nil
                    }
                    index = after
                    continue
                }
                switch text[next] {
                case "n": normalized.append("\n")
                case "t": normalized.append("\t")
                case "\"": normalized.append("\"")
                case "\\": normalized.append("\\")
                default: normalized.append(text[next])
                }
                index = text.index(after: next)
                continue
            }
            if character == "\"" {
                return (normalized, interpolated, text.index(after: index))
            }
            normalized.append(character)
            index = text.index(after: index)
        }
        return nil
    }

    /// `from` 是 `\(` 后面第一个字符。
    private static func skipInterpolation(_ text: String, from start: String.Index) -> String.Index? {
        var depth = 1
        var index = start
        while index < text.endIndex, depth > 0 {
            let character = text[index]
            if character == "\\" {
                index = text.index(after: index)
                if index < text.endIndex {
                    index = text.index(after: index)
                }
                continue
            }
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            index = text.index(after: index)
        }
        return depth == 0 ? index : nil
    }

    private static func swiftFiles(in directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        var files: [URL] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            files.append(url)
        }
        return files
    }

    // MARK: - 解析

    private struct Catalog: Decodable {
        var sourceLanguage: String
        var strings: [String: Entry]
    }

    private struct Entry: Decodable {
        var extractionState: String?
        var shouldTranslate: Bool?
        var localizations: [String: Localization]?
    }

    private struct Localization: Decodable {
        var stringUnit: StringUnit?
    }

    private struct StringUnit: Decodable {
        var state: String?
        var value: String?
    }

    private func decode(_ url: URL) throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: try Data(contentsOf: url))
    }

    private var sourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // MeterFeaturesTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // MeterKit
            .appending(path: "Sources")
    }

    private var repoRoot: URL {
        sourcesRoot
            .deletingLastPathComponent()   // MeterKit
            .deletingLastPathComponent()   // Packages
            .deletingLastPathComponent()   // repo
    }

    /// 产品用词。和 `scripts/check-source-invariants.py` 的 `COPY_TERMS` 同步。
    private static let copyTerms: [(forbidden: String, replacement: String)] = [
        ("凭证", "凭据"),
        ("我拿到了，下一步", "我拿到凭据了，下一步"),
    ]

    @Test("关键词：凭证写成凭据，教程按钮写我拿到凭据了")
    func forbiddenCopyTermsAreAbsent() throws {
        var offenders: [String] = []
        let folders = [
            "App",
            "Widget",
            "Packages/MeterKit/Sources",
            "Packages/MeterKit/Tests",
            "docs",
            "scripts",
        ]
        let suffixes: Set<String> = ["swift", "xcstrings", "md", "py", "sh"]
        let skip: Set<String> = [
            "check-source-invariants.py",
            "LocalizationCoverageTests.swift",
        ]
        for folder in folders {
            let directory = repoRoot.appending(path: folder)
            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator {
                if skip.contains(url.lastPathComponent) { continue }
                if url.path.contains("/.build/") { continue }
                guard suffixes.contains(url.pathExtension) else { continue }
                offenders.append(contentsOf: try copyTermOffenders(in: url))
            }
        }
        let rootMarkdown = try FileManager.default.contentsOfDirectory(
            at: repoRoot,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        for url in rootMarkdown where url.pathExtension == "md" {
            offenders.append(contentsOf: try copyTermOffenders(in: url))
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    private func copyTermOffenders(in file: URL) throws -> [String] {
        let text = try String(contentsOf: file, encoding: .utf8)
        let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        var hits: [String] = []
        for term in Self.copyTerms {
            var search = text.startIndex
            while let range = text.range(of: term.forbidden, range: search..<text.endIndex) {
                let line = text[text.startIndex..<range.lowerBound].filter { $0 == "\n" }.count + 1
                hits.append(
                    "\(relative):\(line) 写「\(term.replacement)」，不要写「\(term.forbidden)」。"
                )
                search = range.upperBound
            }
        }
        return hits
    }
}
