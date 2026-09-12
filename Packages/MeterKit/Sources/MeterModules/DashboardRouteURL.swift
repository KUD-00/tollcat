import Foundation
import MeterCore

/// 深链：widget 和通知点进来时要去哪一页。
///
/// 表放在模块这一层，**两端共用同一份**：widget（`MeterModules` 它链得到）负责写出
/// URL，App 负责认回来。各写一半迟早会漂成两套拼法，而漂了之后的症状是「点了没反应」，
/// 没有编译期信号。
///
/// scheme 在两份 Info.plist 里注册（`App/Supporting-Info.plist`、`Mac/Supporting-Info.plist`）。
public enum DashboardDeepLink {
    public static let scheme = "tollcat"

    /// 只打开仪表盘，不推任何详情页。widget 上「一整块」的落点。
    public static var dashboardURL: URL {
        URL(string: "\(scheme)://dashboard")!
    }

    /// 认回来。不是本 app 的 scheme、或者路径不认识，一律 nil——
    /// 宁可当没点过，也不要猜一个页面推出去。
    public static func route(from url: URL) -> DashboardRoute? {
        guard url.scheme == scheme else { return nil }
        let host = url.host()
        let value = url.pathComponents.first { $0 != "/" }
        switch host {
        case "composition": return .composition
        case "comparison": return .comparison
        case "subscriptions": return .subscriptions
        case "heatmap": return .heatmap
        case "categories": return .categories
        case "account":
            guard let value, let uuid = UUID(uuidString: value) else { return nil }
            return .account(AccountID(rawValue: uuid))
        case "provider":
            guard let value, !value.isEmpty else { return nil }
            return .provider(ProviderID(rawValue: value))
        default: return nil
        }
    }

    /// 这个 URL 是「打开仪表盘」而不是某一页。
    public static func isDashboard(_ url: URL) -> Bool {
        url.scheme == scheme && url.host() == "dashboard"
    }
}

public extension DashboardRoute {
    /// 写出去。和 `DashboardDeepLink.route(from:)` 是一对，改一边要改另一边——
    /// `DashboardRouteURLTests` 会把每个 case 都走一遍来回。
    var deepLinkURL: URL {
        let base = "\(DashboardDeepLink.scheme)://"
        switch self {
        case .composition: return URL(string: base + "composition")!
        case .comparison: return URL(string: base + "comparison")!
        case .subscriptions: return URL(string: base + "subscriptions")!
        case .heatmap: return URL(string: base + "heatmap")!
        case .categories: return URL(string: base + "categories")!
        case .account(let id): return URL(string: base + "account/\(id.rawValue.uuidString)")!
        case .provider(let id): return URL(string: base + "provider/\(id.rawValue)")!
        }
    }
}
