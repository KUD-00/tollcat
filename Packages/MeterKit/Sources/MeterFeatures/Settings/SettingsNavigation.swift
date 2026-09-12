import Foundation

/// 设置 tab 里要落到哪。`root` 是列表第一屏（提醒、外观都在），不是某一页。
enum SettingsNavigation: Equatable {
    case root
    case route(SettingsRoute)

    /// `nil` / `reminders` = 列表第一屏。别的路径对得上就推进那一页，对不上也回第一屏。
    init(path: String?) {
        switch path {
        case nil, "reminders":
            self = .root
        case "inbox":
            self = .route(.inbox)
        case "import", "transfer":
            self = .route(.importExport)
        case "feedback":
            self = .route(.feedback)
        case "about":
            self = .route(.about)
        case "tip":
            self = .route(.tip)
        case "whats-new":
            self = .route(.whatsNew)
        default:
            self = .root
        }
    }
}
