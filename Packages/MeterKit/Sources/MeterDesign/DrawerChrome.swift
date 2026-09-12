import SwiftUI

/// 有主按钮的抽屉共用外壳：分组灰底、抓手、同一套 detent。
///
/// 玻璃只给导航层。sheet 若留系统材料，Form 短内容底下会透出玻璃，
/// 和连接参考不像同一张抽屉。高度策略见 `DrawerHeight`。
///
/// 横屏 iPad 不用 detent：HIG 把 detent 标成 iPhone 机制，iPad 用居中
/// 的 form / page sheet。抓手也只给能拖档位的手机抽屉。
///
/// Features 里不要手写 `presentationDetents` / `presentationSizing` /
/// `presentationBackground`。`DrawerChromeGuardrailTests` 和
/// `scripts/check-source-invariants.py` 两边都扫。
public struct DrawerChrome: ViewModifier {
    var height: DrawerHeight
    var usesPadChrome: Bool

    public init(height: DrawerHeight, usesPadChrome: Bool) {
        self.height = height
        self.usesPadChrome = usesPadChrome
    }

    public func body(content: Content) -> some View {
        let sheet = content
            .presentationBackground(Color.meterGroupedBackground)
        if usesPadChrome {
            pad(sheet)
                .modifier(MacSheetSurface())
        } else {
            phone(sheet)
        }
    }

    @ViewBuilder
    private func pad(_ sheet: some View) -> some View {
        switch height {
        case .compact:
            // form 先定宽度，再贴高度。裸 `.fitted` 从 NavigationStack
            // 弹出时会按整页提议，添加确认踩过。
            sheet
                .presentationSizing(
                    .form
                        .fitted(horizontal: false, vertical: true)
                        .sticky(horizontal: false, vertical: true)
                )
                .presentationDragIndicator(.hidden)
        case .expandable:
            #if os(macOS)
            // Mac 的 sheet 没有拖手，按内容长高（窗口装不下再滚），
            // 不要一张固定 400pt 的窄条把商品档位切一半。
            sheet
                .presentationSizing(
                    .form
                        .fitted(horizontal: false, vertical: true)
                        .sticky(horizontal: false, vertical: true)
                )
                .presentationDragIndicator(.hidden)
            #else
            sheet
                .presentationSizing(.form)
                .presentationDragIndicator(.hidden)
            #endif
        case .large, .mediumLarge:
            sheet
                .presentationSizing(.form)
                .presentationDragIndicator(.hidden)
        case .page:
            sheet
                .presentationSizing(.page)
                .presentationDragIndicator(.hidden)
        case .fitted:
            // 对话框只占它要的那么大。里面的东西得报得出理想尺寸——
            // List / Form 报 0，别往这一档里放。
            sheet
                .presentationSizing(.fitted)
                .presentationDragIndicator(.hidden)
        }
    }

    @ViewBuilder
    private func phone(_ sheet: some View) -> some View {
        let sheet = sheet.presentationDragIndicator(.visible)
        switch height {
        case .compact:
            sheet
                .presentationDetents([.height(compactHeight)])
                .presentationContentInteraction(.scrolls)
        case .expandable(let measured):
            sheet
                .presentationDetents([.custom(FittedDrawerDetent.self), .large])
                .presentationContentInteraction(.scrolls)
                .onAppear { FittedDrawerDetent.adopt(measured) }
                .onChange(of: height) { _, newHeight in
                    if case .expandable(let value) = newHeight {
                        FittedDrawerDetent.adopt(value)
                    }
                }
                .onDisappear { FittedDrawerDetent.measuredHeight = 0 }
        case .large, .page, .fitted:
            // 手机没有「按内容收宽」这回事：sheet 一律满宽，收矮走 detent。
            sheet.presentationDetents([.large])
        case .mediumLarge:
            sheet
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
        }
    }

    private var compactHeight: CGFloat {
        if case .compact(let height) = height, height.isFinite, height > 0 {
            return height
        }
        return 1
    }
}

/// Mac 的 sheet：Form 自己铺的系统画布和 `presentationBackground` 拼成两截
/// （主区那套 `meterMacDetailCanvas` 不会跟进 sheet），这里藏掉；再把
/// 「弹出面」环境打开，标题 / 关闭 / 底栏切成 Mac 对话框版式。
private struct MacSheetSurface: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .scrollContentBackground(.hidden)
            .environment(\.meterInSheetSurface, true)
        #else
        content
        #endif
    }
}

public extension View {
    func meterDrawerChrome(_ height: DrawerHeight, usesPadChrome: Bool) -> some View {
        modifier(DrawerChrome(height: height, usesPadChrome: usesPadChrome))
    }

    /// iPad popover 里不要套 sheet 外壳（抓手、form / page sizing）。
    @ViewBuilder
    func meterPhoneDrawerChrome(_ height: DrawerHeight, usesPadChrome: Bool) -> some View {
        if usesPadChrome {
            self
        } else {
            modifier(DrawerChrome(height: height, usesPadChrome: false))
        }
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            Text(verbatim: "Drawer")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .meterDrawerChrome(.mediumLarge, usesPadChrome: false)
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            Text(verbatim: "Drawer")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .meterDrawerChrome(.mediumLarge, usesPadChrome: false)
        }
        .preferredColorScheme(.dark)
}

#Preview("Pad") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            Text(verbatim: "Drawer")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .meterDrawerChrome(.page, usesPadChrome: true)
        }
}
