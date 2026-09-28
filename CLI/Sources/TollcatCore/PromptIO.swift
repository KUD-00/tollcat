import Foundation

protocol PromptIO: Sendable {
    var isInteractive: Bool { get }
    func writePrompt(_ text: String)
    func readLine(secret: Bool) -> String?
}

struct StandardPrompt: PromptIO {
    var isInteractive: Bool { StandardStream.stdinIsTTY() }

    func writePrompt(_ text: String) {
        FileHandle.standardError.write(Data(text.utf8))
    }

    func readLine(secret: Bool) -> String? {
        if secret, isInteractive {
            return SecretLine.read()
        }
        return Swift.readLine()
    }
}

struct ScriptedPrompt: PromptIO {
    var isInteractive: Bool
    var answers: [String]
    private let lock = LockBox()

    init(answers: [String], isInteractive: Bool = false) {
        self.answers = answers
        self.isInteractive = isInteractive
    }

    func writePrompt(_ text: String) {
        _ = text
    }

    func readLine(secret: Bool) -> String? {
        _ = secret
        return lock.next(from: answers)
    }
}

private final class LockBox: @unchecked Sendable {
    private let lock = NSLock()
    private var index = 0

    func next(from answers: [String]) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard index < answers.count else { return nil }
        let value = answers[index]
        index += 1
        return value
    }
}
