import MeterCore

/// 启动画面口袋里插着的三枚通用服务圆牌。图标和启动画面用同一组（`scripts/render-app-icon.py`）。
///
/// 它们不代表任何一家，只代表一类服务：过渡时各自飞到构成卡片里第一家同类服务的色块上。
public enum LaunchTokenKind: String, CaseIterable, Sendable {
    case cloud
    case ai
    case database

    /// 这类服务算哪枚圆牌。认不出的类别不飞，跟着口袋一起沉下去。
    public static func kind(for category: ProviderCategory) -> LaunchTokenKind? {
        switch category {
        case .hosting, .networkEdge, .storage, .gpuCompute: .cloud
        case .aiInference: .ai
        case .database, .search: .database
        default: nil
        }
    }
}
