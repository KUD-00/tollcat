import Foundation
import MeterCore
import MeterPersistence

/// 教程分段小标题。字段名来自目录，前面的「如何获取」是界面文案。
enum SetupPartHeading {
    static func resource(for part: SetupPart) -> LocalizedStringResource? {
        let title = part.title
        guard !title.isEmpty else { return nil }
        return L("如何获取\(title)")
    }
}
