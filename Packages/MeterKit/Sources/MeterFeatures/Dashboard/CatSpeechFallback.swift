import Foundation
import MeterCore
import MeterFormat

/// 候选句由我们写死，第 0 条就是当前表情要说的那句。
/// 首选句的**分岔**单源在 `CatSpeechPrimaryLine`（MeterFormat，Android 共用）；
/// 这里只做 iOS 的渲染，并给每个分岔补第二候选。
enum CatSpeechFallback {
    static func line(for prompt: CatSpeechPrompt) -> String {
        candidates(for: prompt)[0].text
    }

    static func candidates(for prompt: CatSpeechPrompt) -> [CatSpeechCandidate] {
        let pair = pair(for: CatSpeechPrimaryLine.resolve(facts(from: prompt)))
        return [pair.primary, pair.secondary]
    }

    private static func facts(from prompt: CatSpeechPrompt) -> CatSpeechPrimaryLine.Facts {
        CatSpeechPrimaryLine.Facts(
            mood: prompt.mood,
            hasAnyProvider: prompt.hasAnyProvider,
            totalText: prompt.totalText,
            projectedText: prompt.projectedText,
            allowsProjection: prompt.allowsProjection,
            changePercent: prompt.changePercent,
            leadAnomalyName: prompt.leadAnomalyName,
            leadAnomalyPercent: prompt.leadAnomalyPercent,
            leadBalanceName: prompt.leadBalanceName
        )
    }

    private static func pair(
        for line: CatSpeechPrimaryLine
    ) -> (primary: CatSpeechCandidate, secondary: CatSpeechCandidate) {
        switch line {
        case .sleepingUnread:
            return (
                candidate("sleeping-unread", String(localized: L("这回没读到账单。"))),
                candidate("sleeping-blank", String(localized: L("这回账单是空的。")))
            )
        case .sleepingNone:
            return (
                candidate("sleeping-none", String(localized: L("还没有账单。"))),
                candidate("sleeping-empty", String(localized: L("接入一家，才有数字可看。")))
            )
        case .dead:
            return (
                candidate("dead-doubled", String(localized: L("这个月比上个月同期涨了一倍多。"))),
                candidate("dead-check", String(localized: L("合计已经翻倍了，得看看出了什么事。")))
            )
        case .shockedPercent(let percent):
            return (
                candidate("shocked-percent", String(localized: L("合计较上月同期涨了 \(percent)%。"))),
                candidate("shocked-steep", String(localized: L("这个月涨得有点猛。")))
            )
        case .shockedSteep:
            return (
                candidate("shocked-steep", String(localized: L("这个月涨得有点猛。"))),
                candidate("shocked-fast", String(localized: L("这个月的合计涨得很快。")))
            )
        case .alertBalance(let name):
            return (
                candidate("alert-balance", String(localized: L("\(name) 的余额快见底了。"))),
                candidate("alert-balance-soon", String(localized: L("\(name) 的余额撑不了太久。")))
            )
        case .alertAnomaly(let name, let percent):
            return (
                candidate("alert-anomaly", String(localized: L("\(name) 较上月同期涨了 \(percent)%。"))),
                candidate("alert-anomaly-watch", String(localized: L("\(name) 这个月涨得反常。")))
            )
        case .alertGeneric:
            return (
                candidate("alert-generic", String(localized: L("有一项需要留意。"))),
                candidate("alert-look", String(localized: L("有一件事值得看一眼。")))
            )
        case .awkward:
            return (
                candidate("awkward-stale", String(localized: L("有几家没刷上来，先看上次的数字。"))),
                candidate("awkward-old", String(localized: L("有几家还是旧数据，先看上次的。")))
            )
        case .savedPercent(let saved):
            return (
                candidate("saved-less", String(localized: L("这个月比上个月同期少花了 \(saved)%。"))),
                candidate("saved-down", String(localized: L("合计比上个月同期低了 \(saved)%。")))
            )
        case .savedFree:
            return (
                candidate("saved-free", String(localized: L("这个月还都在免费额度里。"))),
                candidate("saved-zero", String(localized: L("这个月还没开始计费。")))
            )
        case .normalClosed(let total):
            // 用「那个月」而不是「这个月」：这两句只在回看过去某个月时出现，
            // 说「这个月」指的会是八月，而屏幕上写的是七月。
            return (
                candidate("normal-closed", String(localized: L("那个月合计 \(total)。"))),
                candidate("normal-closed-flat", String(localized: L("那个月一共花了 \(total)。")))
            )
        case .normalProjection(let total, let projected):
            return (
                candidate(
                    "normal-mtd",
                    String(localized: L("本月至今 \(total)，预计月底 \(projected)。"))
                ),
                candidate(
                    "normal-pace",
                    String(localized: L("合计 \(total)，按这个速度月底大概 \(projected)。"))
                )
            )
        }
    }

    private static func candidate(_ id: String, _ text: String) -> CatSpeechCandidate {
        CatSpeechCandidate(id: CatSpeechCandidateID(rawValue: id), text: text)
    }
}
