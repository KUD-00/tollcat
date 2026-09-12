import Foundation
import Observation
import MeterFeedback
import MeterProviders

/// 反馈页的状态。
///
/// 提交成功之后**不留副本**：这个 App 没有账号，没有回信通道，
/// 留一份本地历史只会让人以为能追踪进度。失败才留在输入框里，让人能重试。
@MainActor
@Observable
final class FeedbackModel {
    enum Outcome: Hashable {
        case sent
        case rateLimited
        case failed
    }

    var category: FeedbackCategory = .default
    var message = ""
    var contact = ""
    /// 默认关。带上它是把「我用了哪几家」交出去，得让用户自己按。
    var includesProviderList = false
    /// 默认关。带上测试连接那次 HTTP 摘要。正文由调用方打码后再传入。
    var includesExchange = false

    private(set) var isSubmitting = false
    private(set) var outcome: Outcome?

    let environment: FeedbackEnvironmentInfo

    private let submitter: any FeedbackSubmitting
    private let connectedProviderNames: @MainActor () -> [String]
    private let makeID: () -> String

    init(
        submitter: any FeedbackSubmitting,
        environment: FeedbackEnvironmentInfo = .current(),
        connectedProviderNames: @MainActor @escaping () -> [String],
        makeID: @escaping () -> String = { UUID().uuidString }
    ) {
        self.submitter = submitter
        self.environment = environment
        self.connectedProviderNames = connectedProviderNames
        self.makeID = makeID
    }

    /// 连接向导那一节：钉死这一家，正文预填，没有「附带名单」开关。
    static func setupReport(
        providerName: String,
        outcome: SetupVerifyOutcome,
        submitter: (any FeedbackSubmitting)? = nil,
        environment: FeedbackEnvironmentInfo = .current(),
        makeID: @escaping () -> String = { UUID().uuidString }
    ) -> FeedbackModel {
        let model = FeedbackModel(
            submitter: submitter
                ?? (FeatureLaunchArguments.stubFeedback
                    ? StubFeedbackSubmitter()
                    : LiveFeedback.submitter()),
            environment: environment,
            connectedProviderNames: { [providerName] },
            makeID: makeID
        )
        model.category = SetupFeedbackCopy.category(for: outcome)
        model.message = SetupFeedbackCopy.draftMessage(
            providerName: providerName,
            outcome: outcome
        )
        model.includesProviderList = true
        return model
    }

    var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedMessage.isEmpty && !isSubmitting
    }

    /// 还能再写多少字。只在接近上限时展示，平时不要拿字数计数器分散注意力。
    var remainingCharacters: Int {
        FeedbackFieldLimits.message - message.count
    }

    var showsRemainingCharacters: Bool {
        remainingCharacters <= 200
    }

    /// 界面上那一行「会一起发过去」的清单，逐项可读。
    var attachedProviderNames: [String] {
        includesProviderList ? connectedProviderNames() : []
    }

    func submit(exchange: String? = nil) async {
        guard canSubmit else { return }
        isSubmitting = true
        outcome = nil
        defer { isSubmitting = false }

        let payload = FeedbackPayload(
            id: makeID(),
            category: category,
            message: trimmedMessage,
            contact: contact,
            appVersion: environment.appVersion,
            osVersion: environment.osVersion,
            locale: environment.locale,
            deviceModel: environment.deviceModel,
            providers: includesProviderList ? connectedProviderNames() : nil,
            exchange: includesExchange ? exchange : nil
        )

        do {
            try await submitter.submit(payload)
            outcome = .sent
            message = ""
            contact = ""
        } catch let error as FeedbackError where error.isRateLimited {
            outcome = .rateLimited
        } catch {
            outcome = .failed
        }
    }
}

extension FeedbackModel {
    /// 从仪表模型上取「已接入哪几家」的显示名。只要名字，不碰金额。
    static func connectedNames(dashboard: DashboardModel) -> @MainActor () -> [String] {
        { [weak dashboard] in
            guard let dashboard else { return [] }
            return dashboard.connectionStates()
                .filter(\.isLive)
                .map { state in
                    ProviderCatalog.descriptor(id: state.providerID)?.displayName
                        ?? state.providerID.rawValue
                }
                .sorted()
        }
    }
}
