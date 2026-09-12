// GENERATED — 由 scripts/generate-shared.py 从 shared/module-size.json 生成。
// 不要手改：改 shared/module-size.json 后重跑生成器。


import CoreGraphics

/// 模块的**宽度**档：横向能排下什么。
///
/// 和高度档（`ModuleHeight`）、容器档（`ModuleContainer`）是三根正交的轴，
/// 一起决定同一个模块视图在 iPhone 列表 / bento 卡 / 侧栏 / widget / 分享卡里的版式。
///
/// 档位由**容器**声明（`meterModuleStyle(width:height:container:)`），模块只读不量：
/// 量自身尺寸再回填是布局反馈环，会转死主线程。
///
/// 档位是提示不是义务。没做某一档版式的模块按就近的下一档画，
/// 所以判断一律写成 `width >= .wide` 这种区间比较，不要穷举 switch。
public enum ModuleWidth: Int, CaseIterable, Comparable, Sendable {
    /// 挤。一个数加一行小字就满了；图和列表并排会两边都不够看，改上下叠。
    ///
    /// 出现在：
    /// - iOS / macOS widget systemSmall（约 146 内容宽）
    /// - bento 卡被挤到 0.75 格（约 155）
    case compact = 0
    /// 基准档。今天绝大多数壳都落在这里，所有模块都必须在这一档下好看。
    ///
    /// 出现在：
    /// - iPhone 列表行（约 345）
    /// - bento 卡一格（约 218）
    /// - widget systemMedium / systemLarge（约 340）
    /// - 分享卡的模块卡
    /// - iPad / Mac 侧栏底部那张卡（钉模块时列拉到上限，约 224 内容宽）
    case regular = 1
    /// 宽到列表可以分两列、图可以和列表真正并排。宽窗口下的 bento 卡走这一档。
    ///
    /// 出现在：
    /// - Mac 宽窗口的 bento 卡（三列封顶后每列约 460）
    /// - iPad 横屏分栏里的 bento 卡
    case wide = 2
    /// 很宽。今天只有大显示器上的 bento 卡够得着；没有专门版式的模块按 wide 画。
    ///
    /// 出现在：
    /// - 外接大屏上的 Mac 窗口（每列约 628 起）
    case expanded = 3

    /// 这一档从多宽起算。量的是模块拿到的内容宽，容器的内边距已经扣掉。
    public var minContentWidth: CGFloat {
        switch self {
        case .compact: 0
        case .regular: 200
        case .wide: 380
        case .expanded: 560
        }
    }

    /// 一个内容宽落在哪一档。容器算好宽度调这里，别在模块里调。
    public static func bucket(forContentWidth width: CGFloat) -> ModuleWidth {
        allCases.last { width >= $0.minContentWidth } ?? .compact
    }

    public static func < (lhs: ModuleWidth, rhs: ModuleWidth) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// 模块的**高度**档：纵向预算。起头那个大数字要不要、图表多大、列表列几行。
///
/// 为什么高度必须单独成一根轴：widget 的 systemMedium 和 systemLarge 内容宽一样
/// （都约 300），高度差 2.5 倍——宽度轴分不开它俩，容器档两个又都是 `.snapshot`。
///
/// `.unbounded` 不是「很高」，是「没有上限」：手机 List 的行想多高就多高，
/// 所以它反过来是**不走卡版式**的那一档——圆环用整只、列表列全部。
public enum ModuleHeight: Int, CaseIterable, Comparable, Sendable {
    /// 只够一个数加一两行。列表类模块最多列两行，图表要压到最小可读。
    ///
    /// 出现在：
    /// - iOS / macOS widget systemSmall（约 126 内容高）
    /// - widget systemMedium（同样约 126，宽的是它，高不是）
    case tight = 0
    /// 基准档：起头一个大数字 + 三四行，或者一张小图配图例。宽壳 bento 卡就是按这一档设计的。
    ///
    /// 出现在：
    /// - 宽壳 bento 卡（定高 240）
    /// - iPad / Mac 侧栏卡（封顶 260）
    /// - 分享卡的模块卡（照着 bento 卡那张脸）
    case regular = 1
    /// 装得下长列表或者放大的图。
    ///
    /// 出现在：
    /// - widget systemLarge（约 322 内容高）
    case tall = 2
    /// 高度不封顶：手机 `List` 的行。内容有多长就多长，没人裁。
    case unbounded = 3

    /// 这一档从多高起算。`unbounded` 没有数值。
    public var minContentHeight: CGFloat? {
        switch self {
        case .tight: 0
        case .regular: 180
        case .tall: 320
        case .unbounded: nil
        }
    }

    /// 走卡版式吗：起头一个大数字（定高卡靠它对齐第一行）、图表小一号、列表只列前几行。
    /// 只有不封顶的那一档不走——它是模块的老家，手机列表。
    public var prefersCardMetrics: Bool { self != .unbounded }

    /// 一个内容高落在哪一档。容器算好高度调这里，别在模块里调。
    public static func bucket(forContentHeight height: CGFloat) -> ModuleHeight {
        allCases
            .compactMap { bucket in bucket.minContentHeight.map { ($0, bucket) } }
            .last { height >= $0.0 }?.1 ?? .tight
    }

    public static func < (lhs: ModuleHeight, rhs: ModuleHeight) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
