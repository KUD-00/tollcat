#if DEBUG
import SwiftUI
import MeterDesign
import MeterTips

/// 打赏成功：猫变大换脸、档位收走、留下留言。点一下就能看，不必真买。
struct GalleryTipStatesView: View {
    @State private var celebrated = false
    /// 三档的谢词不一样，画廊要能挨个看，不用真买三次。
    @State private var treat = TipProductID.small
    @State private var isRepeat = false
    @State private var draftName = ""
    @State private var draftMessage = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MeterGroupedList {
            Section {
                VStack(spacing: MeterSpacing.sm) {
                    CatView(
                        parts: (celebrated ? CatMood.saved : CatMood.normal).parts,
                        size: celebrated
                            ? MeterSpacing.catTipCelebrating
                            : MeterSpacing.catTip,
                        accessibilityLabel: celebrated
                            ? L("猫猫收到了吃的，很高兴")
                            : L("猫猫在等吃的"),
                        isAnimated: true,
                        motion: .idle
                    )
                    .frame(maxWidth: .infinity)

                    if celebrated {
                        let copy = TipThanks.make(treat: treat, isRepeat: isRepeat)
                        VStack(spacing: MeterSpacing.xxs) {
                            Text(copy.headline)
                                .font(MeterFont.title2)
                                .foregroundStyle(Color.meterLabel)
                            Text(copy.note)
                                .font(MeterFont.subheadline)
                                .foregroundStyle(Color.meterSecondaryLabel)
                        }
                        .multilineTextAlignment(.center)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if celebrated {
                Section {
                    TextField(L("名字（可不填）"), text: $draftName)
                    TextField(L("一句话（可不填）"), text: $draftMessage, axis: .vertical)
                        .lineLimit(3...6)
                } footer: {
                    Text(L("名字和留言都可以空着。退出这页就当没留。"))
                }
            } else {
                Section {
                    HStack(alignment: .bottom, spacing: MeterSpacing.xs) {
                        ForEach(TipTreatKind.allCases, id: \.self) { kind in
                            TipTreatView(kind: kind, size: MeterSpacing.tipTreat)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } footer: {
                    Text(L("糖果、咖啡、披萨。点下面那颗看付款成功之后的变化。"))
                }
            }

            Section {
                ForEach(TipProductID.allCases, id: \.self) { id in
                    VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                        Text(id.listTitle)
                            .font(MeterFont.subheadline)
                            .foregroundStyle(Color.meterSecondaryLabel)
                        Text(TipThanks.make(treat: id, isRepeat: false).headline)
                            .font(MeterFont.title2)
                            .foregroundStyle(Color.meterLabel)
                        Text(TipThanks.make(treat: id, isRepeat: false).note)
                            .font(MeterFont.subheadline)
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, MeterSpacing.xxs)
                }
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    Text(L("回头客"))
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                    Text(TipThanks.make(treat: .medium, isRepeat: true).headline)
                        .font(MeterFont.title2)
                        .foregroundStyle(Color.meterLabel)
                    Text(TipThanks.make(treat: .medium, isRepeat: true).note)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, MeterSpacing.xxs)
            } header: {
                Text(L("谢词"))
            }

            Section {
                Button(celebrated ? L("再看选档") : L("付款成功")) {
                    celebrated.toggle()
                }
                .accessibilityHint(L("点一下看付款成功"))

                if celebrated {
                    // 档位名的单源在 MeterTips（`listTitle`），别在这儿再抄一份字面量。
                    Picker(L("档位"), selection: $treat) {
                        ForEach(TipProductID.allCases, id: \.self) { id in
                            Text(id.listTitle).tag(id)
                        }
                    }
                    Toggle(L("回头客"), isOn: $isRepeat)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: celebrated)
        .navigationTitle(L("打赏"))
        .navigationBarTitleDisplayMode(.inline)
        .meterKeyboardDismiss {}
        .meterPrimaryActionBar(isVisible: celebrated, ignoresKeyboard: true) {
            Button(L("写好了")) {
                celebrated = false
            }
            .meterPrimaryActionStyle()
        }
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryTipStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryTipStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
