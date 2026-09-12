import Charts
import SwiftUI

/// 可平移的日线图不能用 `chartXSelection` 的拖——它会把惯性平移吃掉。
/// 点一下对准那天；拖仍然归时间轴。
struct MeterChartDaySelection: ViewModifier {
    var isScrollable: Bool
    @Binding var selection: Date?

    func body(content: Content) -> some View {
        if isScrollable {
            content.chartGesture { proxy in
                SpatialTapGesture().onEnded { value in
                    selection = proxy.value(atX: value.location.x, as: Date.self)
                }
            }
        } else {
            content.chartXSelection(value: $selection)
        }
    }
}
