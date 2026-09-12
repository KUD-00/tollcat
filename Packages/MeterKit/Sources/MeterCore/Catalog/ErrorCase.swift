import Foundation

/// HTTP 状态 → 人话 + 下一步。401 和 403 不能合成「连接失败」。
public struct ErrorCase: Hashable, Sendable, Codable {
    public struct LocalizedCopy: Hashable, Sendable, Codable {
        public var explanation: String?
        public var nextStep: String?

        public init(explanation: String? = nil, nextStep: String? = nil) {
            self.explanation = explanation
            self.nextStep = nextStep
        }
    }

    public var httpStatus: Int
    public var explanation: String
    public var nextStep: String
    public var en: LocalizedCopy?
    public var ja: LocalizedCopy?

    public init(
        httpStatus: Int,
        explanation: String,
        nextStep: String,
        en: LocalizedCopy? = nil,
        ja: LocalizedCopy? = nil
    ) {
        self.httpStatus = httpStatus
        self.explanation = explanation
        self.nextStep = nextStep
        self.en = en
        self.ja = ja
    }

    public func localized(for language: CatalogLanguage) -> ErrorCase {
        let copy = language.pick(en: en, ja: ja)
        return ErrorCase(
            httpStatus: httpStatus,
            explanation: catalogOverlay(copy?.explanation, fallback: explanation),
            nextStep: catalogOverlay(copy?.nextStep, fallback: nextStep)
        )
    }
}
