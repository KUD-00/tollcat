import Foundation
import Testing
@testable import TollcatCore

struct CLIRuntimeTests {
    @Test func version() {
        var stdout = ""
        var stderr = ""
        let code = CLIRuntime.run(
            arguments: ["--version"],
            environment: ["TOLLCAT_COMMIT": "deadbeef"],
            now: Date(timeIntervalSince1970: 0),
            paths: tempPaths(),
            vault: MemoryVault(),
            prompt: ScriptedPrompt(answers: []),
            stdoutIsTTY: false,
            stdout: &stdout,
            stderr: &stderr
        )
        #expect(code == ExitCode.ok)
        #expect(stdout.contains("tollcat \(CLIVersion.marketing)"))
        #expect(stdout.contains("deadbeef"))
        #expect(stderr.isEmpty)
    }

    @Test func help() {
        var stdout = ""
        var stderr = ""
        let code = CLIRuntime.run(
            arguments: ["--help"],
            environment: ["LANG": "en_US.UTF-8"],
            now: Date(timeIntervalSince1970: 0),
            paths: tempPaths(),
            vault: MemoryVault(),
            prompt: ScriptedPrompt(answers: []),
            stdoutIsTTY: false,
            stdout: &stdout,
            stderr: &stderr
        )
        #expect(code == ExitCode.ok)
        #expect(stdout.lowercased().contains("usage"))
    }

    @Test func unknownFlagIsUsage() {
        var stdout = ""
        var stderr = ""
        let code = CLIRuntime.run(
            arguments: ["--nope"],
            environment: ["LANG": "en_US.UTF-8"],
            now: Date(timeIntervalSince1970: 0),
            paths: tempPaths(),
            vault: MemoryVault(),
            prompt: ScriptedPrompt(answers: []),
            stdoutIsTTY: false,
            stdout: &stdout,
            stderr: &stderr
        )
        #expect(code == ExitCode.usage)
        #expect(stderr.contains("Unknown flag") || stderr.contains("未知旗标"))
    }

    @Test func emptyDashboardJSONHasNoCredentials() {
        ResourceBootstrap.install()
        var stdout = ""
        var stderr = ""
        let code = CLIRuntime.run(
            arguments: ["--json"],
            environment: ["LANG": "en_US.UTF-8", "NO_COLOR": "1"],
            now: Date(timeIntervalSince1970: 1_700_000_000),
            paths: tempPaths(),
            vault: MemoryVault(),
            prompt: ScriptedPrompt(answers: []),
            stdoutIsTTY: false,
            stdout: &stdout,
            stderr: &stderr
        )
        #expect(code == ExitCode.ok)
        #expect(stdout.contains("\"empty\""))
        let lowered = stdout.lowercased()
        for banned in ["apikey", "apitoken", "secretaccesskey", "credential"] {
            #expect(!lowered.contains(banned))
        }
    }

    @Test func providersListsOffered() {
        ResourceBootstrap.install()
        var stdout = ""
        var stderr = ""
        let code = CLIRuntime.run(
            arguments: ["providers", "--locale", "en"],
            environment: [:],
            now: Date(timeIntervalSince1970: 0),
            paths: tempPaths(),
            vault: MemoryVault(),
            prompt: ScriptedPrompt(answers: []),
            stdoutIsTTY: false,
            stdout: &stdout,
            stderr: &stderr
        )
        #expect(code == ExitCode.ok)
        #expect(stdout.contains("openai") || stdout.contains("OpenAI"))
        #expect(!stdout.lowercased().contains("apikey"))
    }

    private func tempPaths() -> AppPaths {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tollcat-runtime-\(UUID().uuidString)")
            .appendingPathComponent("ledger.json")
        return AppPaths(ledgerFile: url)
    }
}
