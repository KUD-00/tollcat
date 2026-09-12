import Foundation
import MeterCore
import MeterFormat

public enum BudgetBuilder {
    /// 条的读数（比例、超没超、快到了没有）在 `MeterCore/BudgetGauge`，这里只写字。
    public static func make(
        monthToDate: MonthToDate,
        budgetUSD: Decimal?,
        presentation: MoneyPresentation
    ) -> BudgetModuleContent? {
        guard let gauge = BudgetGauge.make(spent: monthToDate.totalUSD, budgetUSD: budgetUSD) else {
            return nil
        }
        let caption: String
        if gauge.isOver {
            caption = String(localized: L("超出 \(gauge.overspend.formatted(using: presentation))"))
        } else {
            // `used(_:)` 出来的就是「用了 72%」，模板里再写一遍「用了」就成了
            // 「用了 用了 72%」（英日同理）。
            caption = String(localized: L("还剩 \(gauge.remaining.formatted(using: presentation))，\(DashboardPercentFormat.used(gauge.fraction))"))
        }
        return BudgetModuleContent(
            spentText: gauge.spent.formatted(using: presentation),
            budgetText: gauge.budget.formatted(using: presentation),
            fraction: gauge.fraction,
            caption: caption,
            spokenLabel: String(localized: L("预算 \(SpokenMoney.label(for: gauge.budget, presentation: presentation))，已花 \(SpokenMoney.label(for: gauge.spent, presentation: presentation))，\(caption)")),
            isOver: gauge.isOver,
            isClose: gauge.isClose
        )
    }
}
