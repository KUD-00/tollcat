import Foundation
import Testing
import MeterProviders
@testable import MeterFeatures

/// 出站 HTTP 摘要的金额打码。Worker 不许收到账单数字，用户打开开关也不等于授权。
struct SetupFeedbackExchangeTests {
    @Test("bill / total / credits / due / owing / tariff 这些别名都算金额键")
    func billingAliasesAreRedacted() {
        let redacted = SetupFeedbackExchange.redactMoney(in: """
        {"current_bill": 142.5, "total": 143.5, "credits": 10, "lastBill": 99.25,
         "due": 7, "owing": 8, "tariff": 0.3, "debit": 4, "plan": "pro"}
        """)
        for figure in ["142.5", "143.5", "99.25", "0.3"] {
            #expect(!redacted.contains(figure))
        }
        // 八个金额键各换成一个 `"***"`；不依赖 pretty 输出冒号两边的空白。
        #expect(redacted.components(separatedBy: #""***""#).count - 1 == 8)
        #expect(redacted.contains("pro"))
    }

    @Test("计数和时间不误伤：total_tokens、totalCount、due_date 原样留下")
    func countsAndDatesSurvive() {
        let redacted = SetupFeedbackExchange.redactMoney(
            in: #"{"total_tokens": 12, "totalCount": 3, "due_date": "2026-09-01", "creditorName": "acme"}"#
        )
        #expect(!redacted.contains("***"))
        #expect(redacted.contains("12"))
        #expect(redacted.contains("2026-09-01"))
        #expect(redacted.contains("acme"))
    }

    @Test("键名无害的字符串值里带的金额也打掉")
    func moneyInsideStringValuesIsRedacted() {
        let redacted = SetupFeedbackExchange.redactMoney(
            in: #"{"message": "Insufficient balance: $3.20 remaining"}"#
        )
        #expect(!redacted.contains("3.20"))
        #expect(redacted.contains("Insufficient"))
    }

    @Test("解析不了的正文不再原样放行：表单、XML、纯文本里的金额都打掉")
    func nonJSONBodiesDoNotFailOpen() {
        let form = SetupFeedbackExchange.redactMoney(in: "current_bill=142&total=142&page=3")
        #expect(form == "current_bill=***&total=***&page=3")

        let xml = SetupFeedbackExchange.redactMoney(
            in: "<invoice><total>142</total><count>3</count></invoice>"
        )
        #expect(xml == "<invoice><total>***</total><count>3</count></invoice>")

        let prose = SetupFeedbackExchange.redactMoney(in: "Your bill is 142.50 EUR, pay by Friday")
        #expect(!prose.contains("142"))
        #expect(prose.contains("pay by Friday"))
    }

    @Test("摘要也过一遍：URL 里的金额打掉，状态码留下")
    func summaryIsRedactedToo() throws {
        let dump = try #require(SetupFeedbackExchange.outboundText([
            HTTPExchange(
                summary: "GET https://api.example.com/v2/usage?amount=12.50\nHTTP 402",
                body: "Payment required"
            ),
        ]))
        #expect(!dump.contains("12.50"))
        #expect(dump.contains("HTTP 402"))
        #expect(dump.contains("Payment required"))
    }
}
