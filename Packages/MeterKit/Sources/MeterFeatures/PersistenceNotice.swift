import Foundation

/// 落盘失败和演示数据的行内提示。演示那条可关掉，内存库那条不能。
public struct PersistenceNotice: Equatable, Identifiable, Sendable {
    public var id: String
    public var message: String
    public var isDismissible: Bool

    public init(id: String, message: String, isDismissible: Bool) {
        self.id = id
        self.message = message
        self.isDismissible = isDismissible
    }
}
