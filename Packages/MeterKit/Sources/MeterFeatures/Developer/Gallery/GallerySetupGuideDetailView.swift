#if DEBUG
import MeterCore
import SwiftUI
import MeterDesign
import MeterPersistence
import MeterProviders

struct GallerySetupGuideDetailView: View {
    var descriptor: ProviderDescriptor?
    var guide: SetupGuide?

    var body: some View {
        MeterGroupedList {
            if let guide {
                if let descriptor {
                    SetupUsageFactsSection(descriptor: descriptor, fields: guide.fields)
                }

                if guide.parts.isEmpty {
                    ContentUnavailableView {
                        Label(L("接入说明还没写好"), systemImage: "list.clipboard")
                    } description: {
                        Text(L("这家的分步说明还在准备。可以先去官网创建只读凭据。"))
                    }
                } else {
                    ForEach(Array(guide.parts.enumerated()), id: \.offset) { _, part in
                        Section {
                            ForEach(Array(part.steps.enumerated()), id: \.offset) { _, step in
                                SetupStepText(
                                    step: step,
                                    linkURL: step.linkPhrases.isEmpty
                                        ? nil
                                        : descriptor?.setupLinkURL(target: step.linkTarget)
                                )
                                if let copyable = step.copyable {
                                    CopyBox(copyable.value, onCopy: {})
                                }
                            }
                        } header: {
                            if let heading = SetupPartHeading.resource(for: part) {
                                Text(heading)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label(L("接入说明还没写好"), systemImage: "list.clipboard")
                } description: {
                    Text(L("这家的分步说明还在准备。可以先去官网创建只读凭据。"))
                }
            }
        }
        .navigationTitle(descriptor?.displayName ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("AWS") {
    NavigationStack {
        GallerySetupGuideDetailView(
            descriptor: ProviderCatalog.aws,
            guide: nil
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        GallerySetupGuideDetailView(
            descriptor: ProviderCatalog.fly,
            guide: nil
        )
    }
}
#endif
