import SwiftUI
import MeterDesign

/// 大数字旁边的口径切换：合计（含订阅）/ 按量。
///
/// 两段都只给一个词，不写「含订阅 / 仅按量」：这颗要和 34pt 的金额同排，
/// 长一点的词在英日下能把胶囊撑到 ~190pt，四位数金额就把它挤到下一行去了
/// （「含订阅 / 仅按量」133pt、「Incl. subs / Variable only」198pt、
/// 「合计 / 按量」85pt、「Total / Usage」127pt）。口径本身还有下面那行
/// 订阅小字兜底（「本月订阅 $4 · 未计入」），VoiceOver 读的也是整句。
///
/// 做成**双段胶囊**而不是 Switch 或单颗按钮：
/// - Switch 是「设置」的语感，摆在金额旁边太重，而且关着的时候不自明；
/// - 单颗按钮只能显示一种状态，读者分不清写的是「现状」还是「按了会怎样」；
/// - 双段两个口径都在场、选中的亮着，和筛选抽屉的月份 chip 同一族语言。
///
/// 点已选中的那段不做任何事——这是分段控件的语义，不是开关的语义。
/// VoiceOver 不读两段小字，整颗控件用系统 Toggle 的读法（见 representation）。
public struct SubscriptionScopeControl: View {
    public var includesSubscriptions: Bool
    public var onChange: (Bool) -> Void

    public init(includesSubscriptions: Bool, onChange: @escaping (Bool) -> Void) {
        self.includesSubscriptions = includesSubscriptions
        self.onChange = onChange
    }

    @Namespace private var thumbNamespace

    public var body: some View {
        HStack(spacing: 0) {
            segment(L("合计"), value: true)
            segment(L("按量"), value: false)
        }
        .padding(MeterSpacing.xxs)
        // 轨道先垫页面底色再上灰：`tertiarySystemFill` 是半透明的，
        // 猫从这颗控件底下经过时不能透出来。
        .background {
            ZStack {
                Capsule().fill(Color.meterGroupedBackground)
                Capsule().fill(Color.meterTertiarySystemFill)
            }
        }
        // 数字那一行本来就有 34pt 字高，垫到 minTap 不改变行高，只把竖向命中放宽。
        .frame(minHeight: MeterSpacing.minTap)
        .sensoryFeedback(.selection, trigger: includesSubscriptions)
        .accessibilityRepresentation {
            Toggle(
                L("算进固定订阅"),
                isOn: Binding(
                    get: { includesSubscriptions },
                    set: { onChange($0) }
                )
            )
        }
    }

    private func segment(_ title: LocalizedStringResource, value: Bool) -> some View {
        let isSelected = includesSubscriptions == value
        return Button {
            guard !isSelected else { return }
            withAnimation(DashboardMotion.number) {
                onChange(value)
            }
        } label: {
            Text(title)
                .font(MeterFont.footnote.weight(isSelected ? .semibold : .regular))
                // 选中态用主题色实底 + 白字，和筛选抽屉的月份 chip 同一族。
                // 「白色滑块」那套在暗色下和轨道几乎同色，辨认不出选中的是哪段。
                .foregroundStyle(isSelected ? Color.white : Color.meterSecondaryLabel)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, MeterSpacing.sm)
                .padding(.vertical, MeterSpacing.xxs + 2)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor)
                            .matchedGeometryEffect(id: "thumb", in: thumbNamespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    @Previewable @State var includes = true
    VStack(spacing: MeterSpacing.md) {
        SubscriptionScopeControl(includesSubscriptions: includes) { includes = $0 }
    }
    .padding()
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var includes = false
    SubscriptionScopeControl(includesSubscriptions: includes) { includes = $0 }
        .padding()
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}
