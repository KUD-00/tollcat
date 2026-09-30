import Foundation
import MeterDesign

/// 页序按新用户心里冒出来的问题排：这是什么 → 数字从哪来 → 凭据放哪 → 从哪开始。
enum OnboardingPage: Int, CaseIterable, Identifiable, Hashable {
    case number
    case source
    case keychain
    case add

    var id: Int { rawValue }

    var displayNumber: Int { rawValue + 1 }

    var isLast: Bool { self == .add }

    /// `-onboarding-page=` 的命名别名稳定；数字下标跟着页序走。
    static func fromLaunchArgument(_ raw: String?) -> OnboardingPage {
        switch raw {
        case "source", "1":
            return .source
        case "keychain", "2":
            return .keychain
        case "add", "3":
            return .add
        default:
            return .number
        }
    }

    /// 第一页的标题就是品牌主句（BRAND.md 第零节），不另发明自我介绍。
    var title: LocalizedStringResource {
        switch self {
        case .number: L("把各家云账单，装进口袋")
        case .source: L("数字从哪来")
        case .keychain: L("凭据不出这台设备")
        case .add: L("加上第一家服务")
        }
    }

    var body: LocalizedStringResource {
        switch self {
        case .number:
            L("TollCat 把你在 AWS、Cloudflare、OpenAI 这些服务上的花费加在一起，告诉你这个月到现在花了多少，月底大概会到多少。")
        case .source:
            L("每家服务开一份只读凭据填进来。刷新时，这台设备直接向它的官方接口要账单，不经过 TollCat 的服务器，也不用注册账号。")
        case .keychain:
            L("API 密钥只进本机 Keychain，不进 iCloud，也不跟备份走。换手机用设置里的导入与导出。")
        case .add:
            L("先把在用的服务加进列表，凭据可以之后再填。只付月费的服务，比如 ChatGPT Pro，填上月费就算数。")
        }
    }

    var next: OnboardingPage? {
        OnboardingPage(rawValue: rawValue + 1)
    }
}
