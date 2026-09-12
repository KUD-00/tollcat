import SwiftUI
import MeterCore
import MeterDesign
import MeterFormat
import MeterPersistence

/// 菜单栏那一小块。露什么看设置里的「菜单栏」：默认只有一只猫，
/// 金额点开才看得到。数字口径和 Widget 相同：本月、全部账号、跟「算进固定订阅」。
public struct MenuBarMeterLabel: View {
    var dashboard: DashboardModel

    public init(dashboard: DashboardModel) {
        self.dashboard = dashboard
    }

    public var body: some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch dashboard.shell.menuBarStyle {
        case .cat:
            catGlyph
        case .catAndAmount:
            HStack(spacing: MeterSpacing.xs) {
                catGlyph
                if let monthToDate = widgetScopedMonthToDate {
                    Text(monthToDate.totalUSD.formatted(using: dashboard.moneyPresentation))
                        .monospacedDigit()
                }
            }
        case .amount:
            Text(amountText)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var catGlyph: some View {
        #if os(macOS)
        Image(nsImage: CatMenuBarGlyph.image(for: MeterDesign.CatMood(dashboard.catMood)))
        #else
        Text(L("TollCat"))
        #endif
    }

    private var amountText: String {
        guard let monthToDate = widgetScopedMonthToDate else {
            return String(localized: L("TollCat"))
        }
        return monthToDate.totalUSD.formatted(using: dashboard.moneyPresentation)
    }

    /// 读屏永远报金额：这是用户自己听，不是旁人瞄屏幕。
    private var accessibilityLabel: String {
        guard let monthToDate = widgetScopedMonthToDate else {
            return String(localized: L("还没有账单"))
        }
        return [
            String(localized: MeterFormatText.resource("本月支出")),
            SpokenMoney.label(
                for: monthToDate.totalUSD,
                presentation: dashboard.moneyPresentation
            ),
        ].joined(separator: String(localized: MeterFormatText.resource("，")))
    }

    private var widgetScopedMonthToDate: MonthToDate? {
        dashboard.widgetScopedMonthToDate
    }
}
