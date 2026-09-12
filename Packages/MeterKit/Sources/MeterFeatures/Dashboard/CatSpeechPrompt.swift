import Foundation
import MeterCore

/// 挑句子用的、已经算好的事实。候选句只能引用这里的数，不另算。
/// 金额是**从量**口径（`variableUSD`），和首屏主角同一笔钱——
/// 猫说的数必须能在同一屏上找到。
struct CatSpeechPrompt: Sendable {
    var locale: Locale
    var mood: CatMood
    var hasAnyProvider: Bool
    var totalText: String
    var projectedText: String
    /// 这个区间还在走吗。回看已经过完的月份时为 false——那时候外推值等于总数，
    /// 说「按这个速度月底大概 $10」既是废话又暗示那个月还没结束。
    var allowsProjection = true
    var changePercent: Int?
    var leadAnomalyName: String?
    var leadAnomalyPercent: Int?
    var leadBalanceName: String?

    var languageCode: String {
        locale.language.languageCode?.identifier ?? "zh"
    }
}
