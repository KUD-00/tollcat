import Foundation

/// Neon 官方「Usage and cost calculations」页上的单价。Consumption API 本身不返回美元。
///
/// 待核对：用真账号把这里算出的金额和 Console → Billing 对账；Plans 页调价后必须改这张表。
/// 待核对：Enterprise 可能有谈判价，文档说默认跟 Scale，对不上就标不支持。
enum NeonPlanPricing: String, Sendable {
    case free
    case launch
    case scale
    case agent
    case enterprise

    static func parse(_ raw: String?) -> NeonPlanPricing? {
        guard let raw else { return nil }
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "free": return .free
        case "launch": return .launch
        case "scale": return .scale
        case "agent": return .agent
        case "enterprise": return .enterprise
        default: return nil
        }
    }

    /// USD per CU-hour.
    var computePerCUHour: Decimal {
        switch self {
        case .free: return 0
        case .launch, .agent: return Decimal(string: "0.106")!
        case .scale, .enterprise: return Decimal(string: "0.222")!
        }
    }

    var rootStoragePerGBMonth: Decimal { self == .free ? 0 : Decimal(string: "0.35")! }
    var childStoragePerGBMonth: Decimal { self == .free ? 0 : Decimal(string: "0.35")! }
    var instantRestorePerGBMonth: Decimal { self == .free ? 0 : Decimal(string: "0.20")! }
    var snapshotPerGBMonth: Decimal { self == .free ? 0 : Decimal(string: "0.09")! }
    var publicTransferPerGB: Decimal { self == .free ? 0 : Decimal(string: "0.10")! }
    var privateTransferPerGB: Decimal {
        switch self {
        case .scale, .enterprise, .agent: return Decimal(string: "0.01")!
        default: return 0
        }
    }
    var extraBranchPerMonth: Decimal { self == .free ? 0 : Decimal(string: "1.50")! }

    /// 每个项目包含的分支数（含 root）。免费额度是这个数减 1。
    var branchesPerProject: Int {
        switch self {
        case .free: return 10
        case .launch: return 10
        case .scale, .agent, .enterprise: return 25
        }
    }

    /// 每个项目每月免费公共流量，单位 GB。
    var publicTransferAllowanceGB: Decimal { self == .free ? 0 : 500 }

    func costUSD(
        metric: String,
        rawValue: Decimal,
        hoursInBucket: Decimal
    ) -> Decimal {
        switch metric {
        case "compute_unit_seconds":
            return (rawValue / 3600) * computePerCUHour
        case "root_branch_bytes_month":
            return (rawValue / 1_000_000_000) * rootStoragePerGBMonth
        case "child_branch_bytes_month":
            return (rawValue / 1_000_000_000) * childStoragePerGBMonth
        case "instant_restore_bytes_month":
            return (rawValue / 1_000_000_000) * instantRestorePerGBMonth
        case "snapshot_storage_bytes_month":
            return (rawValue / 1_000_000_000) * snapshotPerGBMonth
        case "public_network_transfer_bytes":
            return 0
        case "private_network_transfer_bytes":
            return (rawValue / 1_000_000_000) * privateTransferPerGB
        case "extra_branches_month":
            // raw 是这个 bucket 的 branch-hours。先扣当天免费额度，再 / 744。
            // 待核对：文档示例按「每个项目每个时间桶」扣额度；多项目要分别扣。
            let freeHours = Decimal(branchesPerProject - 1) * hoursInBucket
            let billableHours = max(Decimal(0), rawValue - freeHours)
            return (billableHours / 744) * extraBranchPerMonth
        default:
            return 0
        }
    }
}
