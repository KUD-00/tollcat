import Foundation

/// 反馈附带的环境信息。**全部列在这里，界面上原样展示给用户看。**
///
/// 挑选标准是「能不能帮我复现，且换个人也一样」：
/// - 版本号：绝大多数「这里坏了」都是某个版本坏了。
/// - 系统版本：玻璃工具栏和 SwiftData 迁移都在小版本间变过行为；
///   Mac 壳和 iPhone / iPad 还不是同一套界面。
/// - 机型标识：`iPhone17,1` / `Mac16,1` 这种，决定屏幕尺寸和有没有灵动岛。
/// - 语言：界面文案和数字格式都跟着它变。
///
/// 刻意**不带**的东西：IDFV、广告标识、时区、运营商、屏幕分辨率、
/// 安装时间。它们对复现的帮助小于它们的指纹价值。
struct FeedbackEnvironmentInfo: Hashable, Sendable {
    var appVersion: String
    var osVersion: String
    var deviceModel: String
    var locale: String

    static func current() -> FeedbackEnvironmentInfo {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let model = Self.machineIdentifier()
        return FeedbackEnvironmentInfo(
            appVersion: "\(short) (\(build))",
            osVersion: Self.osVersionText(model: model),
            deviceModel: model,
            locale: Locale.current.identifier
        )
    }

    private static func osVersionText(model: String) -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let name = Self.osName(model: model)
        if version.patchVersion == 0 {
            return "\(name) \(version.majorVersion).\(version.minorVersion)"
        }
        return "\(name) \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// `macOS` / `iPadOS` / `iOS`。名字必须跟编译目标走——Mac 壳报成 iOS，
    /// 复现从第一步就走错平台；iPad 也要和 iPhone 分开，那是两套壳。
    ///
    /// 不读 `UIDevice.current.systemName`（它给的就是这三个名字）：那个属性是
    /// main actor 隔离的，而这一支从 `current()` 起全是 nonisolated —— `FeedbackModel`
    /// 的默认参数在哪求值都得成立。机型标识本来就要采一份，iPad 从它认得出来。
    private static func osName(model: String) -> String {
        #if os(macOS)
        "macOS"
        #elseif os(iOS)
        model.hasPrefix("iPad") ? "iPadOS" : "iOS"
        #else
        "unknown"
        #endif
    }

    /// `iPhone17,1` / `Mac16,1`。系统给的营销名分不出具体机型。
    ///
    /// 模拟器上 `uname` 给的是宿主架构（`arm64`），对诊断毫无意义，
    /// 所以优先读 `SIMULATOR_MODEL_IDENTIFIER`——它才是被模拟的那台机器。
    /// 真机上这个变量不存在，走下面的 `uname`。
    private static func machineIdentifier() -> String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"],
           !simulated.isEmpty {
            return simulated
        }
        var info = utsname()
        guard uname(&info) == 0 else { return "unknown" }
        let raw = withUnsafeBytes(of: &info.machine) { bytes in
            bytes.prefix { $0 != 0 }
        }
        return String(decoding: raw, as: UTF8.self)
    }
}
