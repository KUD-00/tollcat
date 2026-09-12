import SwiftUI

private struct MeterStaticRenderKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// 这一份视图正在被渲成静态图片（分享卡），不是给人点的界面。
    ///
    /// `ImageRenderer` 只渲一帧：`onAppear` / `task` 不跑，所以任何「进场从 0 转到 1」
    /// 的动画在图上就是空的（圆环渲成一圈白）。同一个开关顺带把只有能点才有意义的
    /// 装饰收掉——chevron、翻月箭头、「查看更多」在一张图上是假线索。
    var meterStaticRender: Bool {
        get { self[MeterStaticRenderKey.self] }
        set { self[MeterStaticRenderKey.self] = newValue }
    }
}
