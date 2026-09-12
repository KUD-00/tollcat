import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ProviderCatalogTests {
    @Test("各家 kind 按账单形态分配")
    func descriptorsMatchKinds() {
        #expect(ProviderCatalog.all.count == 527)
        #expect(ProviderCatalog.offered.count == 241)
        #expect(ProviderCatalog.betterstack.kind == .usage)
        #expect(ProviderCatalog.easypost.kind == .prepaid)
        #expect(ProviderCatalog.transloadit.kind == .usage)
        #expect(ProviderCatalog.api2pdf.kind == .prepaid)
        #expect(ProviderCatalog.hetrixtools.kind == .prepaid)
        #expect(ProviderCatalog.shipstation.kind == .prepaid)
        #expect(ProviderCatalog.thanksio.kind == .usage)
        #expect(ProviderCatalog.click2mail.kind == .usage)
        #expect(ProviderCatalog.gelato.kind == .usage)
        #expect(ProviderCatalog.shipbob.kind == .usage)
        #expect(ProviderCatalog.mikrocloud.kind == .usage)
        #expect(ProviderCatalog.leaseweb.kind == .usage)
        #expect(ProviderCatalog.qovery.kind == .usage)
        #expect(ProviderCatalog.prodigi.kind == .usage)
        #expect(ProviderCatalog.qiniu.kind == .usage)
        #expect(ProviderCatalog.mysendingbox.kind == .usage)
        #expect(ProviderCatalog.stannp.kind == .prepaid)
        #expect(ProviderCatalog.phaxio.kind == .prepaid)
        #expect(ProviderCatalog.porkbun.kind == .prepaid)
        #expect(ProviderCatalog.namecheap.kind == .prepaid)
        #expect(ProviderCatalog.gandi.kind == .prepaid)
        #expect(ProviderCatalog.mapbox.kind == .usage)
        #expect(ProviderCatalog.googlemaps.kind == .usage)
        #expect(ProviderCatalog.docusign.kind == .subscription)
        #expect(ProviderCatalog.typeform.kind == .subscription)
        #expect(ProviderCatalog.kit.kind == .subscription)
        for descriptor in ProviderCatalog.all {
            #expect(descriptor.colorKey == descriptor.id.rawValue)
        }
        for descriptor in ProviderCatalog.offered {
            #expect(descriptor.billingURL?.scheme == "https")
            #expect(descriptor.credentialSetupURL?.scheme == "https")
            #expect(descriptor.credentialSetupURL != descriptor.billingURL)
            #expect(descriptor.declineReason == nil)
        }
        for descriptor in ProviderCatalog.all where descriptor.accessStatus == .declined {
            #expect(descriptor.billingURL == nil)
            #expect(descriptor.credentialSetupURL == nil)
            #expect(!(descriptor.declineReason ?? "").isEmpty)
            #expect(!descriptor.isOffered)
        }
        #expect(ProviderCatalog.api2pdf.billingURL != ProviderCatalog.api2pdf.credentialSetupURL)
        #expect(ProviderTier.one < .two)
        #expect(ProviderTier.two < .three)
        #expect(ProviderTier.three < .four)
        #expect(ProviderTier.allCases.map(\.rawValue) == [1, 2, 3, 4])
        for descriptor in ProviderCatalog.all {
            #expect(!descriptor.tierReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test("不接入的家有理由、不进取数 map、不进产品列表")
    func declinedProvidersStayOutOfProductLists() {
        let declined = ProviderCatalog.all.filter { $0.accessStatus == .declined }.map(\.id)
        for id: ProviderID in [.mapbox, .googlemaps, .docusign, .typeform, .kit, .airtable, .googleads, .ramp] {
            #expect(declined.contains(id))
            #expect(!ProviderAssembly.liveRESTProviderIDs.contains(id))
            #expect(ProviderCatalog.descriptor(id: id)?.isOffered == false)
        }
        #expect(Set(ProviderCatalog.offered.map(\.id)).isDisjoint(with: Set(declined)))
    }

    @Test("新接入 live 家在 liveREST 与 offered")
    func newLiveProvidersAreWired() {
        for id: ProviderID in [
            .betterstack, .easypost, .transloadit, .api2pdf, .hetrixtools,
            .shipstation, .thanksio, .click2mail,
            .gelato, .prodigi, .qiniu, .mysendingbox,
            .stannp, .phaxio, .porkbun, .namecheap, .gandi,
            .hostens, .binarylane, .tierpoint, .postman, .sevenbridges, .cmcom,
            .shipbob, .mikrocloud, .leaseweb, .qovery,
            .phoenixnap, .magalucloud,
            .transip, .serverscom, .flexport,
            .i3dnet, .datapacket, .cudocompute, .shipwell, .ocamba,
            .inferencesh, .voltview,
            .clevercloud, .utilityapi, .dnsimple, .latitudesh,
            .realtimeregister, .pdfshift, .alchemy, .friendli, .mixpeek, .typebot, .vpsnet, .seeweb, .parasail,
            .bring, .armada, .mollie,
            .openprovider, .stackit, .conoha,
            .zcomcloud, .idcf, .internetx, .melbicom,
            .time4vps, .bitlaunch, .hivelocity,
            .scalingo, .upsun, .ncloud, .nomos, .dnscale, .together,
            .formspring, .hostcircle, .loginet,
            .idcloudhost, .unleash, .glesys, .cloudsigma, .rediscloud,
            .iwinv, .frankenergie, .dilmune, .hubble,
            .filescom, .doit, .timeweb, .cloudheed, .sevalla, .catalystvm, .oxahost, .fiskil, .threeplguys, .pleo, .cerebrium, .shipmondo, .sendcloud, .alibabacloud, .volcengine, .kingsoftcloud, .tencentcloud, .make,
        ] {
            #expect(ProviderAssembly.liveRESTProviderIDs.contains(id))
            #expect(ProviderCatalog.descriptor(id: id)?.isOffered == true)
            #expect(ProviderCatalog.descriptor(id: id)?.accessStatus == .pendingVerification)
        }
    }

    @Test("Stripe / Botpress / Neo4j Aura 已对过真账")
    func stripeBotpressNeo4jAreAvailable() {
        for id: ProviderID in [.stripe, .botpress, .neo4j] {
            #expect(ProviderAssembly.liveRESTProviderIDs.contains(id))
            #expect(ProviderCatalog.descriptor(id: id)?.isOffered == true)
            #expect(ProviderCatalog.descriptor(id: id)?.accessStatus == .available)
        }
    }

    @Test("DigitalOcean 已对过真账，仍是用量后付费")
    func digitaloceanIsAvailableUsage() {
        #expect(ProviderAssembly.liveRESTProviderIDs.contains(.digitalocean))
        #expect(ProviderCatalog.digitalocean.isOffered)
        #expect(ProviderCatalog.digitalocean.accessStatus == .available)
        #expect(ProviderCatalog.digitalocean.kind == .usage)
    }
}
