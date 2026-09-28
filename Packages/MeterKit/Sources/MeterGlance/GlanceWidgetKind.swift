import SwiftUI
import WidgetKit

/// 「一眼」那几种小组件：iPhone 锁屏和手表表盘各有一份壳，登记的是同一张表。
///
/// 两种而不是一种：表盘上的一个圆形位要么放金额、要么放预算圆环，
/// 让用户在图库里按名字挑，比加完再进编辑去换直接。
public enum GlanceWidgetKind: String, CaseIterable, Sendable {
    case month
    case budget

    public var kind: String { "TollCatGlance.\(rawValue)" }

    public var displayName: LocalizedStringResource {
        switch self {
        case .month: L("本月")
        case .budget: L("预算")
        }
    }

    public var summary: LocalizedStringResource {
        switch self {
        case .month: L("这个月花了多少，按现在的速度月底大概多少。")
        case .budget: L("这个月的预算用了几成。在 iPhone 上设了预算才有数。")
        }
    }

    /// 这一种在这台设备上给哪几格。角落位只有手表有。
    public var families: [WidgetFamily] {
        #if os(watchOS)
        switch self {
        case .month: [.accessoryRectangular, .accessoryCircular, .accessoryInline, .accessoryCorner]
        case .budget: [.accessoryCircular, .accessoryCorner]
        }
        #elseif os(iOS)
        switch self {
        case .month: [.accessoryRectangular, .accessoryCircular, .accessoryInline]
        case .budget: [.accessoryCircular]
        }
        #else
        // Mac 没有锁屏也没有表盘。模块照样在 Mac 上编（MeterFeatures 链它），只是没有格子可给。
        []
        #endif
    }
}

/// 一格该画哪块视图。两份壳都走这里，iPhone 锁屏和表盘上同一格长得一样。
public struct GlanceWidgetView: View {
    private let kind: GlanceWidgetKind
    private let glance: Glance?
    private let now: Date
    @Environment(\.widgetFamily) private var family

    public init(kind: GlanceWidgetKind, glance: Glance?, now: Date) {
        self.kind = kind
        self.glance = glance
        self.now = now
    }

    public var body: some View {
        let display = GlanceDisplay.resolve(glance, now: now)
        #if os(macOS)
        GlanceRectangularView(display: display, now: now)
        #else
        switch family {
        case .accessoryRectangular:
            GlanceRectangularView(display: display, now: now)
        case .accessoryInline:
            GlanceInlineView(display: display)
        #if os(watchOS)
        case .accessoryCorner:
            GlanceCornerView(display: display, showsBudget: kind == .budget)
        #endif
        default:
            switch kind {
            case .month: GlanceCircularAmountView(display: display)
            case .budget: GlanceCircularBudgetView(display: display)
            }
        }
        #endif
    }
}
