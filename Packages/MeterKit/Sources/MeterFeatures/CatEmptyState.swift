import SwiftUI
import MeterDesign

/// 仪表 / 服务共用的猫空态。
///
/// 系统 `ContentUnavailableView` 的 label、description、actions 各带一套间距。
/// 猫再塞进 label 的 `VStack`，四件套就会叠出三截对不上的 gap。
/// 整棵树放进 label，间距只走这一处 token。
struct CatEmptyState: View {
    var mood: CatMood
    var title: LocalizedStringResource
    var description: LocalizedStringResource?
    var actionTitle: LocalizedStringResource
    var action: () -> Void
    /// UI 冒烟锚点：整块空态一个，主按钮一个。两个空态（仪表 / 服务）文案几乎一样，
    /// 流程要靠 id 而不是靠字分辨自己落在哪一屏。
    var identifier: String
    var actionIdentifier: String

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: MeterSpacing.md) {
                CatView(mood: mood, size: MeterSpacing.catTip)
                Text(title)
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
                if let description {
                    Text(description)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
                Button(actionTitle, action: action)
                    .font(MeterFont.body)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(actionIdentifier)
            }
        }
        // 先把整块收成一个元素再挂 id。直接挂在非元素容器上，identifier 会铺给
        // 里面每个子元素，把按钮自己的 actionIdentifier 盖掉。
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

#Preview("Light") {
    CatEmptyState(
        mood: .sleeping,
        title: L("还没有账单"),
        description: L("接入第一家云服务之后，本月已经花了多少会显示在这里。"),
        actionTitle: L("添加第一个服务"),
        action: {},
        identifier: UITestID.dashboardEmpty,
        actionIdentifier: "preview.add"
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    CatEmptyState(
        mood: .sleeping,
        title: L("还没有账单"),
        description: L("接入第一家云服务之后，本月已经花了多少会显示在这里。"),
        actionTitle: L("添加第一个服务"),
        action: {},
        identifier: UITestID.dashboardEmpty,
        actionIdentifier: "preview.add"
    )
    .preferredColorScheme(.dark)
}
