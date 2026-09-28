import Foundation

/// 这一眼能说什么。三种情况在表盘上是三句不同的话，不能都画成 $0。
public enum GlanceContent: Codable, Equatable, Sendable {
    /// 一条账单都还没有。
    case noBills
    /// 有账单，但账本还说不了这个月：跨月了，iPhone 还没重折过。
    /// 和 widget 的 `SharedStoreContents.canSpeak` 是同一个判断。
    case waitingForMonth
    case month(GlanceMonth)
}
