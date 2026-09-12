import SwiftUI
import MeterDesign

/// Mac 分栏 detail 列里的手工推入栈。
///
/// macOS 26 上系统 `NavigationStack` 在 split 的 detail 里一 push 就会被
/// 提级接管整个 detail 区——中列和列头一起卸载，返回钮跑进窗口工具栏。
/// 所以 Mac 的列内换页不走系统栈：目的地存在这里，平移过渡对齐
/// iPhone / iPad 的推入，标题和返回由 `meterMacColumnBar` 接管。
@MainActor
@Observable
final class MacColumnStackModel {
    struct Hop: Identifiable {
        let id = UUID()
        var title: Text
        /// 推入方给的路线标记（`ServicesRoute` 之类），用来回答「栈里有没有添加页」。
        var tag: AnyHashable?
        var content: AnyView
    }

    enum Direction {
        case forward
        case backward
    }

    private(set) var hops: [Hop] = []
    private(set) var direction: Direction = .forward

    var topTitle: Text? { hops.last?.title }
    var canPop: Bool { !hops.isEmpty }

    func push(title: Text, tag: AnyHashable? = nil, destination: some View) {
        direction = .forward
        hops.append(Hop(title: title, tag: tag, content: AnyView(destination)))
    }

    func contains(tag: some Hashable) -> Bool {
        hops.contains { $0.tag == AnyHashable(tag) }
    }

    func pop() {
        guard !hops.isEmpty else { return }
        direction = .backward
        hops.removeLast()
    }

    func popToRoot() {
        guard !hops.isEmpty else { return }
        direction = .backward
        hops.removeAll()
    }
}

extension EnvironmentValues {
    /// 所在 Mac 列的手工栈。iPhone / iPad 上是 nil，
    /// `MeterColumnLink` 据此回落到系统 `NavigationLink`。
    @Entry var macColumnStack: MacColumnStackModel?
}

/// 列的内容容器：无推入时显示 root，推入后显示栈顶，平移过渡。
struct MacColumnStack<Root: View>: View {
    var model: MacColumnStackModel
    @ViewBuilder var root: () -> Root

    var body: some View {
        ZStack {
            if let top = model.hops.last {
                top.content
                    .id(top.id)
                    .transition(pageTransition)
            } else {
                root()
                    .transition(pageTransition)
            }
        }
        .animation(.snappy(duration: 0.28), value: model.hops.last?.id)
        .clipped()
        .environment(\.macColumnStack, model)
    }

    private var pageTransition: AnyTransition {
        switch model.direction {
        case .forward:
            .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .backward:
            .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        }
    }
}

/// 列表行的推入链接，代替裸 `NavigationLink`。iPhone / iPad 走系统栈
/// （value 交给 `navigationDestination` 解析）；Mac 列里推手工栈。
/// 列里新增会推页的行一律用它，别再写裸 `NavigationLink`——那会整区接管。
struct MeterColumnLink<Value: Hashable, Destination: View, Label: View>: View {
    var value: Value
    var title: Text
    @ViewBuilder var destination: () -> Destination
    @ViewBuilder var label: () -> Label
    @Environment(\.macColumnStack) private var macStack

    var body: some View {
        if let macStack {
            Button {
                macStack.push(title: title, tag: AnyHashable(value), destination: destination())
            } label: {
                MacColumnLinkRow(label: label)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: value, label: label)
        }
    }
}

/// 目的地写在链接点上的变体（原来 `NavigationLink { … } label: { … }` 的那类）。
struct MeterColumnPushLink<Destination: View, Label: View>: View {
    var title: Text
    @ViewBuilder var destination: () -> Destination
    @ViewBuilder var label: () -> Label
    @Environment(\.macColumnStack) private var macStack

    var body: some View {
        if let macStack {
            Button {
                macStack.push(title: title, destination: destination())
            } label: {
                MacColumnLinkRow(label: label)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(destination: destination(), label: label)
        }
    }
}

/// Mac 上手工行的外观：文字 + 右侧 chevron，热区拉满，对齐系统行。
struct MacColumnLinkRow<Label: View>: View {
    @ViewBuilder var label: () -> Label

    var body: some View {
        HStack(spacing: MeterSpacing.sm) {
            label()
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(MeterFont.footnote.weight(.semibold))
                .foregroundStyle(Color.meterTertiaryLabel)
                .accessibilityHidden(true)
        }
        .meterListRowHitTarget()
        .contentShape(Rectangle())
        // 这一行的 chevron 和热区已经在这里了：里面的模块行别再画第二颗。
        .environment(\.moduleRowChromeFromLink, true)
    }
}

#Preview("Light") {
    @Previewable @State var model = MacColumnStackModel()
    MacColumnStack(model: model) {
        List {
            MeterColumnPushLink(title: Text("详情")) {
                Text("推进来的一页")
            } label: {
                Text("推一页")
            }
        }
    }
    .frame(width: 360, height: 240)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = MacColumnStackModel()
    MacColumnStack(model: model) {
        List {
            MeterColumnPushLink(title: Text("详情")) {
                Text("推进来的一页")
            } label: {
                Text("推一页")
            }
        }
    }
    .frame(width: 360, height: 240)
    .preferredColorScheme(.dark)
}
