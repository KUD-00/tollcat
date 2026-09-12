import SwiftUI
import MeterDesign

/// 开场第 2 页：没有 Keychain 那一屏，用三枚符号讲清事实。
struct OnboardingKeychainPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.md) {
            fact(symbol: "lock.iphone", title: L("只在这台设备"))
            fact(symbol: "icloud.slash", title: L("不进 iCloud"))
            fact(symbol: "archivebox", title: L("不跟备份走"))
        }
        .padding(MeterSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private func fact(symbol: String, title: LocalizedStringResource) -> some View {
        Label {
            Text(title)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
        } icon: {
            Image(systemName: symbol)
                .font(MeterFont.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: MeterSpacing.minTap, alignment: .center)
                .accessibilityHidden(true)
        }
        .labelStyle(.titleAndIcon)
    }
}

#Preview("Light") {
    OnboardingKeychainPreview()
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingKeychainPreview()
        .padding(MeterSpacing.pageHorizontal)
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}