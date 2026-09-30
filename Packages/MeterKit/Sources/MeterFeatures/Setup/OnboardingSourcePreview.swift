import SwiftUI
import MeterDesign
import MeterProviders

/// 开场第 2 页：这台设备直接问各家官方接口。没有对应的屏，用设备符号和真服务图标画一张示意，
/// 中间不画任何「云」或服务器——那正是这一页要否认的东西。
struct OnboardingSourcePreview: View {
    var shell: MeterShell

    var body: some View {
        // 三段各按内容宽，空隙均分：设备、箭头、服务三者在卡里等距摆开，不让任何一段吃掉剩余宽度。
        HStack(alignment: .center, spacing: MeterSpacing.sm) {
            Spacer(minLength: 0)
            VStack(spacing: MeterSpacing.xs) {
                Image(systemName: deviceSymbol)
                    .font(MeterFont.largeTitle)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Text(L("这台设备"))
                    .font(MeterFont.footnote)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            Spacer(minLength: 0)
            VStack(spacing: MeterSpacing.xxs) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .accessibilityHidden(true)
                Text(L("只读"))
                    .font(MeterFont.caption)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: MeterSpacing.sm) {
                ForEach(rows, id: \.id) { descriptor in
                    HStack(spacing: MeterSpacing.sm) {
                        ProviderGlyph(colorKey: descriptor.colorKey)
                        Text(verbatim: descriptor.displayName)
                            .font(MeterFont.body)
                            .foregroundStyle(Color.meterLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
        }
        .padding(MeterSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private var deviceSymbol: String {
        switch shell {
        case .phone: "iphone"
        case .pad: "ipad.landscape"
        case .mac: "laptopcomputer"
        }
    }

    private var rows: [ProviderDescriptor] {
        OnboardingDemoContent.sourcePreviewIDs.compactMap { ProviderCatalog.descriptor(id: $0) }
    }
}

#Preview("Light") {
    OnboardingSourcePreview(shell: .phone)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingSourcePreview(shell: .mac)
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
