#if DEBUG
import Foundation

enum DeveloperBuildInfo {
    /// 用户可见版本号 `X.Y.Z`，不带 build 号。更新说明的判据按这个比大小。
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    static var versionCaption: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }

    static var executableModifiedAt: Date? {
        guard let url = Bundle.main.executableURL else { return nil }
        return try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    static var gitCommit: String? {
        Bundle.main.infoDictionary?["MeterGitCommit"] as? String
    }
}
#endif
