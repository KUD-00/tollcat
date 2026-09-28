import Foundation

/// 只读。绝不把环境变量写回盘上。
struct EnvironmentVault: Sendable {
    var environment: [String: String]

    func fields(providerID: String, keys: [String]) -> [String: String] {
        EnvironmentField.fields(providerID: providerID, keys: keys, environment: environment)
    }
}
