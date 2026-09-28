import Foundation
import MeterBridge

package enum CLIRuntime {
    package static func main() -> Int32 {
        var stdout = FileHandleStream(handle: .standardOutput)
        var stderr = FileHandleStream(handle: .standardError)
        return run(
            arguments: Array(CommandLine.arguments.dropFirst()),
            environment: ProcessInfo.processInfo.environment,
            now: Date(),
            paths: AppPaths.resolve(
                environment: ProcessInfo.processInfo.environment,
                home: nil
            ),
            vault: VaultFactory.make(),
            prompt: StandardPrompt(),
            stdoutIsTTY: StandardStream.stdoutIsTTY(),
            stdout: &stdout,
            stderr: &stderr
        )
    }

    static func run<Out: TextOutputStream, Err: TextOutputStream>(
        arguments: [String],
        environment: [String: String],
        now: Date,
        paths: AppPaths,
        vault: any CredentialVault,
        prompt: any PromptIO,
        stdoutIsTTY: Bool,
        stdout: inout Out,
        stderr: inout Err
    ) -> Int32 {
        let invocation: Invocation
        do {
            invocation = try ArgumentParser.parse(arguments)
        } catch let error as ParseError {
            let locale = LocaleTag.resolve(explicit: nil, environment: environment)
            stderr.write(parseMessage(error, localeTag: locale) + "\n")
            stderr.write(JNICopy.text("用法：", locale) + "\n")
            stderr.write(JNICopy.text(usageKey, locale) + "\n")
            return ExitCode.usage
        } catch {
            return ExitCode.usage
        }

        let localeTag = LocaleTag.resolve(explicit: invocation.locale, environment: environment)
        if invocation.help {
            stdout.write(JNICopy.text(usageKey, localeTag) + "\n")
            return ExitCode.ok
        }
        if invocation.version {
            stdout.write(CLIIdentity.line(environment: environment) + "\n")
            return ExitCode.ok
        }

        let color = ColorPolicy.resolve(
            noColorFlag: invocation.noColor || invocation.json || invocation.oneline,
            environment: environment,
            stdoutIsTTY: stdoutIsTTY
        )
        let minutes = invocation.maxAgeMinutes ?? RefreshPolicy.defaultMaxAgeMinutes
        let session = CLISession(
            ledger: JsonLedgerStore(path: paths.ledgerFile),
            vault: vault,
            environment: environment,
            localeTag: localeTag,
            maxAge: TimeInterval(minutes * 60),
            now: now,
            currency: environment["TOLLCAT_CURRENCY"] ?? "USD"
        )

        switch invocation.verb {
        case .providers:
            return runProviders(session: session, json: invocation.json, stdout: &stdout)
        case .add:
            return runAdd(
                session: session,
                positional: invocation.positional,
                prompt: prompt,
                localeTag: localeTag,
                stdout: &stdout,
                stderr: &stderr
            )
        case .remove:
            return runRemove(
                session: session,
                positional: invocation.positional,
                localeTag: localeTag,
                stdout: &stdout,
                stderr: &stderr
            )
        case .refresh:
            let tally = session.refresh(force: true)
            return finishDashboard(
                session: session,
                invocation: invocation,
                color: color,
                localeTag: localeTag,
                tally: tally,
                stdout: &stdout,
                stderr: &stderr
            )
        case nil:
            let tally = session.refresh(force: minutes == 0)
            return finishDashboard(
                session: session,
                invocation: invocation,
                color: color,
                localeTag: localeTag,
                tally: tally,
                stdout: &stdout,
                stderr: &stderr
            )
        }
    }

    private static let usageKey = """
    用法:
      tollcat                 本月合计
      tollcat --oneline       一行，给状态栏
      tollcat --json          机器可读
      tollcat add <服务>      写入凭据
      tollcat remove <服务>   移除
      tollcat refresh         强制拉新
      tollcat providers       支持的服务
      tollcat --version

    旗标:
      --no-color              关闭颜色（也认 NO_COLOR）
      --locale <tag>          覆盖 LANG
      --max-age <分钟>        账本缓存时长，默认 30，0 表示总是拉新
    """

    private static func runProviders<Out: TextOutputStream>(
        session: CLISession,
        json: Bool,
        stdout: inout Out
    ) -> Int32 {
        if json {
            stdout.write(ProductCatalog.json(localeTag: session.localeTag) + "\n")
            return ExitCode.ok
        }
        stdout.write(ProvidersRenderer.render(session.catalog()) + "\n")
        return ExitCode.ok
    }

    private static func runAdd<Out: TextOutputStream, Err: TextOutputStream>(
        session: CLISession,
        positional: [String],
        prompt: any PromptIO,
        localeTag: String,
        stdout: inout Out,
        stderr: inout Err
    ) -> Int32 {
        guard let query = positional.first, positional.count == 1 else {
            stderr.write(JNICopy.text("用法：", localeTag) + "\n")
            stderr.write(JNICopy.text(usageKey, localeTag) + "\n")
            return ExitCode.usage
        }
        switch session.add(query: query, prompt: prompt) {
        case .success(let provider):
            if !provider.credentialSetupURL.isEmpty {
                stderr.write(JNICopy.format("教程：%@", localeTag, provider.credentialSetupURL) + "\n")
            }
            if provider.costsMoneyToRefresh {
                stderr.write(JNICopy.text("要花钱取数，默认刷新会跳过。接入测试仍会打一次。", localeTag) + "\n")
            }
            stdout.write(JNICopy.format("已接入 %@。", localeTag, provider.displayName) + "\n")
            return ExitCode.ok
        case .failure(let error):
            stderr.write(addMessage(error, localeTag: localeTag) + "\n")
            return error.isUsage ? ExitCode.usage : ExitCode.fetchFailed
        }
    }

    private static func runRemove<Out: TextOutputStream, Err: TextOutputStream>(
        session: CLISession,
        positional: [String],
        localeTag: String,
        stdout: inout Out,
        stderr: inout Err
    ) -> Int32 {
        guard let query = positional.first, positional.count == 1 else {
            stderr.write(JNICopy.text(usageKey, localeTag) + "\n")
            return ExitCode.usage
        }
        switch session.remove(query: query) {
        case .success(let provider):
            stdout.write(JNICopy.format("已移除 %@。", localeTag, provider.displayName) + "\n")
            return ExitCode.ok
        case .failure(let error):
            stderr.write(addMessage(error, localeTag: localeTag) + "\n")
            return error.isUsage ? ExitCode.usage : ExitCode.fetchFailed
        }
    }

    private static func finishDashboard<Out: TextOutputStream, Err: TextOutputStream>(
        session: CLISession,
        invocation: Invocation,
        color: ColorPolicy,
        localeTag: String,
        tally: RefreshTally,
        stdout: inout Out,
        stderr: inout Err
    ) -> Int32 {
        let document = session.dashboard()
        if invocation.json {
            stdout.write(document.rawJSON + "\n")
        } else if invocation.oneline {
            stdout.write(OnelineRenderer.render(document, localeTag: localeTag) + "\n")
        } else {
            stdout.write(DashboardRenderer.render(document, localeTag: localeTag, color: color) + "\n")
        }
        if tally.fail > 0 {
            stderr.write(JNICopy.text("部分刷新失败。", localeTag) + "\n")
            return ExitCode.fetchFailed
        }
        return ExitCode.ok
    }

    private static func parseMessage(_ error: ParseError, localeTag: String) -> String {
        switch error {
        case .unknownFlag(let flag):
            return JNICopy.format("未知旗标：%@", localeTag, flag)
        case .unknownCommand(let command):
            return JNICopy.format("未知命令：%@", localeTag, command)
        case .missingValue(let flag):
            return JNICopy.format("未知旗标：%@", localeTag, flag)
        case .invalidMaxAge(let value):
            return JNICopy.format("未知旗标：%@", localeTag, value)
        case .conflictingOutput:
            return JNICopy.text("用法错误。", localeTag)
        }
    }

    private static func addMessage(_ error: AddError, localeTag: String) -> String {
        switch error {
        case .unknownService(let query):
            return JNICopy.format("未知服务：%@", localeTag, query)
        case .declined:
            return JNICopy.text("这家服务不接入。", localeTag)
        case .noLiveFetch:
            return JNICopy.text("CLI 读不了这家：没有公开的账单接口。", localeTag)
        case .needEnvironment:
            return JNICopy.text("非交互环境请设置环境变量 TOLLCAT_<服务>_<字段>。", localeTag)
        case .missingField(let key):
            return JNICopy.format("缺必填字段：%@", localeTag, key)
        case .fetchFailed(let message):
            return JNICopy.format("取数失败：%@", localeTag, message)
        case .notConnected(let provider):
            return JNICopy.format("没有接入 %@。", localeTag, provider.displayName)
        case .credentialDeleteFailed(let provider):
            return JNICopy.format("%@ 的凭据没能从钥匙环删除，已保留接入。", localeTag, provider.displayName)
        }
    }
}

private extension AddError {
    var isUsage: Bool {
        switch self {
        case .unknownService, .declined, .noLiveFetch, .needEnvironment, .missingField, .notConnected:
            return true
        case .fetchFailed, .credentialDeleteFailed:
            return false
        }
    }
}
