#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryCatStatesView: View {
    @State private var studio = GalleryCatStudio()

    var body: some View {
        @Bindable var studio = studio
        MeterGroupedList {
            // 大图放在最上面：选中表情要在点的同时看得见，
            // 放在选择器下面就得滚一屏才知道刚才点了什么。
            Section {
                studio.cat(size: MeterSpacing.catGallery)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 3),
                    spacing: MeterSpacing.sm
                ) {
                    ForEach(MeterDesign.CatMood.allCases, id: \.self) { mood in
                        Button {
                            studio.apply(mood)
                        } label: {
                            VStack(spacing: MeterSpacing.xxs) {
                                CatView(mood: mood, size: MeterSpacing.catTip, isAnimated: false)
                                Text(mood.galleryTitle)
                                    .font(MeterFont.caption2)
                                    .foregroundStyle(Color.meterSecondaryLabel)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(mood.galleryTitle)
                    }
                }
                .listRowBackground(Color.clear)
            } header: {
                Text(L("全部表情"))
            }

            Section {
                Toggle(L("动画"), isOn: $studio.isAnimated)
                    .accessibilityHint(L("关掉就是 Widget 那一帧"))
                Picker(L("耳朵"), selection: $studio.ears) {
                    ForEach(CatEarMotion.allCases, id: \.self) { ears in
                        Text(ears.galleryTitle).tag(ears)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityHint(L("开启动画之后两只耳朵才会自己晃"))
            } footer: {
                Text(L("常态会眨眼、视线会慢慢漂。吓到会绷直颤抖，睡觉的 ZZZ 会上浮。换表情先眨眼再变脸。耳朵会动是试验：两只不同步，生产界面默认钉住。点表情当场看。"))
            }

            Section {
                Picker(L("预设"), selection: presetSelection) {
                    ForEach(MeterDesign.CatMood.allCases, id: \.self) { mood in
                        Text(mood.galleryTitle).tag(mood)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(L("预设"))
            } footer: {
                Text(L("点一套预设会换上对应的眼睛、嘴和挂件。图层可以再拆开。"))
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
            } header: {
                Text(L("图层"))
            }

            Section {
                MeterColumnPushLink(title: Text(L("高级"))) {
                    GalleryCatAdvancedView(studio: studio)
                } label: {
                    Text(L("高级"))
                }
            } footer: {
                Text(L("姿势、眼镜、翻肚皮、动效循环和尺寸都在里面。"))
            }

            Section {
                widgetPreview
                    .listRowBackground(Color.clear)
            } header: {
                Text(L("Widget"))
            } footer: {
                Text(L("中号：猫猫在左、数字在右。没有动画。"))
            }

            Section {
                ForEach(DashboardCatPerch.allCases) { perch in
                    DashboardCatStage(
                        composition: GalleryCatPerchPreview.sample,
                        mood: studio.mood.coreMood,
                        speech: String(localized: L("合计较上月同期涨了 \(62)%。")),
                        monthToDate: GalleryCatPerchPreview.monthToDate,
                        onShare: {},
                        pinnedPerch: perch
                    )
                    .listRowBackground(Color.meterGroupedBackground)
                    .listRowInsets(
                        EdgeInsets(
                            top: 0,
                            leading: -MeterSpacing.pageHorizontal,
                            bottom: 0,
                            trailing: -MeterSpacing.pageHorizontal
                        )
                    )
                    .listRowSeparator(.hidden)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(perch.galleryTitle)
                }
            } header: {
                Text(L("仪表落点"))
            } footer: {
                Text(L("进仪表会从合计右边那三处里抽一处。分享按钮两翼这两处只在这一页看得到——分享钮已经挪到页尾。"))
            }
        }
        .navigationTitle(L("猫猫"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var presetSelection: Binding<MeterDesign.CatMood> {
        Binding(
            get: { studio.mood },
            set: { studio.apply($0) }
        )
    }

    private var widgetPreview: some View {
        HStack(alignment: .center, spacing: MeterSpacing.sm) {
            studio.cat(size: MeterSpacing.catWidget, animated: false)
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                Text("$47.20")
                    .font(MeterFont.title2)
                    .monospacedDigit()
                    .foregroundStyle(Color.meterLabel)
                Text(L("预计 $94.00"))
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterSecondaryLabel)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(MeterSpacing.sm)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(Color.meterSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("中号 Widget 预览"))
    }
}

private enum GalleryCatPerchPreview {
    static let monthToDate = MonthToDateModuleContent.make(
        from: MonthToDate(
            totalUSD: Money(roundedUSD: 47.20),
            projectedMonthEndUSD: Money(roundedUSD: 87.70),
            confidence: .estimated,
            estimatedAccounts: [AccountID.fixture(for: .neon)],
            facts: [],
            variableUSD: Money(roundedUSD: 47.20),
            projectedVariableUSD: Money(roundedUSD: 87.70)
        ),
        estimatedNames: ["Neon"],
        staleCaption: nil,
        now: MeterClock.design.now,
        calendar: MeterClock.design.calendar
    )

    static let sample = CompositionModuleContent(
        segments: [
            CompositionSegment(
                accountID: AccountID.fixture(for: .aws),
                providerID: .aws,
                displayName: "AWS",
                colorKey: "aws",
                amount: Money(roundedUSD: 21.40),
                fraction: 0.45,
                percent: 45
            ),
            CompositionSegment(
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare,
                displayName: "Cloudflare",
                colorKey: "cloudflare",
                amount: Money(roundedUSD: 11.05),
                fraction: 0.23,
                percent: 23
            ),
        ],
        totalText: Money(roundedUSD: 47.20).formatted(),
        spokenTotal: String(localized: L("47 美元 20 美分")),
        destination: AccountID.fixture(for: .aws)
    )
}

private extension MeterDesign.CatMood {
    var coreMood: MeterCore.CatMood {
        MeterCore.CatMood(rawValue: rawValue) ?? .normal
    }

    var galleryTitle: String {
        switch self {
        case .normal: String(localized: L("平常"))
        case .sleeping: String(localized: L("睡觉"))
        case .saved: String(localized: L("省到了"))
        case .alert: String(localized: L("告急"))
        case .shocked: String(localized: L("吓到"))
        case .awkward: String(localized: L("尴尬"))
        case .dead: String(localized: L("翻肚皮"))
        }
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryCatStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryCatStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
