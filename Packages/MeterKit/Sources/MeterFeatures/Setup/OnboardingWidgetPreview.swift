import SwiftUI
import MeterCore
import MeterDesign
import MeterFormat
import MeterModules

/// 开场第 3 页：和真中号小组件同一套结构（月份行角标猫 + 总额 + 预计 + 构成条）。
struct OnboardingWidgetPreview: View {
    var presentation: MoneyPresentation
    var now: Date = MeterClock.design.now
    var calendar: Calendar = MeterClock.design.calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: MeterSpacing.xs) {
                Text(monthCaption)
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .lineLimit(1)
                Spacer(minLength: 0)
                CatView(mood: .normal, size: MeterSpacing.catWidget)
            }

            Text(totalText)
                .font(MeterFont.title.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.meterLabel)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(value: totalValue))
                .animation(DashboardMotion.number, value: totalValue)
                .padding(.top, MeterSpacing.xxs)

            Text(projectedCaption)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.top, MeterSpacing.xxs)

            Spacer(minLength: MeterSpacing.xs)

            SegmentBar(
                segments: segments,
                height: MeterSpacing.segmentBarWidget
            )

            Text(refreshCaption)
                .font(MeterFont.caption2)
                .foregroundStyle(Color.meterTertiaryLabel)
                .lineLimit(1)
                .padding(.top, MeterSpacing.xxs)
        }
        .padding(MeterSpacing.md)
        .frame(maxWidth: .infinity, minHeight: MeterSpacing.onboardingWidget, alignment: .leading)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .environment(\.moneyPresentation, presentation)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private var monthCaption: String {
        MeterDateFormat.monthName(now: now, calendar: calendar)
    }

    private var totalText: String {
        OnboardingDemoContent.variableUSD.formatted(using: presentation)
    }

    private var totalValue: Double {
        NSDecimalNumber(decimal: presentation.amount(from: OnboardingDemoContent.variableUSD)).doubleValue
    }

    private var projectedCaption: String {
        let amount = OnboardingDemoContent.projectedVariableUSD.formatted(using: presentation)
        return String(localized: MeterFormatText.resource("预计 \(amount)"))
    }

    private var refreshCaption: String {
        MeterDateFormat.relative(
            from: now.addingTimeInterval(-12 * 60),
            now: now,
            calendar: calendar
        )
    }

    private var segments: [(color: Color, fraction: Double)] {
        // 和 Widget 的新用户默认口径一致：仅从量，订阅不占段。
        let billed = OnboardingDemoContent.usage
        let total = billed.reduce(Money.zero) { $0 + $1.1 }
        return billed.enumerated().map { index, item in
            let fraction = NSDecimalNumber(decimal: item.1.usd / total.usd).doubleValue
            return (MeterColor.composition(index: index), fraction)
        }
    }

    private var spokenLabel: String {
        [
            monthCaption,
            SpokenMoney.label(for: OnboardingDemoContent.variableUSD, presentation: presentation),
            String(localized: MeterFormatText.resource("预计 \(SpokenMoney.label(for: OnboardingDemoContent.projectedVariableUSD, presentation: presentation))")),
            refreshCaption,
        ].joined(separator: String(localized: MeterFormatText.resource("，")))
    }
}

#Preview("Light") {
    OnboardingWidgetPreview(presentation: .usd)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingWidgetPreview(presentation: .usd)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
