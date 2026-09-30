import MeterCore

/// 启动过渡里每枚圆牌落到构成图例的哪一段。跨端只算这一次：iOS 直接用，
/// 桥把结果写进 Android 的 JSON，跟随端只管按 id 找到那颗色块。
public enum LaunchTokenTargets {
    /// 按图例顺序（花得多的在前）给每类圆牌挑第一段同类服务。「其他」和认不出类别的段不接。
    public static func make(from slices: [CompositionSlice]) -> [LaunchTokenKind: String] {
        var targets: [LaunchTokenKind: String] = [:]
        for slice in slices where !slice.isOther {
            guard let provider = slice.providerID,
                  let category = ProviderIdentity.known(provider)?.category,
                  let kind = LaunchTokenKind.kind(for: category),
                  targets[kind] == nil
            else { continue }
            targets[kind] = slice.id
        }
        return targets
    }
}
