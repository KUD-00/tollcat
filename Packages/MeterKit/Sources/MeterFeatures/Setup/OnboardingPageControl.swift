import SwiftUI
import MeterDesign
#if canImport(UIKit)
import UIKit
#endif

/// iPhone / iPad 用系统 `UIPageControl`。Mac 没有对应物，走一排可点的圆点。
struct OnboardingPageControl: View {
    var page: OnboardingPage
    var onChange: (OnboardingPage) -> Void

    var body: some View {
        #if os(macOS)
        HStack(spacing: MeterSpacing.xs) {
            ForEach(OnboardingPage.allCases) { item in
                Button {
                    onChange(item)
                } label: {
                    Circle()
                        .fill(item == page ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: L("第 \(item.displayNumber) 页，共 \(OnboardingPage.allCases.count) 页")))
            }
        }
        #else
        OnboardingPageControlUIKit(page: page, onChange: onChange)
        #endif
    }
}

#if os(iOS)
/// 系统 `UIPageControl`。SwiftUI 没有对应物；自造圆点会和 TabView 原来那组对不上。
private struct OnboardingPageControlUIKit: UIViewRepresentable {
    var page: OnboardingPage
    var onChange: (OnboardingPage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = OnboardingPage.allCases.count
        control.currentPage = page.rawValue
        control.backgroundStyle = .prominent
        control.hidesForSinglePage = true
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.changed(_:)),
            for: .valueChanged
        )
        return control
    }

    func updateUIView(_ control: UIPageControl, context: Context) {
        context.coordinator.onChange = onChange
        let pages = OnboardingPage.allCases.count
        // 同样的值再写一遍会触发 valueChanged / 固有尺寸变化，
        // 叠在分页 ScrollView 上就变成量尺寸循环。
        if control.numberOfPages != pages {
            control.numberOfPages = pages
        }
        if control.currentPage != page.rawValue {
            control.currentPage = page.rawValue
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var onChange: (OnboardingPage) -> Void

        init(onChange: @escaping (OnboardingPage) -> Void) {
            self.onChange = onChange
        }

        @objc func changed(_ sender: UIPageControl) {
            guard let page = OnboardingPage(rawValue: sender.currentPage) else { return }
            onChange(page)
        }
    }
}
#endif
