import SwiftUI
import MeterDesign

/// 「保存到 Keychain」下面那行说明。讲人话，让人敢把 key 填进来。
/// 抽屉自己已经是一层表面，正文直接铺在上面，不再套 insetGrouped 的灰底卡片。
/// 标题走系统导航栏，坐进 sheet 顶部的玻璃里，不跟正文抢同一栏。
struct KeychainExplainerSheet: View {
    @Environment(\.usesPadChrome) private var usesPadChrome
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0
    @State private var chromeHeight: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                explainer
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            } action: { chromeHeight = $0 }
            .meterSheetTitle(Text(L("什么是 Keychain？")))
            // iPhone 靠下滑关；Mac 的 sheet 没有下滑，右下要有「完成」。
            .meterSheetClose { dismiss() }
        }
        .meterDrawerChrome(
            .compact(contentHeight + chromeHeight),
            usesPadChrome: usesPadChrome
        )
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.md) {
            Text(L("Keychain 是这台设备自带的加密钥匙串。你填进来的密钥由系统保管，不会写进这个 App 自己的文件里。"))
            Text(L("我们只用最严的一档：只在这台设备上、只有你解锁之后才能读。它不会同步到 iCloud，也不会跟着备份出现在别的手机上。"))
            Text(L("你在服务页删掉这家接入时，对应的钥匙会一起删掉，不会留在这台设备上。"))
        }
        .font(MeterFont.body)
        .foregroundStyle(Color.meterLabel)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, MeterSpacing.pageHorizontal)
        .padding(.top, MeterSpacing.sm)
        // 系统圆角会切进底部，要比标题那一侧多留一点。
        .padding(.bottom, MeterSpacing.xl)
        .frame(maxWidth: usesPadChrome ? MeterSpacing.readableMeasure : .infinity, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            KeychainExplainerSheet()
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            KeychainExplainerSheet()
        }
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            KeychainExplainerSheet()
        }
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            KeychainExplainerSheet()
        }
        .environment(\.meterShell, .pad)
}
