import SwiftUI

/// 设置这种分组页。iOS 走 insetGrouped `List`；Mac 没有这种 style，
/// `.inset` 是密表，系统设置用的是 grouped `Form`。
public struct MeterGroupedList<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        #if os(macOS)
        Form {
            content
        }
        .formStyle(.grouped)
        // 行里的裸按钮压成 iOS 那种「一行字」，不要 NSButton 凸起。
        .meterGroupedRowButtons()
        // section 卡换成和仪表盘模块同一张卡面：系统那张只会比画布更暗。
        .meterGroupedSectionCard()
        // Mac 的 grouped Form 自己铺一层系统画布（深色是 #282828 那档灰），
        // 和列头 bar 的 `meterGroupedBackground`（#1E1E1E）拼成两截。
        // iOS 的画布恰好就是 token 同一个色，从来露不出馅。
        .scrollContentBackground(.hidden)
        .background(Color.meterGroupedBackground)
        #else
        List {
            content
        }
        .listStyle(.insetGrouped)
        #endif
    }
}

#Preview("Light") {
    NavigationStack {
        MeterGroupedList {
            Section {
                Toggle("Preview toggle", isOn: .constant(true))
            } header: {
                Text("General")
            }
        }
        .navigationTitle("Settings")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        MeterGroupedList {
            Section {
                Toggle("Preview toggle", isOn: .constant(true))
            } header: {
                Text("General")
            }
        }
        .navigationTitle("Settings")
    }
    .preferredColorScheme(.dark)
}
