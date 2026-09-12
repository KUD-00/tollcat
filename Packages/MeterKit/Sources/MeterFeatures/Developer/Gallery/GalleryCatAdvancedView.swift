#if DEBUG
import SwiftUI
import MeterDesign

/// 把猫的图层和姿势拆开拧。生产界面仍然只走命名表情。
struct GalleryCatAdvancedView: View {
    @Bindable var studio: GalleryCatStudio

    var body: some View {
        MeterGroupedList {
            Section {
                studio.cat()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                Toggle(L("动画"), isOn: $studio.isAnimated)
                Picker(L("动效循环"), selection: $studio.motion) {
                    ForEach(CatMotionKind.allCases, id: \.self) { kind in
                        Text(kind.galleryTitle).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                Picker(L("耳朵"), selection: $studio.ears) {
                    ForEach(CatEarMotion.allCases, id: \.self) { ears in
                        Text(ears.galleryTitle).tag(ears)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text(L("开启动画会按循环播，姿势滑块先不生效。耳朵会动只在动画开着时播。"))
            }

            Section {
                Picker(L("眼睛"), selection: $studio.parts.eyes) {
                    ForEach(CatEyes.allCases, id: \.self) { eyes in
                        Text(eyes.galleryTitle).tag(eyes)
                    }
                }
                .pickerStyle(.menu)

                Picker(L("嘴"), selection: $studio.parts.mouth) {
                    ForEach(CatMouth.allCases, id: \.self) { mouth in
                        Text(mouth.galleryTitle).tag(mouth)
                    }
                }
                .pickerStyle(.menu)

                Picker(L("挂件"), selection: $studio.parts.accessory) {
                    ForEach(CatAccessory.allCases, id: \.self) { accessory in
                        Text(accessory.galleryTitle).tag(accessory)
                    }
                }
                .pickerStyle(.menu)

                Toggle(L("翻肚皮"), isOn: $studio.parts.isUpsideDown)
                Toggle(L("眼镜"), isOn: $studio.parts.wearsGlasses)
            } header: {
                Text(L("图层"))
            }

            Section {
                poseSlider(L("压扁"), value: squashBinding, range: -0.5...1.5)
                poseSlider(L("眨眼"), value: blinkBinding, range: 0...1)
                poseSlider(L("视线左右"), value: gazeXBinding, range: -40...40)
                poseSlider(L("视线上下"), value: gazeYBinding, range: -24...24)
                poseSlider(L("尾巴"), value: tailBinding, range: -45...45)
                poseSlider(L("左耳"), value: leftEarBinding, range: -20...20)
                poseSlider(L("右耳"), value: rightEarBinding, range: -20...20)
                poseSlider(L("ZZZ 上浮"), value: zzzBinding, range: 0...1)
                poseSlider(L("颤抖"), value: shakeBinding, range: -1...1)
                poseSlider(L("拉长"), value: stretchBinding, range: 0...2)
            } header: {
                Text(L("姿势"))
            } footer: {
                Text(L("关掉动画之后，这些滑块才是这一帧。"))
            }

            Section {
                poseSlider(L("尺寸"), value: $studio.size, range: 32...280, disabledWhenAnimated: false)
                Picker(L("常用尺寸"), selection: namedSizeBinding) {
                    ForEach(GalleryCatNamedSize.allCases) { named in
                        Text(named.title).tag(named)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(L("尺寸"))
            } footer: {
                Text(L("常用尺寸只改预览大小，图层和姿势不动。"))
            }
        }
        .navigationTitle(L("高级"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var squashBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.squash }, set: { studio.pose.squash = $0 })
    }

    private var blinkBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.blink }, set: { studio.pose.blink = $0 })
    }

    private var gazeXBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.gazeX }, set: { studio.pose.gazeX = $0 })
    }

    private var gazeYBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.gazeY }, set: { studio.pose.gazeY = $0 })
    }

    private var tailBinding: Binding<CGFloat> {
        Binding(
            get: { CGFloat(studio.pose.tailDegrees) },
            set: { studio.pose.tailDegrees = Double($0) }
        )
    }

    private var leftEarBinding: Binding<CGFloat> {
        Binding(
            get: { CGFloat(studio.pose.leftEarDegrees) },
            set: { studio.pose.leftEarDegrees = Double($0) }
        )
    }

    private var rightEarBinding: Binding<CGFloat> {
        Binding(
            get: { CGFloat(studio.pose.rightEarDegrees) },
            set: { studio.pose.rightEarDegrees = Double($0) }
        )
    }

    private var zzzBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.zzzLift }, set: { studio.pose.zzzLift = $0 })
    }

    private var shakeBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.shake }, set: { studio.pose.shake = $0 })
    }

    private var stretchBinding: Binding<CGFloat> {
        Binding(get: { studio.pose.stretch }, set: { studio.pose.stretch = $0 })
    }

    private var namedSizeBinding: Binding<GalleryCatNamedSize> {
        Binding(
            get: {
                GalleryCatNamedSize.allCases.first { abs($0.size - studio.size) < 0.5 } ?? .gallery
            },
            set: { studio.size = $0.size }
        )
    }

    private func poseSlider(
        _ title: LocalizedStringResource,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>,
        disabledWhenAnimated: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
                    .accessibilityHidden(true)
            }
            Slider(value: value, in: range)
                .accessibilityLabel(title)
        }
        .disabled(disabledWhenAnimated && studio.isAnimated)
    }
}

private enum GalleryCatNamedSize: String, CaseIterable, Identifiable {
    case widget
    case sidebar
    case tip
    case dashboard
    case onboarding
    case gallery

    var id: String { rawValue }

    var size: CGFloat {
        switch self {
        case .widget: MeterSpacing.catWidget
        case .sidebar: MeterSpacing.catSidebar
        case .tip: MeterSpacing.catTip
        case .dashboard: MeterSpacing.catDashboard
        case .onboarding: MeterSpacing.catOnboarding
        case .gallery: MeterSpacing.catGallery
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .widget: L("Widget")
        case .sidebar: L("侧栏")
        case .tip: L("打赏")
        case .dashboard: L("仪表")
        case .onboarding: L("开屏")
        case .gallery: L("画廊")
        }
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryCatAdvancedView(studio: GalleryCatStudio())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryCatAdvancedView(studio: GalleryCatStudio())
    }
    .preferredColorScheme(.dark)
}
#endif
