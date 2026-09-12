import Foundation
import MeterCore
import MeterPersistence

/// 把步骤正文拆成纯文字 / 加粗 / 链接。
///
/// 可点片段只是范围，地址由调用方传入——目录里没有 URL。
/// safari 符号不进 AttributedString：SwiftUI 的 `Text` 吃不下
/// `NSTextAttachment`，图标会丢。由 `SetupStepText` 用 `Image` 拼。
enum SetupStepMarkup {
    enum Piece: Equatable {
        case plain(String)
        case emphasis(String)
        case link(String)
    }

    static func pieces(_ step: SetupStep) -> [Piece] {
        let source = step.text
        var marks: [(Range<String.Index>, Piece)] = []
        for phrase in step.linkPhrases {
            if let range = source.range(of: phrase) {
                marks.append((range, .link(phrase)))
            }
        }
        for phrase in step.emphasized {
            guard let range = source.range(of: phrase) else { continue }
            if marks.contains(where: { $0.0.overlaps(range) }) { continue }
            marks.append((range, .emphasis(phrase)))
        }
        marks.sort { $0.0.lowerBound < $1.0.lowerBound }

        var result: [Piece] = []
        var cursor = source.startIndex
        for (range, piece) in marks {
            if cursor < range.lowerBound {
                result.append(.plain(String(source[cursor..<range.lowerBound])))
            }
            result.append(piece)
            cursor = range.upperBound
        }
        if cursor < source.endIndex {
            result.append(.plain(String(source[cursor...])))
        }
        return result
    }

    static func attributed(_ step: SetupStep, linkURL: URL?) -> AttributedString {
        var text = AttributedString(step.text)
        for phrase in step.emphasized {
            if let range = text.range(of: phrase) {
                text[range].inlinePresentationIntent = .stronglyEmphasized
            }
        }
        guard let linkURL else { return text }
        for phrase in step.linkPhrases {
            if let range = text.range(of: phrase) {
                text[range].link = linkURL
            }
        }
        return text
    }
}
