import SwiftUI
import MeterDesign

/// 写在对应行里面的注解。不要用 Section footer 扛这件事——
/// footer 在卡片外面，读起来像整组的说明。
struct ListRowNote: View {
    var text: LocalizedStringResource

    var body: some View {
        Text(text)
            .font(MeterFont.footnote)
            .foregroundStyle(Color.meterSecondaryLabel)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Light") {
    MeterGroupedList {
        Toggle(isOn: .constant(true)) {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(L("关闭猫猫"))
                ListRowNote(text: L("仪表上不再出现猫。数字和构成还在。"))
            }
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    MeterGroupedList {
        Toggle(isOn: .constant(true)) {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text(L("关闭猫猫"))
                ListRowNote(text: L("仪表上不再出现猫。数字和构成还在。"))
            }
        }
    }
    .preferredColorScheme(.dark)
}
