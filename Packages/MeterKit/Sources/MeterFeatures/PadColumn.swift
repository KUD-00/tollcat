import SwiftUI

/// 横屏三栏里，同一个 Settings/Services 实例不能同时占两列。
/// 用环境告诉这一份该画列表还是详情，状态仍在共享的 model 上。
enum PadColumn: Equatable {
    case list
    case detail
}

private struct PadColumnKey: EnvironmentKey {
    static let defaultValue: PadColumn? = nil
}

extension EnvironmentValues {
    var padColumn: PadColumn? {
        get { self[PadColumnKey.self] }
        set { self[PadColumnKey.self] = newValue }
    }
}
