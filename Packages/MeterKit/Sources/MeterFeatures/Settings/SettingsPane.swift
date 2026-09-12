/// 横屏 iPad 设置页侧栏的选中项。手机栈仍然只认 `SettingsRoute`。
enum SettingsPane: Hashable {
    case route(SettingsRoute)
    case developer
}
