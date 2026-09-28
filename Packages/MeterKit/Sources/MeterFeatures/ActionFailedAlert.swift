import SwiftUI

/// 结束 / 删除 / 轮换这类操作现在会因为投递 key 没吊销掉而整体放弃（本地一点没动）。
/// 调用处以前 `try?` 吞掉错误，改成会失败之后必须让人看见，否则按了没反应。
struct ActionFailedAlert: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.alert(L("没有完成"), isPresented: $isPresented) {
            Button(L("知道了")) { isPresented = false }
        } message: {
            Text(L("这次没能联系上信箱，所以什么都没改。联网后再试一次。"))
        }
    }
}

extension View {
    func actionFailedAlert(isPresented: Binding<Bool>) -> some View {
        modifier(ActionFailedAlert(isPresented: isPresented))
    }
}
