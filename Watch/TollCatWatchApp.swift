import SwiftUI
import MeterGlance

/// 手表壳。只读：它看到的每一个数都是 iPhone 推来的，自己不出网、不存凭据、不折算。
@main
struct TollCatWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            WatchRootView(model: WatchGlanceModel.shared)
        }
    }
}

struct WatchRootView: View {
    let model: WatchGlanceModel

    var body: some View {
        NavigationStack {
            GlanceScreen(glance: model.glance)
                .navigationTitle(Text(verbatim: "TollCat"))
        }
        .tint(GlanceStyle.accent)
        // 开着 App 的时候向 iPhone 要一份最新的；iPhone 不在身边就用手上那份。
        .task { WatchGlanceReceiver.shared.requestLatest() }
    }
}

#Preview {
    WatchRootView(model: WatchGlanceModel(glance: GlanceSamples.month))
}
