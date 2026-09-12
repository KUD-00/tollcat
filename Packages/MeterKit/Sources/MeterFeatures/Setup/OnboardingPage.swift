import Foundation
import MeterDesign

enum OnboardingPage: Int, CaseIterable, Identifiable, Hashable {
    case number
    case keychain
    case widget
    case add

    var id: Int { rawValue }

    var displayNumber: Int { rawValue + 1 }

    var isLast: Bool { self == .add }

    /// `-onboarding-page=` 的命名别名稳定；数字下标跟着页序走。
    static func fromLaunchArgument(_ raw: String?) -> OnboardingPage {
        switch raw {
        case "keychain", "1":
            return .keychain
        case "widget", "2":
            return .widget
        case "add", "3":
            return .add
        default:
            return .number
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .number: L("这个月花了多少")
        case .keychain: L("凭据不出这台设备")
        case .widget: L("不必打开也能看见")
        case .add: L("加上第一家服务")
        }
    }

    /// 第 3 页那句话按壳分岔：Mac 上没有主屏和锁屏，说「划过去」是句假话。
    /// **壳从参数进来，不写 `#if os`**——这是文案选择，不是 API 可用性，
    /// 编译期分岔会让另一边那句话根本不参与编译，也没法在一份预览里同时看两种。
    func body(shell: MeterShell) -> LocalizedStringResource {
        switch self {
        case .number:
            L("各家云和 AI 的账单收成一个数字。打开就能看见这个月已经花了多少。")
        case .keychain:
            L("API 密钥只进本机 Keychain，不进 iCloud，也不跟备份走。换手机用设置里的导入与导出。")
        case .widget:
            shell == .mac
                ? L("通知里不放金额，也没有金额告警。菜单栏和桌面小组件就能看见这个月的数字。")
                : L("通知里不放金额，也没有金额告警。把小组件放到主屏或锁屏，划过去就是这个月的数字。")
        case .add:
            L("先加进列表就行，不必现在就有 API 密钥。只订了 ChatGPT Pro 也可以先加进来。")
        }
    }

    var next: OnboardingPage? {
        OnboardingPage(rawValue: rawValue + 1)
    }
}
