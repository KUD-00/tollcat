import Foundation

/// 这条读数是谁取的。
///
/// 混在同一段历史里会毁掉两件事：`Confidence` 没法推理，
/// 以及「这个数和你后台看到的一致」这个承诺失效。所以来源必须跟着快照走，
/// 和 `kind` 一样永久落库（SPEC 第 07 节「历史保真」）。
public enum SnapshotSource: String, Hashable, Sendable, Codable, CaseIterable {
    /// App 自己打官方账单接口取回来的。
    case api
    /// 用户在自己机器上取数后投递到读数信箱，App 取回来的。
    /// 这一档我们不保证和官方后台对得上——取数逻辑不在我们手里。
    case inbox
    /// 用户在详情里填的某个月花费。合同和信箱相同，只是输入面在 App 里。
    case manual

    /// JSON 容错入口（Android JNI 解 snapshot JSON 用）：字段缺失或不认识时按 `api` 读。
    public static func fromStored(_ raw: String?) -> SnapshotSource {
        guard let raw, let value = SnapshotSource(rawValue: raw) else { return .api }
        return value
    }

    /// 能不能声称和官方后台对得上。详情页那句话按它选。
    public var reconcilesWithVendorConsole: Bool {
        self == .api
    }

    /// 本月至今由用户提供，周期就是投递 / 填写的那个月。
    public var isUserSupplied: Bool {
        self == .inbox || self == .manual
    }
}
