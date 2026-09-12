import SwiftUI

/// 设置 → 读数信箱，还没建过时的空态。
///
/// 不能塞进 `List` 的 Section：那一行撑不开，图标和标题会顶在大标题底下，
/// 底下整屏空着。和仪表 / 服务一样，整页换成 `ContentUnavailableView`。
struct InboxEmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label(L("还没有信箱"), systemImage: "tray")
        } description: {
            Text(L("接入 Render、Expo 或 Clerk 这类没有公开账单接口的服务时，会自动为你建一个。"))
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview("Light") {
    NavigationStack {
        InboxEmptyView()
            .navigationTitle(L("读数信箱"))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        InboxEmptyView()
            .navigationTitle(L("读数信箱"))
    }
    .preferredColorScheme(.dark)
}
