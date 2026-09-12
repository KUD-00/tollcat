import SwiftUI
import MeterDesign

/// 服务页一家都没接的空态。
///
/// 之前这块是塞在 `List` 的一个 `Section` 里的 `ContentUnavailableView`：
/// 它只能在那一行的容器里居中，于是挤在大标题底下，卡片下沿还留出一大块死白，
/// 底下三分之二整屏空着。空态要撑满整屏才居中得起来——所以这里**替换掉整个
/// `List`**，而不是当成列表里的一行。
///
/// 文案上刻意和仪表盘那个空态区分开。仪表盘说「还没有账单」、按钮是
/// 「添加第一个服务」；这一屏只说「还没有接入服务」，按钮是「添加服务」。
/// 两屏长得几乎一样的话，用户会以为自己没跳成功。
struct ServicesEmptyView: View {
    var onAdd: () -> Void

    var body: some View {
        CatEmptyState(
            mood: .normal,
            title: L("还没有接入服务"),
            description: nil,
            actionTitle: L("添加服务"),
            action: onAdd,
            identifier: UITestID.servicesEmpty,
            actionIdentifier: UITestID.servicesEmptyAdd
        )
    }
}

#Preview("Light") {
    NavigationStack {
        ServicesEmptyView(onAdd: {})
            .navigationTitle(L("服务"))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ServicesEmptyView(onAdd: {})
            .navigationTitle(L("服务"))
    }
    .preferredColorScheme(.dark)
}
