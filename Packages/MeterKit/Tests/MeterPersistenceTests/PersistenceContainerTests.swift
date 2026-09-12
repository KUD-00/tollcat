import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

struct PersistenceContainerTests {
    @Test("App Group 标识按平台")
    func appGroupIdentifierIsTollCat() {
        #if os(macOS)
        #expect(PersistenceContainer.appGroupIdentifier.hasSuffix("com.zhechengqi.tollcat"))
        #expect(!PersistenceContainer.appGroupIdentifier.hasPrefix("group."))
        #else
        #expect(PersistenceContainer.appGroupIdentifier == PersistenceContainer.iOSAppGroupIdentifier)
        #expect(PersistenceContainer.iOSAppGroupIdentifier == "group.com.zhechengqi.tollcat")
        #endif
    }

    @Test(
        "生产配置把 store 放进 App Group，且不走 CloudKit",
        .enabled(if: PersistenceContainer.appGroupContainerURL() != nil)
    )
    func liveConfigurationLivesInAppGroup() throws {
        // SwiftData 在没有 entitlement 时是 Fatal error，不是 throw。
        let groupURL = try #require(PersistenceContainer.appGroupContainerURL())
        let configuration = PersistenceContainer.makeConfiguration()
        #expect(configuration.groupAppContainerIdentifier == PersistenceContainer.appGroupIdentifier)
        #expect(configuration.cloudKitContainerIdentifier == nil)
        #expect(!configuration.isStoredInMemoryOnly)
        #expect(
            configuration.url.standardizedFileURL.path.hasPrefix(groupURL.standardizedFileURL.path),
            "store URL \(configuration.url.path) is not under App Group \(groupURL.path)"
        )
    }

    @Test("内存配置不碰 App Group，给测试和 Preview 用")
    func inMemoryConfigurationDoesNotTouchAppGroup() throws {
        let configuration = PersistenceContainer.makeConfiguration(inMemory: true)
        #expect(configuration.isStoredInMemoryOnly)
        #expect(configuration.cloudKitContainerIdentifier == nil)

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        // 七张数据表 + 账本那三张（按月的行、每账号此刻的状态、折叠输入的戳）。
        #expect(container.schema.entities.count == 10)
    }

    /// 提交闸 `scripts/check-source-invariants.py` 扫同一套 import / SwiftData 禁令。
    @Test("MeterPersistence 不依赖 SwiftUI / Design / Providers")
    func persistenceImportsStayInContract() throws {
        let sources = moduleSourcesDirectory.appending(path: "MeterPersistence")
        let files = try swiftFiles(under: sources)
        #expect(!files.isEmpty)

        let forbidden = ["import SwiftUI", "import MeterDesign", "import MeterProviders"]
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for token in forbidden {
                #expect(!text.contains(token), "\(file.lastPathComponent) contains \(token)")
            }
        }
    }

    @Test("空库对 Widget 是空，不是 $0")
    @MainActor
    func emptySharedStoreIsEmptyNotZero() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let contents = try SharedStoreReader.load(from: container, calendar: utcCalendar, now: Date())
        #expect(contents.isEmpty)
        #expect(contents.view.rollups.isEmpty)
        #expect(contents.view.latest.isEmpty)
        #expect(contents.subscriptions.isEmpty)
        #expect(contents.lastSuccessfulRefreshAt == nil)
    }

    @Test("读出主 App 写下的 snapshot、订阅和最近刷新时间")
    @MainActor
    func sharedStoreReaderLoadsWhatTheAppWrote() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_787_000_000)
        let snapshot = Snapshot(
            providerID: .cloudflare,
            accountID: AccountID.fixture(for: .cloudflare),
            kind: .usage,
            fetchedAt: fetchedAt,
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_220_799),
            currentSpendUSD: Money(usd: Decimal(string: "11.05")!)
        )
        let subscription = MonthlySubscription(
            name: "GitHub Copilot",
            amount: Money(usd: 4),
            period: .monthly,
            anchorDate: Date(timeIntervalSince1970: 1_767_398_400),
            providerID: .github
        )

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(try SnapshotRecord(domain: snapshot, calendar: utcCalendar))
        context.insert(SubscriptionRecord(domain: subscription, calendar: utcCalendar))
        context.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare,
                isEnabled: true,
                sortIndex: 0,
                lastSuccessfulRefreshAt: fetchedAt,
                credentialReference: "credential.cloudflare"
            )
        )
        try context.save()

        let contents = try SharedStoreReader.load(from: container, calendar: utcCalendar, now: Date())
        #expect(!contents.isEmpty)
        // Widget 拿到的是**读模型**，不是快照日志。库里还没折账本时门自己折一份，
        // 所以这里断言的是折出来的行，而不是那条原始读数。
        #expect(contents.view.latest.map(\.accountID) == [snapshot.accountID])
        #expect(contents.view.latest.first?.fetchedAt == snapshot.fetchedAt)
        #expect(contents.view.rollups.contains { $0.hasReading })
        #expect(contents.subscriptions.count == 1)
        #expect(contents.subscriptions[0].name == "GitHub Copilot")
        #expect(contents.subscriptions[0].amount == Money(usd: 4))
        #expect(contents.lastSuccessfulRefreshAt == fetchedAt)
    }

    @Test("MeterCore 里没有 SwiftData 痕迹")
    func meterCoreHasNoSwiftData() throws {
        let sources = moduleSourcesDirectory.appending(path: "MeterCore")
        let files = try swiftFiles(under: sources)
        #expect(!files.isEmpty)

        let forbidden = ["SwiftData", "@Model", "ModelContainer", "ModelContext"]
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for token in forbidden {
                #expect(!text.contains(token), "\(file.lastPathComponent) contains \(token)")
            }
            for line in text.split(separator: "\n") {
                let stripped = line.trimmingCharacters(in: .whitespaces)
                if stripped.hasPrefix("import ") {
                    #expect(stripped == "import Foundation", "\(file.lastPathComponent) \(stripped)")
                }
            }
            // 墙钟进入这一层只有一个入口：`MeterClock`。和
            // `ArchitectureGuardrailTests` / `check-source-invariants.py` 同一条例外。
            guard file.lastPathComponent != "MeterClock.swift" else { continue }
            #expect(!text.contains("Date()"), "\(file.lastPathComponent) Date()")
            #expect(!text.contains("Calendar.current"), "\(file.lastPathComponent) Calendar.current")
        }
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
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
