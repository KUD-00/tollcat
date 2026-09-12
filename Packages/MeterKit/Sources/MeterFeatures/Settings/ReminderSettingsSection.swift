import SwiftUI
import MeterCore
import MeterDesign

struct ReminderSettingsSection: View {
    @Bindable var model: SettingsModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle(isOn: enabledBinding) {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(ReminderSettingsCopy.toggleTitle)
                    ListRowNote(text: ReminderSettingsCopy.toggleNote)
                }
            }
            .accessibilityLabel(ReminderSettingsCopy.toggleTitle)
            .accessibilityHint(ReminderSettingsCopy.toggleNote)

            if model.showsReminderEditors {
                Picker(ReminderSettingsCopy.frequencyLabel, selection: frequencyBinding) {
                    ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                        Text(ReminderSettingsCopy.frequencyTitle(frequency)).tag(frequency)
                    }
                }
                .accessibilityLabel(ReminderSettingsCopy.frequencyLabel)

                DatePicker(
                    ReminderSettingsCopy.timeLabel,
                    selection: timeBinding,
                    displayedComponents: .hourAndMinute
                )
                .environment(\.calendar, model.reminderCalendarForPicker)
                .environment(\.timeZone, model.reminderCalendarForPicker.timeZone)
                .accessibilityLabel(ReminderSettingsCopy.timeLabel)

                if model.reminderSchedule.frequency == .weekly
                    || model.reminderSchedule.frequency == .biweekly {
                    Picker(ReminderSettingsCopy.weekdayLabel, selection: weekdayBinding) {
                        ForEach(weekdayChoices, id: \.self) { weekday in
                            Text(ReminderSettingsCopy.weekdayTitle(weekday, calendar: model.reminderCalendarForPicker)).tag(weekday)
                        }
                    }
                    .accessibilityLabel(ReminderSettingsCopy.weekdayLabel)
                }

                if model.reminderSchedule.frequency == .monthly {
                    Picker(ReminderSettingsCopy.dayOfMonthLabel, selection: dayBinding) {
                        ForEach(1...31, id: \.self) { day in
                            Text(ReminderSettingsCopy.dayOfMonthTitle(day)).tag(day)
                        }
                    }
                    .accessibilityLabel(ReminderSettingsCopy.dayOfMonthLabel)
                }
            }

            if model.showsNotificationDenied {
                VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                    Text(ReminderSettingsCopy.deniedExplanation)
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(action: openSystemSettings) {
                        HStack(spacing: MeterSpacing.xxs) {
                            Text(ReminderSettingsCopy.openSettings)
                            Image(systemName: "gearshape")
                                .imageScale(.small)
                                .accessibilityHidden(true)
                        }
                    }
                    .meterListRowButtonStyle()
                    .frame(minHeight: MeterSpacing.minTap, alignment: .leading)
                    .accessibilityHint(L("打开系统设置，打开 TollCat 的通知"))
                }
            }
        } header: {
            Text(ReminderSettingsCopy.sectionHeader)
        }
    }

    private var weekdayChoices: [Int] {
        ReminderSettingsCopy.weekdays(firstWeekday: model.reminderCalendarForPicker.firstWeekday)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { model.isReminderToggleOn },
            set: { newValue in
                Task { await model.setReminderEnabled(newValue) }
            }
        )
    }

    private var frequencyBinding: Binding<ReminderFrequency> {
        Binding(
            get: { model.reminderSchedule.frequency },
            set: { newValue in
                Task { await model.setReminderFrequency(newValue) }
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = model.reminderSchedule.hour
                components.minute = model.reminderSchedule.minute
                return model.reminderCalendarForPicker.date(from: components) ?? Date()
            },
            set: { date in
                let components = model.reminderCalendarForPicker.dateComponents(
                    [.hour, .minute],
                    from: date
                )
                Task {
                    await model.setReminderTime(
                        hour: components.hour ?? model.reminderSchedule.hour,
                        minute: components.minute ?? model.reminderSchedule.minute
                    )
                }
            }
        )
    }

    private var weekdayBinding: Binding<Int> {
        Binding(
            get: { model.reminderSchedule.weekday },
            set: { newValue in
                Task { await model.setReminderWeekday(newValue) }
            }
        )
    }

    private var dayBinding: Binding<Int> {
        Binding(
            get: { model.reminderSchedule.dayOfMonth },
            set: { newValue in
                Task { await model.setReminderDayOfMonth(newValue) }
            }
        )
    }

    private func openSystemSettings() {
        guard let url = SystemSettingsURL.notifications else { return }
        openURL(url)
    }
}
