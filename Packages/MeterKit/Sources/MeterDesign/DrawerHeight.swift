import CoreGraphics

/// 抽屉高度。主按钮 Y 由 `meterPrimaryActionBar` 钉死，这里只决定 sheet 收多高。
///
/// iPhone 走 detent。横屏 iPad 走居中 form / page，映射在 `DrawerChrome.pad`。
///
/// - compact：按内容收矮，不能拉开。添加确认、Keychain 说明。
/// - expandable：按内容收矮，可拉到 large。加一笔订阅、手填用量。
/// - large：开满。筛选三节（仅手机；iPad 是 popover）。
/// - mediumLarge：利用指南一篇一篇弹，SPEC 写死 medium / large。
/// - page：iPhone 开满；iPad 用 page sheet。连接参考双栏。
/// - fitted：iPhone 开满；iPad / Mac 按内容的理想尺寸收（宽高都收）。分享卡。
///   里面的东西必须报得出理想尺寸——`List` / `Form` 的理想高是 0，会缩成一条横条。
public enum DrawerHeight: Equatable {
    case compact(CGFloat)
    case expandable(CGFloat)
    case large
    case mediumLarge
    case page
    case fitted
}
