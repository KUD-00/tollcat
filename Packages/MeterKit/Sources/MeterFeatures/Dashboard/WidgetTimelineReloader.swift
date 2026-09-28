import WidgetKit

/// Widget 只读共享 store。必须在 store 落盘之后再喊它，否则会读到旧数。
///
/// 手表也在这里一起喊：它看到的数是 iPhone 推过去的，推的时机和 widget 重载是同一刻。
enum WidgetTimelineReloader {
    static func reloadAfterStoreWrite() {
        WidgetCenter.shared.reloadAllTimelines()
        #if os(iOS)
        WatchGlancePublisher.shared.storeDidChange()
        #endif
    }
}
