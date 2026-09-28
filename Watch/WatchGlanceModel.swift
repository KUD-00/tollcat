import Observation
import MeterGlance

/// 手表 App 屏幕上那一份。收到新数由 `WatchGlanceReceiver` 换掉整份。
@MainActor
@Observable
final class WatchGlanceModel {
    static let shared = WatchGlanceModel(glance: GlanceStore.live().load())

    var glance: Glance?

    init(glance: Glance?) {
        self.glance = glance
    }
}
