import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence

struct SetupGuideStepView: View {
    @Bindable var model: SetupWizardModel
    var onOpenConsole: (URL) -> Void
    var showsAdvanceButton: Bool = true
    var reportedContentHeight: Binding<CGFloat>? = nil

    var body: some View {
        Form {
            if let descriptor = model.descriptor {
                SetupUsageFactsSection(descriptor: descriptor, fields: model.guide.fields)
            }
            if model.guide.parts.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label(L("接入说明还没写好"), systemImage: "list.clipboard")
                    } description: {
                        Text(L("这家的分步说明还在准备。可以先去官网创建只读凭据。"))
                    }
                }
                if let url = model.credentialSetupURL {
                    Section {
                        Button(L("在浏览器中打开"), systemImage: "safari") {
                            onOpenConsole(url)
                        }
                        .accessibilityLabel(L("在浏览器中打开创建页"))
                    }
                }
            } else {
                ForEach(Array(model.guide.parts.enumerated()), id: \.offset) { _, part in
                    Section {
                        ForEach(Array(part.steps.enumerated()), id: \.offset) { index, step in
                            stepBlock(step, number: index + 1)
                        }
                    } header: {
                        if let heading = SetupPartHeading.resource(for: part) {
                            Text(heading)
                        }
                    }
                }
            }
        }
        // grouped：iOS 就是分组卡片；Mac 是系统设置那种分组 Form。
        // 走 List 的 inset 分组样式在 Mac 会被别名成密表，两栏连接参考整个塌掉。
        .formStyle(.grouped)
        .meterGroupedRowButtons()
        .meterGroupedSectionCard()
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentSize.height }) { _, height in
            guard let reportedContentHeight else { return }
            guard height.isFinite else { return }
            // 抽屉收矮之后会按更矮的提议再量一次，跟着缩会把主按钮切掉。
            // 差几 pt 就改，会跟 sheet 尺寸互相喂，系统报 cyclic layout。
            let snapped = height.rounded()
            guard snapped > reportedContentHeight.wrappedValue + MeterSpacing.xs else { return }
            reportedContentHeight.wrappedValue = snapped
        }
        // 标题由宿主定：手机栈在 `SetupWizardView` 写导航标题，宽壳两栏共用一条 sheet 标题。
        .meterPrimaryActionBar(isVisible: showsAdvanceButton, ignoresKeyboard: true) {
            Button {
                model.advanceFromGuide()
            } label: {
                Text(L("我拿到凭据了，下一步"))
                    .frame(maxWidth: .infinity)
            }
            .meterPrimaryActionStyle()
            .accessibilityIdentifier(UITestID.setupNext)
        }
    }

    @ViewBuilder
    private func stepBlock(_ step: SetupStep, number: Int) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            stepRow(step, number: number)
            if let copyable = step.copyable {
                VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                    if !copyable.label.isEmpty {
                        Text(copyable.label)
                            .font(MeterFont.caption)
                            .foregroundStyle(Color.meterSecondaryLabel)
                    }
                    CopyBox(copyable.value) {
                        model.copy(copyable.value)
                    }
                }
                .padding(.leading, MeterSpacing.stepIndex + MeterSpacing.stepIndexGap)
            }
        }
    }

    @ViewBuilder
    private func stepRow(_ step: SetupStep, number: Int) -> some View {
        let url = linkURL(for: step)
        let row = HStack(alignment: .center, spacing: MeterSpacing.stepIndexGap) {
            StepIndexBadge(number)
            SetupStepText(
                step: step,
                linkURL: url,
                onOpenLink: onOpenConsole
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("第 \(number) 步。\(step.text)"))

        if let url {
            row.accessibilityAction(named: openLinkName(for: step)) {
                onOpenConsole(url)
            }
        } else {
            row
        }
    }

    private func linkURL(for step: SetupStep) -> URL? {
        guard !step.linkPhrases.isEmpty else { return nil }
        return model.descriptor?.setupLinkURL(target: step.linkTarget)
            ?? model.credentialSetupURL
    }

    private func openLinkName(for step: SetupStep) -> LocalizedStringResource {
        step.linkTarget.isEmpty ? L("在浏览器中打开创建页") : L("在浏览器中打开")
    }
}

#Preview("Light") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .guide
    )
    NavigationStack {
        SetupGuideStepView(model: model, onOpenConsole: { _ in })
            .task { await model.prepare() }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    @Previewable @State var model = SetupWizardModel.preview(
        providerID: .cloudflare,
        step: .guide
    )
    NavigationStack {
        SetupGuideStepView(model: model, onOpenConsole: { _ in })
            .task { await model.prepare() }
    }
    .preferredColorScheme(.dark)
}
