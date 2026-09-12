import Foundation
import MeterDesign

/// 抽屉顶上那张图。三档，成本从零到几百 KB。
///
/// 前两档是零字节的——素材已经在仓库里：猫的几何来自 `shared/cat.json`，
/// 服务图标来自 `shared/providers.json`，两者三端同源。
/// `shot` 是位图，所以只有最新一条能带（生成器上有闸），而且图里不许有字：
/// 有字就要三语三份，成本翻三倍，还必然和译文漂移。
enum WhatsNewHero: Hashable, Sendable {
    case cat(CatMood)
    /// `shared/providers.json` 里的 provider key。「这一版支持 X」这类条目用。
    case glyph(String)
    /// `shared/whatsnew/media/<name>-{light,dark}@3x.png` 的 name。
    case shot(String)
}
