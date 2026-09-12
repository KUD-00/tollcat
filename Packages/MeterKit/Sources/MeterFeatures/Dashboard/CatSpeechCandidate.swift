import Foundation

/// 已经写死、已经填好数字的完整句子。屏幕上只能出现这里的 `text`。
struct CatSpeechCandidate: Identifiable, Sendable, Equatable {
    var id: CatSpeechCandidateID
    var text: String
}
