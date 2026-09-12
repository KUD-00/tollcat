import Foundation

/// 照官方文档造的响应，还没拿真账号核对。测试和 Stub 从这里读。
public enum OfficialAPIFixture: Sendable {
    public static func data(named name: String, extension ext: String = "json") -> Data? {
        let candidates = [
            ProviderResourceLocator.url(forResource: name, withExtension: ext, subdirectory: "live"),
            ProviderResourceLocator.url(forResource: name, withExtension: ext, subdirectory: "Fixtures/live"),
            ProviderResourceLocator.url(forResource: name, withExtension: ext, subdirectory: "Fixtures"),
            ProviderResourceLocator.url(forResource: name, withExtension: ext),
        ]
        for url in candidates {
            if let url, let data = try? Data(contentsOf: url) {
                return data
            }
        }
        return nil
    }
}
