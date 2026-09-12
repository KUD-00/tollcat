import Foundation

/// 进入 App 时要不要自动刷一次。判断和取数拆开，好单独测。
enum UsageRefreshOnActivate {
    /// 自动刷新的保鲜期：这家上次成功还在这个窗口里，就不再为它打请求。
    ///
    /// **只管自动刷新**（亮屏，以及以后可能有的定时）。用户下拉刷新是明确说
    /// 「现在就给我最新的」，永远刷全部，一秒都不等——见 `DashboardModel.refresh()`。
    ///
    /// 没有这个窗口的时候，锁屏看一眼通知再解锁就是一整轮网络请求：实测 12 家接入
    /// 连续亮屏三次 = 36 次取数，而每一条回来都让正在看的详情页整页重算一遍。
    /// 账单数据没有比一刻钟更快的更新节奏，这个窗口不会让屏幕上任何数字变旧。
    static let freshness: TimeInterval = 15 * 60

    static func shouldRefresh(
        isEnabled: Bool,
        hasCompletedOnboarding: Bool,
        isAlreadyRefreshing: Bool,
        hasRefreshableProviders: Bool
    ) -> Bool {
        isEnabled && hasCompletedOnboarding && !isAlreadyRefreshing && hasRefreshableProviders
    }
}
