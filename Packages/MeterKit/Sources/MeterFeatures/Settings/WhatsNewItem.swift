import Foundation

/// 抽屉里的一条：符号 + 标题 + 正文。Apple 自己的「新功能」表就是这个形。
struct WhatsNewItem: Identifiable, Hashable, Sendable {
    /// 稳定 id。改名等于换一条，所以它也是以后远程文本 overlay 的钥匙——
    /// 结构编译进包，只有 `title` / `body` 可能被按这个 id 覆盖。
    var id: String
    /// SF Symbol 名。Android / Windows 各有自己那一列，不假装统一。
    var symbol: String?
    var title: WhatsNewText
    var body: WhatsNewText
}
