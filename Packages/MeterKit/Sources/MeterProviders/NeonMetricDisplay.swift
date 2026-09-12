import Foundation

/// Neon consumption 的 metric 名 → 明细里怎么写。
///
/// **用 Neon 自己的词，不译。** Console → Billing 那一页写的就是 Compute / Storage /
/// Data transfer，和 Cloudflare 的 `ServiceFamilyName` 一样原样透传，
/// 用户拿 App 和厂商后台对账时能一眼对上。
///
/// 数量按**计价单位**给，不给原始的字节和秒：`NeonPlanPricing` 就是按
/// CU-hours / GB-months / GB 算钱的，明细里写 `513202514 bytes` 没人对得上账。
enum NeonMetricDisplay: String, Sendable, CaseIterable {
    case computeUnitSeconds = "compute_unit_seconds"
    case rootBranchBytesMonth = "root_branch_bytes_month"
    case childBranchBytesMonth = "child_branch_bytes_month"
    case instantRestoreBytesMonth = "instant_restore_bytes_month"
    case snapshotStorageBytesMonth = "snapshot_storage_bytes_month"
    case publicNetworkTransferBytes = "public_network_transfer_bytes"
    case privateNetworkTransferBytes = "private_network_transfer_bytes"
    case extraBranchesMonth = "extra_branches_month"

    /// 分组名。
    var family: String {
        switch self {
        case .computeUnitSeconds:
            return "Compute"
        case .rootBranchBytesMonth, .childBranchBytesMonth, .snapshotStorageBytesMonth:
            return "Storage"
        case .instantRestoreBytesMonth:
            return "Instant restore"
        case .publicNetworkTransferBytes, .privateNetworkTransferBytes:
            return "Data transfer"
        case .extraBranchesMonth:
            return "Branches"
        }
    }

    /// 行名。和 `family` 一样的那几个（Compute）留着——分组只有一条时
    /// 界面本来就不重复列。
    var label: String {
        switch self {
        case .computeUnitSeconds: return "Compute"
        case .rootBranchBytesMonth: return "Root branch storage"
        case .childBranchBytesMonth: return "Child branch storage"
        case .instantRestoreBytesMonth: return "Instant restore"
        case .snapshotStorageBytesMonth: return "Snapshot storage"
        case .publicNetworkTransferBytes: return "Public network transfer"
        case .privateNetworkTransferBytes: return "Private network transfer"
        case .extraBranchesMonth: return "Extra branches"
        }
    }

    var unit: String {
        switch self {
        case .computeUnitSeconds: return "CU-hours"
        case .rootBranchBytesMonth, .childBranchBytesMonth,
             .instantRestoreBytesMonth, .snapshotStorageBytesMonth:
            return "GB-months"
        case .publicNetworkTransferBytes, .privateNetworkTransferBytes: return "GB"
        case .extraBranchesMonth: return "branch-hours"
        }
    }

    /// 原始读数换成计价单位。换算比例和 `NeonPlanPricing.costUSD` 里的一致，
    /// 改一边必须改另一边——两边对不上，明细里的数量就解释不了那笔钱。
    func quantity(from raw: Decimal) -> Decimal {
        switch self {
        case .computeUnitSeconds:
            return raw / 3600
        case .rootBranchBytesMonth, .childBranchBytesMonth,
             .instantRestoreBytesMonth, .snapshotStorageBytesMonth,
             .publicNetworkTransferBytes, .privateNetworkTransferBytes:
            return raw / 1_000_000_000
        case .extraBranchesMonth:
            return raw
        }
    }
}
