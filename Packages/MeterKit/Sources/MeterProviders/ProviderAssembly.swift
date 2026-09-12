import Foundation
import MeterCore

/// 组装各家 `BillingProvider`。有公开只读账单接口的走真适配器，其余不进取数 map。
public enum ProviderAssembly: Sendable {
    public static let liveRESTProviderIDs: Set<ProviderID> = [
        .cloudflare, .neon, .openai, .vercel, .github,
        .openrouter, .deepseek, .moonshot, .moonshotAI, .xai,
        .digitalocean, .twilio, .planetscale, .upstash, .elevenlabs,
        .railway, .stripe, .resend, .posthog, .sentry,
        .vultr, .fastly, .exa, .atlas, .azure, .polar, .heroku,
        .revenuecat, .qdrant,
        .mistral, .fireworks, .fal, .huggingface, .turso,
        .baseten, .clickhouse, .linode, .runpod, .deepgram, .scaleway,
        .bunny, .grafana, .elastic, .datadog,
        .novita, .apify, .tavily, .deepinfra, .vastai, .firecrawl, .cockroach, .typesense,
        .aiven, .siliconflow, .aimlapi, .stepfun, .stepfunAI, .telnyx,
        .mariadb, .ionos, .upcloud, .confluent,
        .vonage, .plivo, .messagebird, .ibm,
        .clicksend, .infobip, .textmagic,
        .betterstack, .easypost, .transloadit,
        .api2pdf, .hetrixtools,
        .shipstation, .thanksio, .click2mail,
        .gelato, .prodigi, .qiniu, .mysendingbox,
        .stannp, .phaxio, .porkbun, .namecheap, .gandi,
        .shippo, .printful, .gooten, .easyship, .huaweicloud, .anthropic,
        .zilliz, .soniox, .voltagepark, .surrealdb,
        .simply, .domeneshop, .websupport, .active24,
        .northflank, .azion, .gcore, .elastx, .warpstream, .neo4j, .digicert, .klaviyo, .deel, .remote, .oyster, .outscale, .orangecloud, .gridscale, .rackspace, .pika, .hedra, .tidbcloud, .hyperstack, .hostup, .memset, .mittwald, .soracom, .starlink, .tibber, .once, .octopusenergy, .pge, .coned, .dynatrace, .zoom, .namecom, .ovhcloud, .sakuracloud, .akamai,
        .hostens, .binarylane, .tierpoint, .postman, .sevenbridges, .cmcom,
        .shipbob, .mikrocloud, .leaseweb, .qovery,
        .phoenixnap, .magalucloud,
        .transip, .serverscom, .flexport,
        .i3dnet, .datapacket, .cudocompute, .shipwell, .ocamba,
        .inferencesh, .voltview,
        .clevercloud, .utilityapi, .dnsimple, .latitudesh,
        .realtimeregister, .pdfshift, .alchemy, .friendli, .mixpeek, .typebot, .botpress, .vpsnet, .seeweb, .parasail,
        .bring, .armada, .mollie,
        .checkout, .printify, .teelaunch,
        .paypal, .paystack, .flutterwave,
        .openprovider, .stackit, .conoha,
        .zcomcloud, .idcf, .internetx, .melbicom,
        .time4vps, .bitlaunch, .hivelocity,
        .scalingo, .upsun,
        .ncloud, .nomos, .dnscale, .together,
        .formspring, .hostcircle, .loginet,
        .idcloudhost, .unleash, .glesys, .cloudsigma, .rediscloud,
        .iwinv, .frankenergie, .dilmune, .hubble,
        .filescom, .doit, .timeweb, .cloudheed, .sevalla, .catalystvm, .oxahost, .fiskil, .threeplguys, .pleo, .cerebrium, .shipmondo, .sendcloud, .alibabacloud, .volcengine, .kingsoftcloud, .tencentcloud, .make,
    ]

    public static func make(
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        httpClient: any HTTPClient,
        rateSource: SharedExchangeRates = SharedExchangeRates()
    ) -> [ProviderID: any BillingProvider] {
        var result: [ProviderID: any BillingProvider] = [:]
        for descriptor in ProviderCatalog.all {
            let id = descriptor.id
            if let live = liveProvider(
                id: id,
                now: now,
                calendar: calendar,
                httpClient: httpClient,
                rateSource: rateSource
            ) {
                result[id] = live
            }
        }
        return result
    }

