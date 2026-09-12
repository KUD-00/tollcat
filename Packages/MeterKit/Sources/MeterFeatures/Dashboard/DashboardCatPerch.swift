import CoreGraphics
import Foundation
import MeterDesign

/// 猫可以坐的几处页面空白。空白不靠检测，是规定出来的：
/// 合计块右侧给猫留出身位（字让开、块高兜底），分享胶囊居中后两翼天然是空的。
/// 每次进仪表从可坐的里面抽一个，不要钉死在一处。
///
/// 分享进了顶栏「更多」之后，仪表上实际只抽合计区那三处。两翼那两处留着：
/// 猫猫 gallery 还画，落点几何也还有测试。
enum DashboardCatPerch: String, CaseIterable, Identifiable, Sendable {
    case sitHeaderRight
    case loafHeaderRight
    case hangHeaderRight
    case sitShareLeft
    case sitShareRight

    /// 猫锚在哪块空白上。合计区落点没合计就不可坐，两翼落点没分享按钮同理。
    enum Zone: Sendable {
        case header
        case share
    }

    var id: String { rawValue }

    var zone: Zone {
        switch self {
        case .sitHeaderRight, .loafHeaderRight, .hangHeaderRight: .header
        case .sitShareLeft, .sitShareRight: .share
        }
    }

    var galleryTitle: LocalizedStringResource {
        switch self {
        case .sitHeaderRight: L("坐在合计右边")
        case .loafHeaderRight: L("趴在合计右边")
        case .hangHeaderRight: L("从大标题底下探出来")
        case .sitShareLeft: L("坐在分享按钮左边")
        case .sitShareRight: L("坐在分享按钮右边")
        }
    }

    static func available(header: Bool, share: Bool) -> [Self] {
        allCases.filter {
            switch $0.zone {
            case .header: header
            case .share: share
            }
        }
    }

    static func random(using generator: inout some RandomNumberGenerator) -> Self {
        allCases.randomElement(using: &generator) ?? .sitHeaderRight
    }

    /// `seed` 只为了测试可复现，界面上按可坐清单 `randomElement()`。
    static func pick(seed: UInt64) -> Self {
        var generator = SplitMix64(seed: seed)
        return random(using: &generator)
    }

    /// 合计区落点钉在右侧这么宽的一条带里。只约束猫自己（落点几何和测试用），
    /// 字不给猫让位——合计区的猫画在内容底下，UI 压猫，不是猫压 UI。
    static var headerTrailingReserve: CGFloat {
        MeterSpacing.catDashboard + MeterSpacing.xs
    }

    /// 合计块至少要这么高，猫顶才不会伸出舞台被 List 裁掉。
    /// 坐姿脚伸进卡沿 xs，块到卡之间还有一截 sm，都从猫身高里扣。
    static var headerMinHeight: CGFloat {
        MeterSpacing.catDashboard - MeterSpacing.xs - MeterSpacing.sm
    }

    /// `header`：合计块顶到构成卡上沿那条横带（含块卡间距），舞台坐标。
    /// `share`：分享胶囊的实际边框，舞台坐标。每个落点只用自己那个锚。
    func placement(catSize: CGFloat, header: CGRect, share: CGRect) -> DashboardCatPlacement {
        switch self {
        case .sitHeaderRight:
            // 脚伸进构成卡上沿 xs：踩着卡沿才不像悬空。再深会碰到卡里第一行。
            return DashboardCatPlacement(
                x: header.maxX - catSize * 0.92,
                y: header.maxY + MeterSpacing.xs - catSize,
                rotationDegrees: -6,
                isFlipped: false
            )
        case .loafHeaderRight:
            return DashboardCatPlacement(
                x: header.maxX - catSize * 1.02,
                y: header.maxY + MeterSpacing.xs - catSize,
                rotationDegrees: 8,
                isFlipped: true
            )
        case .hangHeaderRight:
            // 顶着舞台上沿，看起来像从大标题底下探出来。
            // 0.78 会探出屏幕右缘被削平——舞台右侧只有 pageHorizontal 那点余量。
            return DashboardCatPlacement(
                x: header.maxX - catSize * 0.9,
                y: 0,
                rotationDegrees: 8,
                isFlipped: true
            )
        case .sitShareLeft:
            return DashboardCatPlacement(
                x: share.minX - catSize - MeterSpacing.xs,
                y: share.maxY - catSize,
                rotationDegrees: 6,
                isFlipped: true
            )
        case .sitShareRight:
            return DashboardCatPlacement(
                x: share.maxX + MeterSpacing.xs,
                y: share.maxY - catSize,
                rotationDegrees: -6,
                isFlipped: false
            )
        }
    }
}
