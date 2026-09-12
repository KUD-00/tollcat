import Foundation

/// `X.Y.Z` 的可比大小。字符串比不行：`1.10.0` 会排在 `1.9.0` 前面。
///
/// 解不出来就是 `nil`，调用方一律当「不知道」处理——宁可不弹抽屉，
/// 也不要因为版本号读歪了把说明放两遍。
struct ReleaseVersion: Comparable, Equatable, Sendable {
    var major: Int
    var minor: Int
    var patch: Int

    init?(_ raw: String) {
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        guard let major = Int(parts[0]), let minor = Int(parts[1]), let patch = Int(parts[2]) else {
            return nil
        }
        guard major >= 0, minor >= 0, patch >= 0 else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func < (lhs: ReleaseVersion, rhs: ReleaseVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
