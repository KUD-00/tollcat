import Foundation
import MeterCore

/// M1 只读打包副本，不做任何网络请求。
public struct BundledCatalogSource: CatalogSource, Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle? = nil) {
        // `Bundle.module` 是 SPM 生成的 internal，不能出现在 public 默认参数里。
        self.bundle = bundle ?? .module
    }

    /// 同步读一次打包目录。
    ///
    /// composition root（`AppEnvironment`）是同步的，而它组装 provider 时就需要
    /// 汇率。目录是随包走的本地文件，同步读不会卡启动；读不到返回 nil，调用方
    /// 自己退到「只认美元」。
    public static func loadBundled() -> Catalog? {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? CatalogCodec.decode(data)
    }

    public func load() async throws -> Catalog {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogError.bundleResourceMissing
        }
        let data = try Data(contentsOf: url)
        return try CatalogCodec.decode(data)
    }
}
