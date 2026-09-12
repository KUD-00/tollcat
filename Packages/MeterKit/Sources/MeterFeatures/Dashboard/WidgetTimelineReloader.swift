import WidgetKit

/// Widget 只读共享 store。必须在 store 落盘之后再喊它，否则会读到旧数。
enum WidgetTimelineReloader {
    static func reloadAfterStoreWrite() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
