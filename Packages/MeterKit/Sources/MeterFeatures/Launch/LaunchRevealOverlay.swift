#if os(iOS)
import MeterDashboard
import MeterDesign
import SwiftUI

/// 冷启动时盖在最上面的启动画面。第一帧和 `LaunchScreen.storyboard` 一模一样（口袋全景贴底、
/// 和屏幕一样宽、最宽 `maxArtWidth`），然后口袋里的圆牌飞到构成图例对应那一家的色块上，
/// 猫和口袋沉下去，底色淡掉。时间线见 SPEC「启动画面与过渡」。
struct LaunchRevealOverlay: View {
    let reveal: LaunchReveal
    /// Preview 里停在静帧上看构图。
    var animates = true
    let onFinished: () -> Void

    /// 和故事板里 `pocket-w-max` 同一个数。
    static let maxArtWidth: CGFloat = 560

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted: Set<LaunchTokenKind> = []
    @State private var flying: Set<LaunchTokenKind> = []
    @State private var glyphGone: Set<LaunchTokenKind> = []
    @State private var landed: Set<LaunchTokenKind> = []
    @State private var flights: [LaunchTokenKind: LaunchSwatchRegistry.Swatch] = [:]
    @State private var sinking = false
    @State private var backgroundGone = false
    @State private var dismissed = false
    /// 覆盖层自己在 `.global` 里的框：落点在它外面就不飞。
    @State private var screenBounds: CGRect = .zero

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let art = min(size.width, Self.maxArtWidth)
            let origin = CGPoint(x: (size.width - art) / 2, y: size.height - art)
            let unit = art / LaunchPocketGeometry.canvas
            let global = proxy.frame(in: .global).origin
            ZStack(alignment: .topLeading) {
                Color("LaunchPocketBackground", bundle: .module)
                    .opacity(backgroundGone ? 0 : 1)
                ForEach(LaunchPocketGeometry.tokens) { token in
                    tokenView(token, origin: origin, unit: unit, global: global, sink: art * Self.sinkRatio)
                }
                Group {
                    Image("LaunchPocketCat", bundle: .module).resizable()
                    Image("LaunchPocketFront", bundle: .module).resizable()
                }
                .frame(width: art, height: art)
                .offset(x: origin.x, y: origin.y + (sinking ? art * Self.sinkRatio : 0))
                .opacity(sinking ? 0 : 1)
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { screenBounds = $0 }
        .environment(\.colorScheme, reveal.systemColorScheme)
        .opacity(dismissed ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await run() }
    }

    /// 猫和口袋往下沉多少（画面宽的比例）。
    private static let sinkRatio: CGFloat = 0.28
    private static let lift: CGFloat = 14

    private func tokenView(
        _ token: LaunchPocketToken,
        origin: CGPoint,
        unit: CGFloat,
        global: CGPoint,
        sink: CGFloat
    ) -> some View {
        let kind = token.kind
        let target = flights[kind]
        let (center, size) = placement(token, origin: origin, unit: unit, global: global, sink: sink)
        return ZStack {
            Circle()
                .fill(target?.color ?? .clear)
                .opacity(glyphGone.contains(kind) ? 1 : 0)
            Image("LaunchPocketToken-\(kind.rawValue)", bundle: .module)
                .resizable()
                .opacity(glyphGone.contains(kind) ? 0 : 1)
        }
        .frame(width: size, height: size)
        .position(center)
        .opacity(landed.contains(kind) || (target == nil && sinking) ? 0 : 1)
    }

    /// 圆牌此刻的中心和直径：没起飞时在口袋里（弹起时上移、没落点时跟着口袋下沉），起飞后就是色块。
    private func placement(
        _ token: LaunchPocketToken,
        origin: CGPoint,
        unit: CGFloat,
        global: CGPoint,
        sink: CGFloat
    ) -> (CGPoint, CGFloat) {
        let kind = token.kind
        let target = flights[kind]
        if let target, flying.contains(kind) {
            return (CGPoint(x: target.frame.midX - global.x, y: target.frame.midY - global.y), target.frame.width)
        }
        let isLifted = lifted.contains(kind)
        let rest = CGPoint(x: origin.x + token.x * unit, y: origin.y + token.y * unit)
        let dy = (isLifted ? -Self.lift : 0) + (target == nil && sinking ? sink : 0)
        return (CGPoint(x: rest.x, y: rest.y + dy), token.radius * 2 * unit * (isLifted ? 1.08 : 1))
    }

