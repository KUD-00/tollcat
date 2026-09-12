import Foundation
import MeterCore

/// 猫气泡首选句的**分岔**，单源在这里；渲染留给两端——
/// iOS 在 `CatSpeechFallback` 用 Features 的 xcstrings（并补第二候选），
/// Android 在 `ProductSpeech` 用 `JNICopy`。改分岔改这里，两端一起变。
public enum CatSpeechPrimaryLine: Equatable, Sendable {
    case sleepingUnread
    case sleepingNone
    case dead
    case shockedPercent(Int)
    case shockedSteep
    case alertBalance(name: String)
    case alertAnomaly(name: String, percent: Int)
    case alertGeneric
    case awkward
    /// `saved` 是省下的幅度，正数（changePercent 的相反数）。
    case savedPercent(saved: Int)
    case savedFree
    case normalClosed(total: String)
    case normalProjection(total: String, projected: String)

    public struct Facts: Sendable {
        public var mood: CatMood
        public var hasAnyProvider: Bool
        public var totalText: String
        public var projectedText: String
        public var allowsProjection: Bool
        public var changePercent: Int?
        public var leadAnomalyName: String?
        public var leadAnomalyPercent: Int?
        public var leadBalanceName: String?

        public init(
            mood: CatMood,
            hasAnyProvider: Bool,
            totalText: String,
            projectedText: String,
            allowsProjection: Bool,
            changePercent: Int?,
            leadAnomalyName: String?,
            leadAnomalyPercent: Int?,
            leadBalanceName: String?
        ) {
            self.mood = mood
            self.hasAnyProvider = hasAnyProvider
            self.totalText = totalText
            self.projectedText = projectedText
            self.allowsProjection = allowsProjection
            self.changePercent = changePercent
            self.leadAnomalyName = leadAnomalyName
            self.leadAnomalyPercent = leadAnomalyPercent
            self.leadBalanceName = leadBalanceName
        }
    }

    public static func resolve(_ facts: Facts) -> CatSpeechPrimaryLine {
        switch facts.mood {
        case .sleeping:
            return facts.hasAnyProvider ? .sleepingUnread : .sleepingNone
        case .dead:
            return .dead
        case .shocked:
            if let percent = facts.changePercent {
                return .shockedPercent(percent)
            }
            return .shockedSteep
        case .alert:
            if let name = facts.leadBalanceName {
                return .alertBalance(name: name)
            }
            if let name = facts.leadAnomalyName, let percent = facts.leadAnomalyPercent {
                return .alertAnomaly(name: name, percent: percent)
            }
            return .alertGeneric
        case .awkward:
            return .awkward
        case .saved:
            if let percent = facts.changePercent, percent < 0 {
                return .savedPercent(saved: -percent)
            }
            return .savedFree
        case .normal:
            guard facts.allowsProjection else {
                return .normalClosed(total: facts.totalText)
            }
            return .normalProjection(total: facts.totalText, projected: facts.projectedText)
        }
    }
}
