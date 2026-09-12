import Foundation

/// 桥载荷的 schema 版本。改了字段名或结构就 +1，Kotlin / C# 侧对不上会打日志。
/// 两侧声明分别在 ProductDashboard/ProductCatalog（编码）和 CatalogModels（解码）。
package enum JNISchema {
    package static let version = 7
}

/// Kotlin 解压 SwiftPM resource bundle 后注入的根目录。
/// Windows 壳同样走这条：`Bundle.module` 在交叉编译目标上解析不到打包资源。
package enum JNIResourceRoot {
    private final class Box: @unchecked Sendable {
        let lock = NSLock()
        var url: URL?
    }

    private static let box = Box()

    package static func set(_ url: URL?) {
        box.lock.lock()
        box.url = url
        box.lock.unlock()
    }

    package static var url: URL? {
        box.lock.lock()
        defer { box.lock.unlock() }
        return box.url
    }
}

package enum JNIJSON {
    package static func stringify(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }

    package static func parse(_ string: String) -> Any? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    package static func array(_ string: String) -> [[String: Any]] {
        if let array = parse(string) as? [[String: Any]] {
            return array
        }
        if let wrapped = parse(string) as? [String: Any],
           let array = wrapped["items"] as? [[String: Any]] {
            return array
        }
        return []
    }

    package static func object(_ string: String) -> [String: Any] {
        parse(string) as? [String: Any] ?? [:]
    }
}
