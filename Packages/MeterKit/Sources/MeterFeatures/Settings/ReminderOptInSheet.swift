import SwiftUI
import MeterDesign

/// 系统通知框只能弹一次。打开前先把「会收到什么、为什么值得开」讲清楚。
struct ReminderOptInSheet: View {
    var onAllow: () -> Void
    var onDecline: () -> Void
    @Environment(\.usesPadChrome) private var usesPadChrome

    var body: some View {
        NavigationStack {
            MeterGroupedList {
                Section {
                    VStack(alignment: .leading, spacing: MeterSpacing.md) {
                        Text(L("到点会提醒你打开 App，看看这个月花了多少。通知里不会出现金额。"))
                            .font(MeterFont.body)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                        ReminderNotificationPreview()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .meterSheetTitle(Text(L("让猫猫到点叫你回来")))
            .meterSheetClose { onDecline() }
            .meterPrimaryActionBar {
                Button(action: onAllow) {
                    Text(L("打开通知"))
                        .frame(maxWidth: .infinity)
                }
                .meterPrimaryActionStyle()
            }
        }
        .meterDrawerChrome(.mediumLarge, usesPadChrome: usesPadChrome)
    }
}

#Preview("Light") {
    ReminderOptInSheet(onAllow: {}, onDecline: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ReminderOptInSheet(onAllow: {}, onDecline: {})
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    ReminderOptInSheet(onAllow: {}, onDecline: {})
        .dynamicTypeSize(.accessibility3)
}
