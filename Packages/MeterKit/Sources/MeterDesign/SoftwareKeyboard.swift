import CoreGraphics

/// 软件键盘是不是真的盖住了屏幕。
///
/// 完成挂在 `placement: .keyboard` 上。外接键盘时系统仍会把这条工具栏
/// 贴在屏幕底——系统就是这么规定的。附件栏大约几十点高；软件键盘本体
/// 通常两百点以上。用盖住的高度区分，没软件键盘时把整条工具栏藏掉。
enum SoftwareKeyboard {
    static let minimumCover: CGFloat = 120
    /// 安全区跟着 sheet 高度抖的那几 pt。写进 detent 会循环布局。
    static let chromeJitter: CGFloat = 16

    static func isCoveringScreen(endFrame: CGRect, screen: CGRect) -> Bool {
        guard endFrame.height > minimumCover else { return false }
        let overlap = screen.intersection(endFrame).height
        if overlap > minimumCover { return true }
        return endFrame.minY < screen.maxY - minimumCover
    }

    /// 抽屉 detent 用的导航栏 + Home Indicator。键盘也在
    /// `safeAreaInsets.bottom` 里，一次加两百多点；写进 `.height`
    /// 抽屉会跟着长，底栏和列表再各让一次。
    ///
    /// 安全区本身跟着 sheet 高度变。差几pt 就改 detent，系统和我们互相喂，
    /// 会报 presentation preference cyclic layout。
    static func acceptedChromeHeight(current: CGFloat, proposed: CGFloat) -> CGFloat {
        guard proposed.isFinite, proposed > 0 else { return current }
        if proposed >= minimumCover * 2 { return current }
        if current <= 0 { return proposed }
        // 首帧占位是 Home Indicator 那一截，真正的导航栏还没量到。
        if current < minimumCover / 2 { return proposed }
        if abs(proposed - current) < chromeJitter { return current }
        if abs(proposed - current) < minimumCover { return proposed }
        return current
    }
}
