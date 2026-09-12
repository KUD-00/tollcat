import Foundation
import MeterCore
import MeterFormat

/// 猫气泡的兜底句。**分岔**单源在 `CatSpeechPrimaryLine`（MeterFormat，与 iOS
/// `CatSpeechFallback` 同一份）；句子本身单源在 MeterFeatures 的
/// Localizable.xcstrings（经 shared/jni-copy.json 生成 `JNICopy`）。
/// 这里只把分岔结果渲染成对应语言的句子。
package enum ProductSpeech {
    package typealias Facts = CatSpeechPrimaryLine.Facts

    package static func line(_ facts: Facts, localeTag: String) -> String {
        switch CatSpeechPrimaryLine.resolve(facts) {
        case .sleepingUnread:
            return JNICopy.text("这回没读到账单。", localeTag)
        case .sleepingNone:
            return JNICopy.text("还没有账单。", localeTag)
        case .dead:
            return JNICopy.text("这个月比上个月同期涨了一倍多。", localeTag)
        case .shockedPercent(let percent):
            return JNICopy.format("合计较上月同期涨了 %lld%%。", localeTag, String(percent))
        case .shockedSteep:
            return JNICopy.text("这个月涨得有点猛。", localeTag)
        case .alertBalance(let name):
            return JNICopy.format("%@ 的余额快见底了。", localeTag, name)
        case .alertAnomaly(let name, let percent):
            return JNICopy.format("%@ 较上月同期涨了 %lld%%。", localeTag, name, String(percent))
        case .alertGeneric:
            return JNICopy.text("有一项需要留意。", localeTag)
        case .awkward:
            return JNICopy.text("有几家没刷上来，先看上次的数字。", localeTag)
        case .savedPercent(let saved):
            return JNICopy.format("这个月比上个月同期少花了 %lld%%。", localeTag, String(saved))
        case .savedFree:
            return JNICopy.text("这个月还都在免费额度里。", localeTag)
        case .normalClosed(let total):
            return JNICopy.format("那个月合计 %@。", localeTag, total)
        case .normalProjection(let total, let projected):
            return JNICopy.format("本月至今 %@，预计月底 %@。", localeTag, total, projected)
        }
    }
}
