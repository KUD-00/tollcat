import os

/// 真机调试用统一 subsystem。Xcode 控制台和 Mac 上的「控制台」App 都按这个滤。
enum TollCatLog {
    static let refresh = Logger(subsystem: subsystem, category: "refresh")
    static let catalog = Logger(subsystem: subsystem, category: "catalog")
    static let inbox = Logger(subsystem: subsystem, category: "inbox")
    static let store = Logger(subsystem: subsystem, category: "store")

    private static let subsystem = "com.zhechengqi.tollcat"

    /// 写 os.Logger，开发构建再抄一份到内存，好在 App 里整段复制。
    static func event(_ category: String, _ message: String) {
        Logger(subsystem: subsystem, category: category).info("\(message, privacy: .public)")
        #if DEBUG
        DeveloperDebugLog.record(category: category, message)
        #endif
    }
}
