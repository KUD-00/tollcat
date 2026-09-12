import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ProviderAssemblyTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now

    @Test("map 的键和 liveRESTProviderIDs 是同一份清单——加 provider 漏改任一边都在这里翻车")
    func mapMatchesDeclaredLiveIDs() {
        let map = ProviderAssembly.make(
            now: { now },
            calendar: calendar,
            httpClient: LiveProviderHarness.stub([])
        )
        #expect(Set(map.keys) == ProviderAssembly.liveRESTProviderIDs)
        // 抽查几家的具体类型，防 switch 里张冠李戴。
        #expect(map[.cloudflare] is CloudflareBillingProvider)
        #expect(map[.openai] is OpenAIBillingProvider)
        #expect(map[.moonshot] is MoonshotBillingProvider)
        #expect(map[.moonshotAI] is MoonshotAIBillingProvider)
        #expect(map[.qdrant] is QdrantBillingProvider)
        #expect(map[.mistral] is MistralBillingProvider)
        #expect(map[.fireworks] is FireworksBillingProvider)
        #expect(map[.fal] is FalBillingProvider)
        #expect(map[.huggingface] is HuggingFaceBillingProvider)
        #expect(map[.turso] is TursoBillingProvider)
        #expect(map[.baseten] is BasetenBillingProvider)
        #expect(map[.clickhouse] is ClickHouseBillingProvider)
        #expect(map[.linode] is LinodeBillingProvider)
        #expect(map[.runpod] is RunPodBillingProvider)
        #expect(map[.deepgram] is DeepgramBillingProvider)
        #expect(map[.scaleway] is ScalewayBillingProvider)
        #expect(map[.bunny] is BunnyBillingProvider)
        #expect(map[.grafana] is GrafanaBillingProvider)
        #expect(map[.elastic] is ElasticBillingProvider)
        #expect(map[.datadog] is DatadogBillingProvider)
        #expect(map[.novita] is NovitaBillingProvider)
        #expect(map[.apify] is ApifyBillingProvider)
        #expect(map[.tavily] is TavilyBillingProvider)
        #expect(map[.deepinfra] is DeepInfraBillingProvider)
        #expect(map[.vastai] is VastAIBillingProvider)
        #expect(map[.firecrawl] is FirecrawlBillingProvider)
        #expect(map[.cockroach] is CockroachBillingProvider)
        #expect(map[.typesense] is TypesenseBillingProvider)
        #expect(map[.aiven] is AivenBillingProvider)
        #expect(map[.siliconflow] is SiliconFlowBillingProvider)
        #expect(map[.aimlapi] is AIMLAPIBillingProvider)
        #expect(map[.stepfun] is StepFunBillingProvider)
        #expect(map[.stepfunAI] is StepFunAIBillingProvider)
        #expect(map[.telnyx] is TelnyxBillingProvider)
        #expect(map[.mariadb] is MariaDBCloudBillingProvider)
        #expect(map[.ionos] is IONOSCloudBillingProvider)
        #expect(map[.upcloud] is UpCloudBillingProvider)
        #expect(map[.confluent] is ConfluentBillingProvider)
        #expect(map[.vonage] is VonageBillingProvider)
        #expect(map[.plivo] is PlivoBillingProvider)
        #expect(map[.messagebird] is MessageBirdBillingProvider)
        #expect(map[.ibm] is IBMCloudBillingProvider)
        #expect(map[.clicksend] is ClickSendBillingProvider)
        #expect(map[.infobip] is InfobipBillingProvider)
        #expect(map[.textmagic] is TextmagicBillingProvider)
        #expect(map[.anthropic] is AnthropicBillingProvider)
        #expect(map[.clevercloud] is CleverCloudBillingProvider)
        #expect(map[.utilityapi] is UtilityAPIBillingProvider)
        #expect(map[.dnsimple] is DNSimpleBillingProvider)
        #expect(map[.latitudesh] is LatitudeSHBillingProvider)
        // 没有公开账单接口的不进 map。
        #expect(map[.aws] == nil)
        #expect(map[.gcp] == nil)
        #expect(!ProviderAssembly.liveRESTProviderIDs.contains(.aws))
        #expect(!ProviderAssembly.liveRESTProviderIDs.contains(.gcp))
    }

    @Test("fromHTTPStatus 把 429 / 5xx / 404 分成不同修复建议")
    func httpStatusMapping() {
        #expect(ProviderError.fromHTTPStatus(429, providerID: .openai)?.remediationKey == .rateLimited)
        #expect(ProviderError.fromHTTPStatus(503, providerID: .openai)?.remediationKey == .serviceUnavailable)
        #expect(ProviderError.fromHTTPStatus(404, providerID: .github)?.remediationKey == .billingAPIUnavailable)
        #expect(ProviderError.fromHTTPStatus(401, providerID: .openai)?.remediationKey == .invalidCredentials)
        #expect(ProviderError.fromHTTPStatus(403, providerID: .openai)?.remediationKey == .insufficientPermissions)
        #expect(ProviderError.fromHTTPStatus(200, providerID: .openai) == nil)
    }
}
