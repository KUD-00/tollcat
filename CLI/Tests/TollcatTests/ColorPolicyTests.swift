import Testing
@testable import TollcatCore

struct ColorPolicyTests {
    @Test func noColorEnv() {
        let policy = ColorPolicy.resolve(
            noColorFlag: false,
            environment: ["NO_COLOR": "1"],
            stdoutIsTTY: true
        )
        #expect(!policy.enabled)
    }

    @Test func pipeDisables() {
        let policy = ColorPolicy.resolve(
            noColorFlag: false,
            environment: [:],
            stdoutIsTTY: false
        )
        #expect(!policy.enabled)
    }

    @Test func ttyEnables() {
        let policy = ColorPolicy.resolve(
            noColorFlag: false,
            environment: [:],
            stdoutIsTTY: true
        )
        #expect(policy.enabled)
        #expect(policy.wrap("x", ANSIColor.red).contains("\u{001B}"))
    }
}
