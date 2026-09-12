import SwiftUI
import MeterDesign
import MeterProviders

/// 添加列表点一家时从底下弹出。只介绍这家是谁，不谈计费模式和支持。
struct AddProviderConfirmSheet: View {
    var descriptor: ProviderDescriptor
    var summary: String
    var onAdd: () -> Void

    /// 首帧几何还没到。从 0 起 detent 可能不布局，量不到真高度。
    @Environment(\.usesPadChrome) private var usesPadChrome
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat =
        MeterSpacing.providerGlyphLarge
        + MeterSpacing.lg
        + MeterSpacing.xxl

    var body: some View {
        ScrollView {
            confirmBody
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newHeight in
                    // 抽屉收矮之后会按更矮的提议再量一次，跟着缩会把主按钮切掉。
                    guard newHeight > contentHeight else { return }
                    contentHeight = newHeight
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        // iPhone 靠下滑关；这里没有导航栏，iOS 上什么都不画。Mac 的 sheet
        // 没有下滑，底栏左边要有「取消」。
        .meterSheetClose { dismiss() }
        .meterPrimaryActionBar {
            Button(action: onAdd) {
                Text(L("添加\(descriptor.displayName)"))
                    .frame(maxWidth: .infinity)
            }
            .meterPrimaryActionStyle()
            .accessibilityIdentifier(UITestID.addProviderConfirm)
        }
        .meterDrawerChrome(
            .compact(
                contentHeight
                    + MeterSpacing.primaryActionBarHeight
                    // Home Indicator 用 xl 就够。再加 xxl，说明和按钮之间会空一截。
                    + MeterSpacing.xl
            ),
            usesPadChrome: usesPadChrome
        )
    }

    private var confirmBody: some View {
        VStack(spacing: MeterSpacing.md) {
            ProviderGlyph(
                colorKey: descriptor.colorKey,
                size: MeterSpacing.providerGlyphLarge,
                accessibilityName: descriptor.displayName
            )
            if !summary.isEmpty {
                Text(summary)
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, MeterSpacing.lg)
        // 指示条下面再留一截，64pt 图标贴顶会顶到抓手。
        .padding(.top, MeterSpacing.xxl)
        // 底栏已经有 sm。md 会在说明和按钮之间空一截。
        .padding(.bottom, MeterSpacing.xs)
        .frame(maxWidth: MeterSpacing.readableMeasure)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddProviderConfirmSheet(
                descriptor: ProviderCatalog.openai,
                summary: "GPT 等模型的 API 平台。预充值，按 token 扣余额。",
                onAdd: {}
            )
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddProviderConfirmSheet(
                descriptor: ProviderCatalog.cloudflare,
                summary: "全球 CDN、DNS 和边缘计算。Workers、R2、D1 按用量月底结算。",
                onAdd: {}
            )
        }
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddProviderConfirmSheet(
                descriptor: ProviderCatalog.cloudflare,
                summary: "全球 CDN、DNS 和边缘计算。Workers、R2、D1 按用量月底结算。",
                onAdd: {}
            )
        }
        .dynamicTypeSize(.accessibility3)
}