    public static func liveProvider(
        id: ProviderID,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        httpClient: any HTTPClient,
        rateSource: SharedExchangeRates = SharedExchangeRates()
    ) -> (any BillingProvider)? {
        switch id {
        case .cloudflare:
            return CloudflareBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .neon:
            return NeonBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .openai:
            return OpenAIBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .anthropic:
            return AnthropicBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .vercel:
            return VercelBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .github:
            return GitHubBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .openrouter:
            return OpenRouterBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .deepseek:
            return DeepSeekBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .moonshot:
            return MoonshotBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .moonshotAI:
            return MoonshotAIBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .xai:
            return XAIBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .digitalocean:
            return DigitalOceanBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .twilio:
            return TwilioBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .planetscale:
            return PlanetScaleBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .upstash:
            return UpstashBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .elevenlabs:
            return ElevenLabsBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .railway:
            return RailwayBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .stripe:
            return StripeBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .resend:
            return ResendBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .posthog:
            return PostHogBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .sentry:
            return SentryBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .vultr:
            return VultrBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .fastly:
            return FastlyBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .exa:
            return ExaBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .atlas:
            return AtlasBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .azure:
            return AzureBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .polar:
            return PolarBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .heroku:
            return HerokuBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .revenuecat:
            return RevenueCatBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .qdrant:
            return QdrantBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mistral:
            return MistralBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .fireworks:
            return FireworksBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .fal:
            return FalBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .huggingface:
            return HuggingFaceBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .turso:
            return TursoBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .baseten:
            return BasetenBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .clickhouse:
            return ClickHouseBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .linode:
            return LinodeBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .runpod:
            return RunPodBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .deepgram:
            return DeepgramBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .scaleway:
            return ScalewayBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .bunny:
            return BunnyBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .grafana:
            return GrafanaBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .elastic:
            return ElasticBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .datadog:
            return DatadogBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .novita:
            return NovitaBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .apify:
            return ApifyBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .tavily:
            return TavilyBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .deepinfra:
            return DeepInfraBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .vastai:
            return VastAIBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .firecrawl:
            return FirecrawlBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .cockroach:
            return CockroachBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .typesense:
            return TypesenseBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .aiven:
            return AivenBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .siliconflow:
            return SiliconFlowBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .aimlapi:
            return AIMLAPIBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .stepfun:
            return StepFunBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .stepfunAI:
            return StepFunAIBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .telnyx:
            return TelnyxBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mariadb:
            return MariaDBCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .ionos:
            return IONOSCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .upcloud:
            return UpCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .confluent:
            return ConfluentBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .vonage:
            return VonageBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .plivo:
            return PlivoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .messagebird:
            return MessageBirdBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .ibm:
            return IBMCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .clicksend:
            return ClickSendBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .infobip:
            return InfobipBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .textmagic:
            return TextmagicBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )

        case .betterstack:
            return BetterStackBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .easypost:
            return EasyPostBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .transloadit:
            return TransloaditBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .api2pdf:
            return Api2PdfBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .hetrixtools:
            return HetrixToolsBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .shipstation:
            return ShipStationBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .thanksio:
            return ThanksIOBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .click2mail:
            return Click2MailBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .gelato:
            return GelatoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .prodigi:
            return ProdigiBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .qiniu:
            return QiniuBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mysendingbox:
            return MySendingBoxBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .stannp:
            return StannpBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .phaxio:
            return PhaxioBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .porkbun:
            return PorkbunBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .namecheap:
            return NamecheapBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .gandi:
            return GandiBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .shippo:
            return ShippoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .printful:
            return PrintfulBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .gooten:
            return GootenBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .easyship:
            return EasyshipBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .huaweicloud:
            return HuaweiCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .zilliz:
            return ZillizBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .soniox:
            return SonioxBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .voltagepark:
            return VoltageParkBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .surrealdb:
            return SurrealDBBillingProvider(httpClient: httpClient, now: now, calendar: calendar)
        case .simply:
            return SimplyBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .domeneshop:
            return DomeneshopBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .websupport:
            return WebsupportBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .active24:
            return Active24BillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .northflank:
            return NorthflankBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .azion:
            return AzionBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .gcore:
            return GcoreBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .elastx:
            return ElastxBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .warpstream:
            return WarpStreamBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar
            )
        case .neo4j:
            return Neo4jAuraBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar
            )
        case .digicert:
            return DigiCertBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .klaviyo:
            return KlaviyoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar
            )
        case .deel:
            return DeelBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .remote:
            return RemoteBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .oyster:
            return OysterBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .outscale:
            return OutscaleBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .orangecloud:
            return OrangeCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .gridscale:
            return GridscaleBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .rackspace:
            return RackspaceBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .pika:
            return PikaBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hedra:
            return HedraBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .tidbcloud:
            return TiDBCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hyperstack:
            return HyperstackBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hostup:
            return HostUpBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .memset:
            return MemsetBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mittwald:
            return MittwaldBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .soracom:
            return SoracomBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .starlink:
            return StarlinkBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .tibber:
            return TibberBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .once:
            return OnceBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .octopusenergy:
            return OctopusEnergyBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .pge:
            return PGEBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .coned:
            return ConEdBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .dynatrace:
            return DynatraceBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .zoom:
            return ZoomBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .namecom:
            return NameComBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .ovhcloud:
            return OVHCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .sakuracloud:
            return SakuraCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .akamai:
            return AkamaiBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hostens:
            return HostensBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .binarylane:
            return BinaryLaneBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .tierpoint:
            return TierPointBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .postman:
            return PostmanBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .sevenbridges:
            return SevenBridgesBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .cmcom:
            return CMComBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .shipbob:
            return ShipBobBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mikrocloud:
            return MikroCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .leaseweb:
            return LeasewebBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .qovery:
            return QoveryBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .phoenixnap:
            return PhoenixNAPBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .magalucloud:
            return MagaluCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .transip:
            return TransIPBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .serverscom:
            return ServersComBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .flexport:
            return FlexportBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .i3dnet:
            return I3DNetBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .datapacket:
            return DataPacketBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .cudocompute:
            return CUDOComputeBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .shipwell:
            return ShipwellBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .ocamba:
            return OcambaBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .inferencesh:
            return InferenceSHBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .voltview:
            return VoltViewBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .clevercloud:
            return CleverCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .utilityapi:
            return UtilityAPIBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .dnsimple:
            return DNSimpleBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .latitudesh:
            return LatitudeSHBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .realtimeregister:
            return RealtimeRegisterBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .pdfshift:
            return PDFShiftBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .alchemy:
            return AlchemyBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .friendli:
            return FriendliBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mixpeek:
            return MixpeekBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .typebot:
            return TypebotBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .botpress:
            return BotpressBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .vpsnet:
            return VPSNetBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .seeweb:
            return SeewebBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .parasail:
            return ParasailBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .bring:
            return BringBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .armada:
            return ArmadaBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .mollie:
            return MollieBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .checkout:
            return CheckoutBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .printify:
            return PrintifyBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .teelaunch:
            return TeelaunchBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .paypal:
            return PayPalBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .paystack:
            return PaystackBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .flutterwave:
            return FlutterwaveBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .openprovider:
            return OpenproviderBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .stackit:
            return StackitBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .conoha:
            return ConoHaBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .zcomcloud:
            return ZComCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .idcf:
            return IDCFBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .internetx:
            return InterNetXBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .melbicom:
            return MelbicomBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .time4vps:
            return Time4VPSBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .bitlaunch:
            return BitLaunchBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hivelocity:
            return HivelocityBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .scalingo:
            return ScalingoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .ncloud:
            return NCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .nomos:
            return NomosBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .dnscale:
            return DNScaleBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .formspring:
            return FormspringBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hostcircle:
            return HostcircleBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .loginet:
            return LoginetBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .idcloudhost:
            return IDCloudHostBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .unleash:
            return UnleashBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .glesys:
            return GleSYSBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .cloudsigma:
            return CloudSigmaBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .rediscloud:
            return RedisCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .iwinv:
            return IwinvBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .frankenergie:
            return FrankEnergieBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .dilmune:
            return DilmuneBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .hubble:
            return HubbleBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .filescom:
            return FilesComBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .doit:
            return DoitBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .timeweb:
            return TimewebBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .cloudheed:
            return CloudheedBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .sevalla:
            return SevallaBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .catalystvm:
            return CatalystVMBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .oxahost:
            return OxahostBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .fiskil:
            return FiskilBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .threeplguys:
            return ThreePLGuysBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .pleo:
            return PleoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .cerebrium:
            return CerebriumBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .shipmondo:
            return ShipmondoBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .sendcloud:
            return SendcloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .alibabacloud:
            return AlibabaCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .volcengine:
            return VolcengineBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .kingsoftcloud:
            return KingsoftCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .tencentcloud:
            return TencentCloudBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .make:
            return MakeBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .together:
            return TogetherBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        case .upsun:
            return UpsunBillingProvider(
                httpClient: httpClient, now: now, calendar: calendar, rateSource: rateSource
            )
        default:
            return nil
        }
    }
}
