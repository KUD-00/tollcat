import SwiftUI
import MeterDesign

/// 系统通知长什么样。文案和真通知同一份，免得预览撒谎。
struct ReminderNotificationPreview: View {
    var body: some View {
        HStack(alignment: .top, spacing: MeterSpacing.sm) {
            CatView(mood: .normal, size: MeterSpacing.providerGlyphLarge)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text("TollCat")
                    .font(MeterFont.subheadline.weight(.semibold))
                    .foregroundStyle(Color.meterLabel)
                Text(ReminderNotificationCopy.title)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                Text(ReminderNotificationCopy.lookBody)
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.card, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L("通知预览：\(ReminderNotificationCopy.title)。\(ReminderNotificationCopy.lookBody)")
        )
    }
}

#Preview("Light") {
    ReminderNotificationPreview()
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ReminderNotificationPreview()
        .padding()
        .preferredColorScheme(.dark)
}
