import Foundation
import Testing
import MeterCore
import MeterInbox
@testable import MeterFeatures

struct InboxPromptBuilderTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func now(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func prompt(now date: Date) -> String {
        InboxPromptBuilder.prompt(
            providerID: .render,
            displayName: "Render",
            now: date,
            calendar: calendar
        )
    }

    @Test("任务书里没有任何密钥——它要能放心粘给云端 LLM")
    func promptCarriesNoSecret() {
        let text = prompt(now: now(2026, 8, 17))
        #expect(!text.contains("tolli_"))
        #expect(!text.contains("tollr_"))
        // 引用环境变量，不是把值写进去。
        #expect(text.contains("$TOLL_INGEST_KEY"))
    }

    @Test("投递地址来自编译进 App 的常量，不是拼出来的字符串")
    func promptUsesCompiledEndpoint() {
        let text = prompt(now: now(2026, 8, 17))
        #expect(text.contains(InboxEndpoint.readingsURL.absoluteString))
    }

    @Test("provider id 用的是取数侧那个 raw value，不是展示名")
    func promptUsesRawProviderID() {
        let text = prompt(now: now(2026, 8, 17))
        #expect(text.contains("\"provider\":\"render\""))
    }

    @Test("周期起点跟着当前月走，跨月复制出来的不会还写着上个月")
    func periodStartFollowsCurrentMonth() {
        #expect(prompt(now: now(2026, 8, 17)).contains("2026-08-01"))
        #expect(prompt(now: now(2026, 9, 1)).contains("2026-09-01"))
        #expect(prompt(now: now(2026, 12, 31)).contains("2026-12-01"))
        #expect(InboxPromptBuilder.monthStartString(now: now(2027, 1, 5), calendar: calendar) == "2027-01-01")
    }

    @Test("把三条最容易搞错的语义写进去了")
    func promptStatesTheTrickySemantics() {
        let text = prompt(now: now(2026, 8, 17))
        // 月累计不是当天，金额是字符串，重复投递是覆盖。
        #expect(text.contains("本月至今累计"))
        #expect(text.contains("字符串"))
        #expect(text.contains("覆盖"))
    }
}
