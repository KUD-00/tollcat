#if DEBUG
import SwiftUI
import MeterDesign

/// 刷新按钮的旋转。点一下就能看，不必走真实 API。
struct GalleryRefreshView: View {
    @State private var isRefreshing = false
    @State private var runID = 0

    var body: some View {
        MeterGroupedList {
            Section {
                Button {
                    spin()
                } label: {
                    Label {
                        Text(L("刷新"))
                    } icon: {
                        MeterRefreshGlyph(isRefreshing: isRefreshing)
                    }
                }
                .meterRefreshing(isRefreshing)
            } header: {
                Text(L("刷新"))
            } footer: {
                Text(L("点一下，箭头转到刷新结束。内容不许另起转圈。减弱动态效果时箭头停住。"))
            }

            Section {
                HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                    Text(L("上次刷新 \(String(localized: L("刚刚")))"))
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                    Button {
                        spin()
                    } label: {
                        MeterRefreshGlyph(isRefreshing: isRefreshing)
                            .font(MeterFont.subheadline)
                            .padding(.vertical, MeterSpacing.xxs)
                            .frame(minWidth: MeterSpacing.minTap, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(isRefreshing)
                    Spacer(minLength: 0)
                }
            } header: {
                Text(L("金额"))
            }

            Section {
                Button(L("转一次")) { spin() }
                    .disabled(isRefreshing)
                    .accessibilityHint(L("点一下，箭头转到刷新结束"))
            } header: {
                Text(L("交互"))
            }
        }
        .navigationTitle(L("刷新按钮"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func spin() {
        runID += 1
        let id = runID
        isRefreshing = true
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard id == runID else { return }
            isRefreshing = false
        }
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryRefreshView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryRefreshView()
    }
    .preferredColorScheme(.dark)
}
#endif
