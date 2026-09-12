// GENERATED — 由 scripts/generate-shared.py 从 shared/ui-test-ids.json 生成。
// 不要手改：改 shared/ui-test-ids.json 后重跑生成器。


import Foundation

/// UI 冒烟测试（maestro/）的锚点。挂 `.accessibilityIdentifier`，不随语言变。
/// 只有冒烟流程要点到 / 要断言的控件才有 id；不要拿它当样式或逻辑开关。
///
/// 住在 MeterDesign：模块视图（MeterModules）和页面（MeterFeatures）都要挂，
/// 放在两边都够得着的最底层，不是因为它跟设计系统有关。
public enum UITestID {
    /// 底部 tab：仪表盘
    public static let tabDashboard = "tab.dashboard"
    /// 底部 tab：服务
    public static let tabServices = "tab.services"
    /// 底部 tab：设置
    public static let tabSettings = "tab.settings"
    /// 开场引导右上角「跳过」
    public static let onboardingSkip = "onboarding.skip"
    /// 开场引导主按钮（继续 / 添加第一个服务）
    public static let onboardingNext = "onboarding.next"
    /// 仪表盘空态整块
    public static let dashboardEmpty = "dashboard.empty"
    /// 本月合计那一个大数字
    public static let dashboardTotal = "dashboard.total"
    /// 服务空态整块
    public static let servicesEmpty = "services.empty"
    /// 服务空态「添加服务」
    public static let servicesEmptyAdd = "services.empty.add"
    /// 服务列表里的「添加服务」行 / FAB
    public static let servicesAdd = "services.add"
    /// 添加服务的目录列表
    public static let addProviderList = "addProvider.list"
    /// 添加确认面板的主按钮
    public static let addProviderConfirm = "addProvider.confirm"
    /// 接入向导：连接参考步
    public static let setupGuide = "setup.guide"
    /// 接入向导主按钮（下一步 / 我拿到凭据了）
    public static let setupNext = "setup.next"
    /// 接入向导：填凭据步
    public static let setupCredentials = "setup.credentials"
    /// 服务详情页
    public static let providerDetailList = "providerDetail.list"
    /// 详情页里的「连接 X 账单」行，两端都从这里进向导
    public static let providerDetailConnect = "providerDetail.connect"
    /// 设置列表
    public static let settingsList = "settings.list"
    /// 设置里的「打开猫猫」开关
    public static let settingsHideCat = "settings.hideCat"
    /// 服务列表里某一家的行，后接 provider key（services.row.cloudflare）
    public static func servicesRow(_ key: String) -> String {
        "services.row." + key
    }
    /// 添加目录里某一家的行，后接 provider key（addProvider.row.cloudflare）
    public static func addProviderRow(_ key: String) -> String {
        "addProvider.row." + key
    }
}
