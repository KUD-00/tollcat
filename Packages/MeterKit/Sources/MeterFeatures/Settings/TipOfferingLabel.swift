import SwiftUI
import MeterDesign
import MeterTips

struct TipOfferingLabel: View {
    enum Layout {
        case column
        case row
    }

    var offering: TipOffering
    var kind: TipTreatKind
    var layout: Layout

    var body: some View {
        switch layout {
        case .column:
            VStack(spacing: MeterSpacing.xs) {
                TipTreatView(kind: kind, size: MeterSpacing.tipTreat)
                Text(offering.displayName)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                price
            }
            .frame(maxWidth: .infinity)
        case .row:
            HStack(spacing: MeterSpacing.md) {
                TipTreatView(kind: kind, size: MeterSpacing.tipTreat)
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(offering.displayName)
                        .font(MeterFont.body)
                        .foregroundStyle(Color.meterLabel)
                    price
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var price: some View {
        Text(offering.displayPrice)
            .font(MeterFont.bodyEmphasized)
            .monospacedDigit()
            .foregroundStyle(Color.accentColor)
    }
}
