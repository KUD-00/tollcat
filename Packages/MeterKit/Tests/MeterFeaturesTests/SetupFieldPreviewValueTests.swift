import Foundation
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct SetupFieldPreviewValueTests {
    @Test("占位值过得了该字段自己的校验")
    func previewValuePassesItsOwnRules() async throws {
        let catalog = try await BundledCatalogSource().load()
        #expect(catalog.guides.count >= ProviderAssembly.liveRESTProviderIDs.count)
        for id in ProviderAssembly.liveRESTProviderIDs {
            #expect(catalog.guides[id] != nil, "\(id.rawValue) 能取数却没有教程")
        }

        for (id, guide) in catalog.guides {
            let descriptor = ProviderCatalog.descriptor(id: id)
            // 信箱和纯固定订阅都没有凭据可填。
            if descriptor?.supportsInboxIngest == true || descriptor?.kind == .subscription {
                #expect(guide.fields.isEmpty, "\(id.rawValue) 不该有凭据字段")
                continue
            }
            #expect(!guide.fields.isEmpty, "\(id.rawValue) 缺字段")
            let values = SetupFieldPreviewValue.dictionary(for: guide.fields)
            #expect(Set(values.keys) == Set(guide.fields.map(\.key)))
            for field in guide.fields {
                let value = try #require(values[field.key])
                #expect(field.errorMessage(for: value) == nil, "\(id.rawValue).\(field.key) 过不了校验: \(value)")
            }
        }
    }

    @Test("验收成功态按向导字段填，不再写死 Cloudflare")
    func launchSuccessUsesGuideFields() async {
        let model = SetupWizardModel(providerID: .aws, dashboard: .preview)
        await model.prepare()
        model.applyLaunchOutcome("success")

        #expect(model.fieldValues["accessKeyID"]?.hasPrefix("AKIA") == true)
        #expect(model.fieldValues["secretAccessKey"] != nil)
        #expect(model.fieldValues["apiToken"] == nil)
        #expect(model.outcome != nil)
    }
}
