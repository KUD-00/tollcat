import Foundation
import MeterCore

/// 上次拉成功的目录。Widget 和冷启动都读它，所以要落在 App Group 里。
public protocol CatalogCaching: Sendable {
    func load() -> Catalog?
    func save(_ catalog: Catalog) throws
}
