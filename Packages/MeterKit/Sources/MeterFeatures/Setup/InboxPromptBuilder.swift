import Foundation
import MeterCore
import MeterInbox
import MeterProviders

/// 给用户复制走喂给 LLM 的那段话。
///
/// **它不是一条 curl，是一份任务书。** 用户不会手写抓取脚本，他会把活儿丢给
/// Claude Code / Cursor / browser-use。所以这里要自带全部上下文：取什么数、
/// 投到哪、字段什么含义、什么节奏、以及什么绝对不能做。
///
/// **prompt 里没有密钥。** 投递 key 用 `$TOLL_INGEST_KEY` 引用，用户自己放进
/// 环境变量。这样这段话粘到哪个云端 LLM 都无所谓——真正的密钥从没离开过他的机器。
///
/// 拆成一行一条而不是一整段模板：散文要翻译，中间那段 HTTP 不能翻译，
/// 而且一整段带五个插值的模板在 String Catalog 里是位置化占位符，手写必错。
enum InboxPromptBuilder: Sendable {
    static func prompt(
        providerID: ProviderID,
        displayName: String,
        now: Date,
        calendar: Calendar
    ) -> String {
        [
            String(localized: L("帮我做一个每天自动上报 \(displayName) 花费的脚本。")),
            "",
            String(localized: L("第一步，取账单：登录 \(displayName)，读出「本月至今」的总花费，单位美元。")),
            String(localized: L("这家没有公开的账单 API，你需要自己想办法——浏览器自动化、解析账单邮件都行。")),
            "",
            String(localized: L("第二步，上报：把这个数字 POST 到下面这个地址。")),
            "",
            requestBlock(providerID: providerID, now: now, calendar: calendar),
            "",
            String(localized: L("规则：")),
            String(localized: L("- currentSpendUSD 是本月至今累计，不是当天花了多少")),
            String(localized: L("- 金额必须是字符串，不要发 JSON number，分位不能丢")),
            String(localized: L("- periodStart 永远是当月 1 号，跨月要自动跟着变")),
            String(localized: L("- 同一个月重复投递是覆盖，不会重复计账，失败重试是安全的")),
            String(localized: L("- 每天跑一次就够")),
            "",
            String(localized: L("$TOLL_INGEST_KEY 是我自己配置的环境变量，你不需要知道它的值，也不要把它写死在代码里。")),
            String(localized: L("除了上面这个地址，不要把我的任何账号信息或凭据发到别处。")),
        ].joined(separator: "\n")
    }

    /// HTTP 那一段不进翻译：它是给机器看的合同，翻译等于改协议。
    /// 地址来自编译进 App 的 `InboxEndpoint`，不许从别处拼。
    static func requestBlock(
        providerID: ProviderID,
        now: Date,
        calendar: Calendar
    ) -> String {
        let body = #"{"provider":"\#(providerID.rawValue)","#
            + #""periodStart":"\#(monthStartString(now: now, calendar: calendar))","#
            + #""currentSpendUSD":"12.34"}"#
        return """
          POST \(InboxEndpoint.readingsURL.absoluteString)
          Authorization: Bearer $TOLL_INGEST_KEY
          content-type: application/json

          \(body)
        """
    }

    /// 周期起点跟着「现在」走，跨月复制出来的 prompt 不会还写着上个月。
    static func monthStartString(now: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: now)
        return String(format: "%04d-%02d-01", parts.year ?? 0, parts.month ?? 0)
    }
}
