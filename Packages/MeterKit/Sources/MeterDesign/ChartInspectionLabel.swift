import SwiftUI

/// 按住图表时跟在竖线旁边的那块：日期 + 金额。容器样式在 [ChartCalloutLabel]。
struct ChartInspectionLabel: View {
    var date: Date
    var amount: Double?
    var unit: ChartTimeUnit

    var body: some View {
        ChartCalloutLabel(
            title: date.formatted(dateFormat),
            valueText: amount.map(ChartMoneyScale.detailLabel)
        )
    }

    private var dateFormat: Date.FormatStyle {
        switch unit {
        case .day:
            .dateTime.month(.abbreviated).day()
        case .month:
            .dateTime.year().month(.abbreviated)
        }
    }
}
