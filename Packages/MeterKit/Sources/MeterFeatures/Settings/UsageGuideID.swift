import Foundation

/// 利用指南的稳定 id。字符串会进偏好和迁移包，改名等于让所有人再看一遍。
enum UsageGuideID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case heroExcludesSubscriptions
    case awsRefreshCostsMoney
    case keysStayOnThisDevice
    case inboxForMissingAPIs
    case widgetOnLockScreen

    var id: String { rawValue }
}
