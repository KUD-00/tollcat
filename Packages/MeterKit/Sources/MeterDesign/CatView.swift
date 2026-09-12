import SwiftUI

/// TollCat。路径内联自 `docs/assets/tollcat.svg`。`isAnimated: false` 给 Widget。
public struct CatView: View {
    private let parts: CatParts
    private let size: CGFloat
    private let isAnimated: Bool
    private let motion: CatMotionKind
    private let pose: CatMotionFrame
    private let ears: CatEarMotion
    private let accessibilityLabel: LocalizedStringResource

    public init(mood: CatMood, size: CGFloat, isAnimated: Bool = true) {
        self.init(
            parts: mood.parts,
            size: size,
            accessibilityLabel: mood.accessibilityLabel,
            isAnimated: isAnimated,
            motion: mood.motion,
            pose: .still(for: mood)
        )
    }

    /// 按图层和姿势拼一只猫。生产界面走命名表情。
    public init(
        parts: CatParts,
        size: CGFloat,
        accessibilityLabel: LocalizedStringResource,
        isAnimated: Bool = false,
        motion: CatMotionKind = .idle,
        pose: CatMotionFrame = CatMotionFrame(),
        ears: CatEarMotion = .still
    ) {
        self.parts = parts
        self.size = size
        self.isAnimated = isAnimated
        self.motion = motion
        self.pose = pose
        self.ears = ears
        self.accessibilityLabel = accessibilityLabel
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        Group {
            if isAnimated && !reduceMotion && motion != .still {
                // 一个时间源驱动整只猫。换图层时再叠一次眨眼，在眼缝最窄处切脸。
                LiveCatPortrait(parts: parts, motion: motion, ears: ears, size: size)
            } else {
                CatPortrait(parts: parts, frame: pose, size: size)
            }
        }
        .frame(width: size, height: size)
        // 摆尾 / ZZZ / 吓到拉长会超出 viewBox，给列表圆角留一点，避免左耳被剃。
        .padding(.horizontal, size * 0.10)
        .padding(.top, size * 0.06)
        // viewBox 底部到剪影底边之间恒定是空的（1024 里的 196，尾巴也只到 708）。
        // 上面那块要留给 ZZZ / 惊叹号 / 骷髅，下面这块任何表情都用不到，
        // 留着就是让猫在行里浮着。吓到拉长以底边为锚，也不会往下溢。
        .padding(.bottom, -size * 0.14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// 循环姿势是时间的纯函数；换脸是一次覆盖眨眼，也由同一只时钟取样。
private struct LiveCatPortrait: View {
    var parts: CatParts
    var motion: CatMotionKind
    var ears: CatEarMotion
    var size: CGFloat

    @State private var cover: Cover?
    /// 猫常驻仪表盘，`.animation` 是跟着刷新率走的每帧采样。
    /// 退到后台 / 应用切换器里没人看它，把时间源停掉，别让它空转耗电。
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: scenePhase != .active)) { context in
            let now = context.date.timeIntervalSinceReferenceDate
            CatPortrait(parts: visibleParts(at: now), frame: motionFrame(at: now), size: size)
        }
        .onChange(of: parts) { old, new in
            guard old != new else { return }
            let now = Date.timeIntervalSinceReferenceDate
            cover = Cover(from: drawingParts(at: now, parent: old), to: new, start: now)
        }
    }

    private func motionFrame(at now: TimeInterval) -> CatMotionFrame {
        var sampled = CatMotion.frame(for: motion, at: now)
        if ears == .twitch {
            CatMotion.applyEars(&sampled, at: now)
        }
        if let cover {
            sampled.blink = max(sampled.blink, CatMotion.coverBlink(elapsed: now - cover.start))
        }
        return sampled
    }

    private func visibleParts(at now: TimeInterval) -> CatParts {
        drawingParts(at: now, parent: parts)
    }

    private func drawingParts(at now: TimeInterval, parent: CatParts) -> CatParts {
        guard let cover else { return parent }
        if now - cover.start < CatMotion.coverSwapElapsed {
            return cover.from
        }
        return cover.to
    }

    private struct Cover {
        var from: CatParts
        var to: CatParts
        var start: TimeInterval
    }
}

#Preview("Light") {
    CatPreviewGrid()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CatPreviewGrid()
        .preferredColorScheme(.dark)
}

#Preview("Static") {
    CatPreviewGrid(isAnimated: false)
}

private struct CatPreviewGrid: View {
    var isAnimated = true

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MeterSpacing.lg) {
                ForEach(CatMood.allCases, id: \.self) { mood in
                    VStack(spacing: MeterSpacing.xs) {
                        CatView(mood: mood, size: MeterSpacing.catGallery, isAnimated: isAnimated)
                        Text(mood.rawValue)
                            .font(MeterFont.caption)
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                }
            }
            .padding(MeterSpacing.pageHorizontal)
        }
        .background(Color.meterGroupedBackground)
    }
}
