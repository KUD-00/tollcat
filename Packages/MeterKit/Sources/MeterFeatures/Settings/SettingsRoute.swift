import Foundation
import MeterUsage

enum SettingsRoute: Hashable {
    case usageGuides
    case whatsNew
    case tip
    case about
    case importExport
    case inbox
    case feedback

    var title: LocalizedStringResource {
        switch self {
        case .usageGuides: L("使用指南")
        case .whatsNew: L("更新说明")
        case .tip: L("请猫猫吃点东西")
        case .about: L("关于")
        case .importExport: L("导入与导出")
        case .inbox: L("读数信箱")
        case .feedback: L("反馈")
        }
    }

    var usageScreen: UsageAnalyticsScreen {
        switch self {
        case .usageGuides: .settingsUsageGuides
        case .whatsNew: .settingsWhatsNew
        case .tip: .settingsTip
        case .about: .settingsAbout
        case .importExport: .settingsImportExport
        case .inbox: .settingsInbox
        case .feedback: .settingsFeedback
        }
    }
}
