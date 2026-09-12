import SwiftUI

/// 满宽主操作。外形跟 `meterPrimaryActionStyle()` 同一颗：大号、胶囊、tint。
/// 测试时系统绿从左到右盖住 tint，不转圈，也不把按钮洗成灰。
public struct FillProgressButton: View {
    private let title: String
    private let phase: FillProgressPhase
    private let isEnabled: Bool
    private let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheen: CGFloat = 0

    public init(
        _ title: String,
        phase: FillProgressPhase,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.phase = phase
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .frame(maxWidth: .infinity)
                .contentTransition(.interpolate)
        }
        .controlSize(.large)
        .buttonStyle(FillProgressButtonStyle(sheen: sheen, isEnabled: isEnabled))
        // 测的时候不能用 `.disabled`：系统会把整颗洗成灰，铺色就看不见了。
        .allowsHitTesting(isEnabled && phase != .progressing)
        .disabled(!isEnabled)
        .accessibilityValue(phase == .progressing ? Text(L("正在测试")) : Text(verbatim: ""))
        .accessibilityAddTraits(phase == .progressing ? .updatesFrequently : [])
        .task(id: phase) {
            await runSheen(for: phase)
        }
    }

    @MainActor
    private func runSheen(for phase: FillProgressPhase) async {
        switch phase {
        case .progressing:
            if reduceMotion {
                withAnimation(.snappy) { sheen = 1 }
                return
            }
            var snap = Transaction()
            snap.disablesAnimations = true
            withTransaction(snap) { sheen = 0 }
            withAnimation(.easeOut(duration: 1.15)) { sheen = 0.9 }
        case .completed:
            if reduceMotion {
                withAnimation(.snappy) { sheen = 0 }
                return
            }
            withAnimation(.snappy) { sheen = 1 }
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { sheen = 0 }
        case .idle:
            withAnimation(.snappy) { sheen = 0 }
        }
    }
}

private struct FillProgressButtonStyle: ButtonStyle {
    var sheen: CGFloat
    var isEnabled: Bool
    /// Mac 弹出面底栏：和旁边那颗「取消」同高、按文字收宽，不再是 50pt 满宽。
    @Environment(\.meterCompactPrimaryAction) private var compact

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, compact ? MeterSpacing.md : 0)
            .frame(
                maxWidth: compact ? nil : .infinity,
                minHeight: compact ? MeterSpacing.macDialogButton : MeterSpacing.primaryActionMinHeight
            )
            .foregroundStyle(isEnabled ? .white : Color.meterSecondaryLabel)
            .background {
                if isEnabled {
                    FillProgressTrack(sheen: sheen)
                } else {
                    Color.meterSystemGray3
                }
            }
            .clipShape(Capsule())
            .opacity(isEnabled && configuration.isPressed ? 0.82 : 1)
    }
}

private struct FillProgressTrack: View {
    var sheen: CGFloat

    var body: some View {
        Color.accentColor
            .overlay(alignment: .leading) {
                Color.green
                    .scaleEffect(x: sheen, y: 1, anchor: .leading)
                    .opacity(sheen > 0 ? 1 : 0)
            }
            .accessibilityHidden(true)
    }
}

#Preview("Disabled") {
    FillProgressButtonPreview(phase: .idle, isEnabled: false)
        .preferredColorScheme(.light)
}

#Preview("Idle · Light") {
    FillProgressButtonPreview(phase: .idle)
        .preferredColorScheme(.light)
}

#Preview("Idle · Dark") {
    FillProgressButtonPreview(phase: .idle)
        .preferredColorScheme(.dark)
}

#Preview("Progressing") {
    FillProgressButtonPreview(phase: .progressing)
}

#Preview("Completed") {
    FillProgressButtonPreview(phase: .completed, title: "保存到 Keychain")
}

#Preview("Interactive · Light") {
    FillProgressInteractivePreview()
        .preferredColorScheme(.light)
}

#Preview("Interactive · Dark") {
    FillProgressInteractivePreview()
        .preferredColorScheme(.dark)
}

private struct FillProgressButtonPreview: View {
    var phase: FillProgressPhase
    var title: String = "测试连接"
    var isEnabled: Bool = true

    var body: some View {
        VStack {
            FillProgressButton(title, phase: phase, isEnabled: isEnabled, action: {})
                .padding(.horizontal, MeterSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.meterGroupedBackground)
    }
}

private struct FillProgressInteractivePreview: View {
    @State private var phase: FillProgressPhase = .idle

    var body: some View {
        VStack(spacing: MeterSpacing.md) {
            FillProgressButton(
                phase == .completed ? "保存到 Keychain" : "测试连接",
                phase: phase,
                isEnabled: true
            ) {
                run()
            }
            Button(action: run) { Text(verbatim: "测一次") }
            Button(action: { phase = .idle }) { Text(verbatim: "重置") }
        }
        .padding(MeterSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.meterGroupedBackground)
    }

    private func run() {
        phase = .progressing
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            phase = .completed
        }
    }
}
