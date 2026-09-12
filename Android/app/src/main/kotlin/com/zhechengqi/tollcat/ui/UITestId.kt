// GENERATED — 由 scripts/generate-shared.py 从 shared/ui-test-ids.json 生成。
// 不要手改：改 shared/ui-test-ids.json 后重跑生成器。


package com.zhechengqi.tollcat.ui

/**
 * UI 冒烟测试（maestro/）的锚点。挂 `Modifier.testTag`，根上开了 testTagsAsResourceId，
 * Maestro 按 resource-id 找。不随语言变。只有冒烟流程要点到 / 要断言的控件才有 id。
 */
object UITestId {
    /** 底部 tab：仪表盘 */
    const val TAB_DASHBOARD = "tab.dashboard"
    /** 底部 tab：服务 */
    const val TAB_SERVICES = "tab.services"
    /** 底部 tab：设置 */
    const val TAB_SETTINGS = "tab.settings"
    /** 开场引导右上角「跳过」 */
    const val ONBOARDING_SKIP = "onboarding.skip"
    /** 开场引导主按钮（继续 / 添加第一个服务） */
    const val ONBOARDING_NEXT = "onboarding.next"
    /** 仪表盘空态整块 */
    const val DASHBOARD_EMPTY = "dashboard.empty"
    /** 本月合计那一个大数字 */
    const val DASHBOARD_TOTAL = "dashboard.total"
    /** 服务空态整块 */
    const val SERVICES_EMPTY = "services.empty"
    /** 服务空态「添加服务」 */
    const val SERVICES_EMPTY_ADD = "services.empty.add"
    /** 服务列表里的「添加服务」行 / FAB */
    const val SERVICES_ADD = "services.add"
    /** 添加服务的目录列表 */
    const val ADD_PROVIDER_LIST = "addProvider.list"
    /** 添加确认面板的主按钮 */
    const val ADD_PROVIDER_CONFIRM = "addProvider.confirm"
    /** 接入向导：连接参考步 */
    const val SETUP_GUIDE = "setup.guide"
    /** 接入向导主按钮（下一步 / 我拿到凭据了） */
    const val SETUP_NEXT = "setup.next"
    /** 接入向导：填凭据步 */
    const val SETUP_CREDENTIALS = "setup.credentials"
    /** 服务详情页 */
    const val PROVIDER_DETAIL_LIST = "providerDetail.list"
    /** 详情页里的「连接 X 账单」行，两端都从这里进向导 */
    const val PROVIDER_DETAIL_CONNECT = "providerDetail.connect"
    /** 设置列表 */
    const val SETTINGS_LIST = "settings.list"
    /** 设置里的「打开猫猫」开关 */
    const val SETTINGS_HIDE_CAT = "settings.hideCat"
    /** 服务列表里某一家的行，后接 provider key（services.row.cloudflare） */
    fun servicesRow(key: String): String = "services.row.$key"
    /** 添加目录里某一家的行，后接 provider key（addProvider.row.cloudflare） */
    fun addProviderRow(key: String): String = "addProvider.row.$key"
}
