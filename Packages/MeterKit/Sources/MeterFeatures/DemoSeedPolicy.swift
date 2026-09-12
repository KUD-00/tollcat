import Foundation
import SwiftData
import MeterCore
import MeterPersistence

/// 演示种子必须能和真实账单分开。引用前缀写在 store 里，不靠口头约定。
public enum DemoSeedPolicy: Sendable {
    public static let seedArgument = "-seed-demo"
    public static let skipArgument = "-skip-demo-seed"
    public static let referencePrefix = "demo.credential."

    /// `arguments` 默认走 `FeatureLaunchArguments`——它在 Release 里是空的。
    /// 直接读 `ProcessInfo` 的话，直发的 Mac 版 `--args -seed-demo` 就能把演示账单
    /// 铺进正式安装里，而演示数据和真实账单在界面上只差一条横幅。
    public static func shouldSeedEmptyStore(
        arguments: [String] = FeatureLaunchArguments.arguments,
        demoModeEnabled: Bool = false
    ) -> Bool {
        if arguments.contains(skipArgument) {
            return false
        }
        if arguments.contains(seedArgument) {
            return true
        }
        return demoModeEnabled
    }

    public static func credentialReference(for id: AccountID) -> String {
        referencePrefix + id.rawValue.uuidString
    }

    public static func storeContainsDemoData(_ container: ModelContainer) -> Bool {
        let context = ModelContext(container)
        let records = (try? context.fetch(FetchDescriptor<ProviderConfigRecord>())) ?? []
        return records.contains { $0.credentialReference.hasPrefix(referencePrefix) }
    }
}