    private func run() async {
        guard animates else { return }
        // 先原样停着：App 第一帧出来后，系统还要用约 0.25 秒把启动画面快照淡掉。
        // 这层和快照一模一样，停着不动就看不出交接；这时候就动，快照会叠出一只重影猫。
        try? await Task.sleep(for: .milliseconds(350))
        if reduceMotion {
            await fadeOut()
            return
        }
        // 等仪表盘的数和色块都到位；等不到就不等了，圆牌跟着口袋沉下去。
        let deadline = ContinuousClock.now + .milliseconds(700)
        while ContinuousClock.now < deadline, !isReady {
            try? await Task.sleep(for: .milliseconds(30))
        }
        guard reveal.showsDashboard else {
            await fadeOut()
            return
        }
        // 再等一帧，让同一张卡上其余的色块也报完。
        try? await Task.sleep(for: .milliseconds(32))
        // 落点得在屏幕里：滚到下面去的那一段飞过去没意义，跟着口袋沉下去。
        var planned: [LaunchTokenKind: LaunchSwatchRegistry.Swatch] = [:]
        for (kind, id) in reveal.targets {
            if let swatch = reveal.registry.swatches[id], screenBounds.contains(CGPoint(x: swatch.frame.midX, y: swatch.frame.midY)) {
                planned[kind] = swatch
            }
        }
        flights = planned
        reveal.registry.hidden = Set(planned.keys.compactMap { reveal.targets[$0] })
        await play(timeline(flyers: LaunchPocketGeometry.tokens.map(\.kind).filter { planned[$0] != nil }))
        onFinished()
    }

    /// 有一颗色块报上来就说明构成卡片排好了；滚到屏幕外的那几段可能根本不排，不能等它们。
    private var isReady: Bool {
        guard reveal.showsDashboard else { return false }
        return reveal.targets.isEmpty || reveal.targets.values.contains { reveal.registry.swatches[$0] != nil }
    }

    /// 一条按毫秒排好的时间线。圆牌依次错开 50 ms：弹出口袋（前 20%），再顺着 iOS 的减速曲线
    /// 落到色块上，路上图案淡掉、换成色块的颜色。同时猫和口袋沉下去，底色淡掉。
    private func timeline(flyers: [LaunchTokenKind]) -> [(at: Int, run: () -> Void)] {
        var events: [(at: Int, run: () -> Void)] = [
            (0, { withAnimation(.timingCurve(0.3, 0, 0.8, 0.15, duration: 0.32)) { sinking = true } }),
            (110, { withAnimation(.easeOut(duration: 0.36)) { backgroundGone = true } }),
            (470, {}),
        ]
        for (index, kind) in flyers.enumerated() {
            let start = 50 * index
            events.append((start, { withAnimation(.easeOut(duration: 0.124)) { _ = lifted.insert(kind) } }))
            events.append((start + 124, { withAnimation(.timingCurve(0.32, 0.72, 0, 1, duration: 0.496)) { _ = flying.insert(kind) } }))
            events.append((start + 244, { withAnimation(.easeOut(duration: 0.2)) { _ = glyphGone.insert(kind) } }))
            events.append((start + 620, {
                _ = landed.insert(kind)
                if let id = reveal.targets[kind] {
                    reveal.registry.hidden.remove(id)
                }
            }))
        }
        return events.sorted { $0.at < $1.at }
    }

    private func play(_ events: [(at: Int, run: () -> Void)]) async {
        var now = 0
        for event in events {
            if event.at > now {
                try? await Task.sleep(for: .milliseconds(event.at - now))
                now = event.at
            }
            event.run()
        }
    }

    private func fadeOut() async {
        withAnimation(.easeOut(duration: 0.25)) { dismissed = true }
        try? await Task.sleep(for: .milliseconds(260))
        onFinished()
    }
}

#Preview("Light") {
    LaunchRevealPreviewHost()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LaunchRevealPreviewHost()
        .preferredColorScheme(.dark)
}

/// Preview 里 `makeForFirstScene` 故意返回 nil（根界面预览不要被挡），这里直接造一份静帧。
private struct LaunchRevealPreviewHost: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LaunchRevealOverlay(reveal: LaunchReveal(systemColorScheme: colorScheme), animates: false) {}
    }
}

#endif
