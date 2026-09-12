import Foundation
import MeterCore

public struct ComparisonModuleContent: Equatable, Sendable {
    public var percentText: String
    public var caption: String
    /// 详情页主角下面那行；有还不能对比的金额时会写进这句。
    public var windowCaption: String = ""
    public var spokenLabel: String
    public var current: Double
    public var previous: Double
    public var currentLabel: String
    public var previousLabel: String
    public var tone: Tone
    /// 对比窗口那个上月的名字，详情行「对比 7 月同期」用。
    public var previousMonthName: String = ""
    public var items: [ComparisonItem] = []

    public init(
        percentText: String,
        caption: String,
        windowCaption: String = "",
        spokenLabel: String,
        current: Double,
        previous: Double,
        currentLabel: String,
        previousLabel: String,
        tone: Tone,
        previousMonthName: String = "",
        items: [ComparisonItem] = []
    ) {
        self.percentText = percentText
        self.caption = caption
        self.windowCaption = windowCaption
        self.spokenLabel = spokenLabel
        self.current = current
        self.previous = previous
        self.currentLabel = currentLabel
        self.previousLabel = previousLabel
        self.tone = tone
        self.previousMonthName = previousMonthName
        self.items = items
    }

    public enum Tone: Equatable, Sendable {
        case up
        case down
        case flat
        case unknown
    }

    public var comparableItems: [ComparisonItem] {
        items.filter(\.isComparable)
    }

    public var incomparableItems: [ComparisonItem] {
        items.filter { !$0.isComparable }
    }
}
