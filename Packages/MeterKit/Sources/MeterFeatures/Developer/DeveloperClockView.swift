#if DEBUG
import SwiftUI
import MeterDesign

struct DeveloperClockView: View {
    var dashboard: DashboardModel
    @Environment(DeveloperSession.self) private var session
    @State private var date: Date

    init(dashboard: DashboardModel) {
        self.dashboard = dashboard
        _date = State(initialValue: DeveloperSession.shared.clockOverride ?? dashboard.clock.now)
    }

    var body: some View {
        MeterGroupedList {
            Section {
                DatePicker(L("当前时间"), selection: $date)
                    .datePickerStyle(.graphical)
                    .onChange(of: date) { _, newValue in
                        session.apply(now: newValue, to: dashboard)
                    }
                if session.clockOverride != nil {
                    Button(L("恢复设备时间")) {
                        session.clearClock(on: dashboard)
                        date = dashboard.clock.now
                    }
                }
            } footer: {
                Text(L("折算、月份标题、预计月底都读这个时间。改完回到仪表页就能看到。"))
            }

            Section {
                ForEach(DeveloperClockPreset.allCases) { preset in
                    Button(preset.title) {
                        let next = preset.date(calendar: dashboard.clock.calendar, now: date)
                        date = next
                        session.apply(now: next, to: dashboard)
                    }
                }
            } header: {
                Text(L("边界"))
            }
        }
        .navigationTitle(L("时间覆盖"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack {
        DeveloperClockView(dashboard: .preview)
    }
    .environment(DeveloperSession.shared)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DeveloperClockView(dashboard: .preview)
    }
    .environment(DeveloperSession.shared)
    .preferredColorScheme(.dark)
}
#endif
