import Foundation

/// 一批匿名页面计数离开设备时**只带这些字段**。
///
/// 不在这里、以后也不该加进来的东西：
/// - 任何 provider 凭据
/// - 任何金额、用量、余额、厂商名字
/// - 任何设备或用户标识（没有 IDFV、没有广告标识、没有日切 token）
/// - locale、时区、机型、系统版本
///
/// `newVisit` 是「这个 UTC 日，这台设备还没成功报过第一次打开」。
/// 服务端只拿它给 visits +1，不拿它识别人。
public struct UsageAnalyticsPayload: Hashable, Sendable, Encodable {
    public var platform: String
    public var appVersion: String
    public var newVisit: Bool
    public var screens: [ScreenCount]

    public struct ScreenCount: Hashable, Sendable, Encodable {
        public var id: String
        public var n: Int

        public init(id: String, n: Int) {
            self.id = id
            self.n = n
        }
    }

    public init(
        platform: String,
        appVersion: String,
        newVisit: Bool,
        screens: [ScreenCount]
    ) {
        self.platform = platform
        self.appVersion = String(appVersion.prefix(UsageFieldLimits.version))
        self.newVisit = newVisit
        self.screens = Array(screens.prefix(UsageFieldLimits.screens))
    }
}
