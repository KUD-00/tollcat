import Foundation

/// 候选句的稳定身份。屏幕上出现的字只能来自候选表，不能是别处拼的。
struct CatSpeechCandidateID: RawRepresentable, Hashable, Sendable, Equatable {
    var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
