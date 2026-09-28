import Foundation

/// `Glance` ⇄ WatchConnectivity 字典。两头（iPhone 发、手表收）只认这一处，
/// 字典键和日期编码不会在两边各写一份。
public enum GlanceCodec {
    /// applicationContext / userInfo / message 里的那个键。
    public static let payloadKey = "glance"
    /// 手表开着 App 时主动向 iPhone 要一份最新的。
    public static let requestKey = "glanceRequest"

    public static func encode(_ glance: Glance) throws -> Data {
        try encoder.encode(glance)
    }

    /// 解不开、或者格式版本对不上都回 nil：手表和 iPhone 不一定同时升级，
    /// 对不上的那份丢掉等下一次推送，比猜着读一份旧格式可靠。
    public static func decode(_ data: Data) -> Glance? {
        guard let glance = try? decoder.decode(Glance.self, from: data),
              glance.schema == Glance.currentSchema
        else {
            return nil
        }
        return glance
    }

    public static func message(_ glance: Glance) throws -> [String: Any] {
        [payloadKey: try encode(glance)]
    }

    public static func glance(in message: [String: Any]) -> Glance? {
        (message[payloadKey] as? Data).flatMap(decode)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
