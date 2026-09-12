import SwiftUI

/// 关掉 sheet 的那颗钮。iOS 用系统 X（`Button(role: .close)`），进导航栏。
///
/// Mac 的 sheet 没有导航栏，系统会把这颗 toolbar item 甩到底部另起一条 bar，
/// 和主按钮叠成两层、中间空一大截。所以 Mac 上它不进 toolbar：有主操作底栏
/// 的面，它变成底栏左边那颗「取消」（Esc）；没有底栏的面（分享卡）自己在
/// 右下画一颗「完成」。
///
/// Features 里关 sheet 一律走这里，不要直接写 `Button(role: .close)`——
/// `SheetCloseGuardrailTests` 和 `scripts/check-source-invariants.py` 两边都扫。
public struct MeterSheetClose: ViewModifier {
    var isActive: Bool
    var action: () -> Void
    @Environment(\.meterSheetCloseHosted) private var hosted

    public init(isActive: Bool = true, action: @escaping () -> Void) {
        self.isActive = isActive
        self.action = action
    }

    public func body(content: Content) -> some View {
        #if os(macOS)
        if !isActive {
            content
        } else if hosted {
            content.preference(key: MeterSheetClosePreference.self, value: MeterSheetCloseHandler(run: action))
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    Button(action: action) {
                        Text(L("完成"))
                    }
                    .keyboardShortcut(.cancelAction)
                }
                .controlSize(.large)
                .padding(.horizontal, MeterSpacing.pageHorizontal)
                .padding(.top, MeterSpacing.sm)
                .padding(.bottom, MeterSpacing.pageHorizontal)
                .background(Color.meterGroupedBackground)
            }
        }
        #else
        content.toolbar {
            if isActive {
                Button(role: .close, action: action)
            }
        }
        #endif
    }
}

public extension View {
    func meterSheetClose(isActive: Bool = true, _ action: @escaping () -> Void) -> some View {
        modifier(MeterSheetClose(isActive: isActive, action: action))
    }
}

/// 关闭动作往上报给 `meterPrimaryActionBar`。闭包不可比较，
/// 只比「有没有」——有了就画那颗取消，不因每次 body 重建再触发一次。
public struct MeterSheetCloseHandler: Equatable, @unchecked Sendable {
    public let run: () -> Void

    public init(run: @escaping () -> Void) {
        self.run = run
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { true }
}

public struct MeterSheetClosePreference: PreferenceKey {
    public static let defaultValue: MeterSheetCloseHandler? = nil

    public static func reduce(value: inout MeterSheetCloseHandler?, nextValue: () -> MeterSheetCloseHandler?) {
        value = nextValue() ?? value
    }
}

public extension EnvironmentValues {
    /// `meterPrimaryActionBar` 在 Mac 弹出面里打开：告诉里面的
    /// `meterSheetClose` 「取消」由底栏来画，别再自己另起一行。
    @Entry var meterSheetCloseHosted: Bool = false
}
