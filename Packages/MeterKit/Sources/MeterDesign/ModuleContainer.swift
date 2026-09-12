import SwiftUI

/// 模块所在的容器：**chrome 与交互**。chevron 谁画、行高谁补、能不能点。
///
/// 和宽度档（`ModuleWidth`）、高度档（`ModuleHeight`，两者都从
/// `shared/module-size.json` 生成）是三根**正交**的轴，一起决定同一个模块视图
/// 在 iPhone 列表 / bento 卡 / 侧栏卡 / 分享卡 / widget 里的版式。
///
/// 它**不管尺寸**：「有没有高度预算」是 `ModuleHeight.prefersCardMetrics` 的事。
/// 一度让这个枚举兼职过高度预算，widget 一来就露馅了——systemMedium 和 systemLarge
/// 都是 `.snapshot`，高度却差 2.5 倍。
///
/// 为什么容器不能和尺寸合成一根：`systemLarge` 的 widget 很宽也很高，但它没有 `List`、
/// 也点不进任何一行。一根 bool（「在不在卡里」）表达不了，再多一个壳就得再加一个 case。
public enum ModuleContainer: Sendable {
    /// 系统 `List` 的一行。高度不封顶，chevron、行高、热区都由 List 补。
    case listRow
    /// 自绘卡：宽壳 bento、iPad/Mac 侧栏。定高会裁，行修饰得自己画。
    case card
    /// 渲成一帧图：分享卡、widget。点不动，所以不画任何「能点」的线索。
    case snapshot

    /// 行的 chevron / 行高 / 热区由容器补吗？只有 `List` 补。
    public var suppliesRowChrome: Bool { self == .listRow }

    /// chevron 自己画吗？卡里要（没有 List 那层）；图上不画——点不动的箭头是假线索。
    public var drawsOwnChevron: Bool { self == .card }

    /// 点得动吗？「查看更多」这类只有能点才成立的行照这个收。
    public var isInteractive: Bool { self != .snapshot }

}

public extension EnvironmentValues {
    /// 模块拿到的宽度档。默认 `.regular`：绝大多数壳都在这一档，
    /// 预览和组件库里不声明也能画对。
    @Entry var moduleWidth: ModuleWidth = .regular
    /// 模块拿到的高度档。默认 `.unbounded`：手机列表的行不封顶。
    @Entry var moduleHeight: ModuleHeight = .unbounded
    /// 模块所在的容器。默认 `.listRow`：手机列表是模块的老家，行修饰交给 List。
    @Entry var moduleContainer: ModuleContainer = .listRow

    /// 外面那层链接壳已经把 chevron 和热区补上了（Mac 列里的手工行）。
    ///
    /// 这不是第三根轴，是 `.listRow` 的另一种来源：容器仍然是卡，但行修饰有人补了，
    /// 再自己画一颗就成了一行两颗箭头。由链接壳自己声明，模块只读。
    @Entry var moduleRowChromeFromLink: Bool = false
}

public extension View {
    /// 容器给里面的模块声明版式档。**三根轴一起给**，别只给一两根——
    /// 少给的那根会拿默认值，读起来像声明过，其实没有。
    ///
    /// 尺寸传的是模块实际拿到的**内容尺寸**：容器自己的内边距先扣掉再算档
    /// （`ModuleWidth.bucket(forContentWidth:)` / `ModuleHeight.bucket(forContentHeight:)`）。
    /// 模块一律不许自己量——量自身尺寸再回填是个布局反馈环，会转死主线程。
    func meterModuleStyle(
        width: ModuleWidth,
        height: ModuleHeight,
        container: ModuleContainer
    ) -> some View {
        modifier(MeterModuleStyle(width: width, height: height, container: container))
    }
}

private struct MeterModuleStyle: ViewModifier {
    var width: ModuleWidth
    var height: ModuleHeight
    var container: ModuleContainer

    /// 外面已经在渲图了就一直是渲图。`.snapshot` 只会把这个开关**打开**，
    /// 不会关掉——分享卡里嵌一张 `.card` 的模块不该把整张图变回「会动」。
    @Environment(\.meterStaticRender) private var inheritedStaticRender

    func body(content: Content) -> some View {
        content
            .environment(\.moduleWidth, width)
            .environment(\.moduleHeight, height)
            .environment(\.moduleContainer, container)
            .environment(\.meterStaticRender, inheritedStaticRender || container == .snapshot)
    }
}
