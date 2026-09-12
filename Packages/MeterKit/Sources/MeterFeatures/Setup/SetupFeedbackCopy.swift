import Foundation
import MeterFeedback

/// 连接向导里那节反馈的文案。预填不含金额、不含密钥。
enum SetupFeedbackCopy {
    static func category(for outcome: SetupVerifyOutcome) -> FeedbackCategory {
        switch outcome {
        case .success:
            return .other
        case .http, .network, .emptyReading, .unknown:
            return .bug
        }
    }

    static func draftMessage(providerName: String, outcome: SetupVerifyOutcome) -> String {
        switch outcome {
        case .success:
            return String(localized: L("\(providerName) 测通了，数字和后台对得上。"))
        case .http(let errorCase):
            let status = "HTTP \(errorCase.httpStatus)"
            return String(localized: L("\(providerName) 测试连接失败，\(status)。"))
        case .network:
            return String(localized: L("\(providerName) 测试连接失败，网络不可用。"))
        case .emptyReading:
            return String(localized: L("\(providerName) 连上了，但没有读到金额。"))
        case .unknown:
            return String(localized: L("\(providerName) 没能完成测试。"))
        }
    }

    static func lede(for outcome: SetupVerifyOutcome) -> LocalizedStringResource {
        switch outcome {
        case .success:
            return L("这家还没拿真实账单对过。数字对的话，告诉我一声。")
        case .http, .network, .emptyReading, .unknown:
            return L("按说明做了还是不行的话，告诉我发生了什么。")
        }
    }
}
