import Foundation
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
import MeterTips

struct OutboundHostsTests {
    @Test("目录里每家 descriptor 的 host 都在出站清单里")
    func catalogHostsAreDeclared() {
        let urls = ProviderCatalog.all.flatMap { descriptor -> [URL] in
            [descriptor.billingURL, descriptor.credentialSetupURL].compactMap { $0 }
                + Array(descriptor.guideURLs.values)
        }
        #expect(!urls.isEmpty)
        for url in urls {
            let host = url.host
            #expect(host != nil, "missing host in \(url.absoluteString)")
            if let host {
                #expect(
                    OutboundHosts.declaredHosts.contains(host),
                    "\(host) from \(url.absoluteString) is not in OutboundHosts.all"
                )
            }
        }
    }

    @Test("打赏 Worker 的 host 在出站清单里，且与 TipWorkerEndpoint 是同一份")
    func tipWorkerHostIsDeclared() {
        let host = TipWorkerEndpoint.origin.host
        #expect(host != nil)
        #expect(host?.isEmpty == false)
        if let host {
            #expect(
                OutboundHosts.declaredHosts.contains(host),
                "TipWorkerEndpoint host \(host) is not in OutboundHosts.all"
            )
        }
        #expect(OutboundHosts.contains(TipWorkerEndpoint.origin))
        #expect(OutboundHosts.contains(TipWorkerEndpoint.tipURL))
        #expect(OutboundHosts.contains(CatalogEndpoint.catalogURL))
    }

    @Test("关于页那份清单没有 mock 占位，也没有重复 host")
    func declaredListIsWhatUsersSee() {
        let hosts = OutboundHosts.all.map(\.host)
        #expect(Set(hosts).count == hosts.count)
        #expect(OutboundHosts.reservedHosts.isDisjoint(with: OutboundHosts.declaredHosts))
        #expect(OutboundHosts.reservedHosts.contains("example.invalid"))
        #expect(OutboundHosts.reservedHosts.contains("meter.invalid"))
        #expect(!OutboundHosts.declaredHosts.contains("example.invalid"))
        #expect(!OutboundHosts.declaredHosts.contains("meter.invalid"))
    }

    @Test("只有某个壳会连的域名：别的壳既不列在关于页，也不进白名单")
    func shellScopedHostsAreFilteredOut() {
        let macOnly = OutboundHosts.all.filter { $0.scope == .macDirectRelease }
        // 现在正好一支：Sparkle 的更新包下载。删空了说明作用域被人抹平，这里要红。
        #expect(!macOnly.isEmpty)
        for item in macOnly {
            #if os(macOS)
            #expect(item.isActiveHere)
            #expect(OutboundHosts.declaredHosts.contains(item.host))
            #else
            #expect(!item.isActiveHere)
            #expect(!OutboundHosts.declaredHosts.contains(item.host))
            #expect(!OutboundHosts.visible.contains { $0.host == item.host })
            #endif
        }
        // 全端那几支两边都在，作用域不是把清单切碎。
        #expect(OutboundHosts.visible.contains { $0.host == "api.tollcat.app" })
        #expect(OutboundHosts.visible.contains { $0.host == "github.com" })
        #expect(OutboundHosts.visible.count <= OutboundHosts.all.count)
    }

    @Test("接了 live 取数各家的 API host 都已声明")
    func providerAPIHostsAreDeclared() {
        let apiHosts: Set<String> = [
            "api.cloudflare.com",
            "console.neon.tech",
            "ce.us-east-1.amazonaws.com",
            "api.openai.com",
            "api.anthropic.com",
            "api.vercel.com",
            "api.github.com",
            "openrouter.ai",
            "api.deepseek.com",
            "api.moonshot.cn",
            "api.moonshot.ai",
            "management-api.x.ai",
            "api.digitalocean.com",
            "api.twilio.com",
            "api.planetscale.com",
            "api.upstash.com",
            "api.elevenlabs.io",
            "backboard.railway.com",
            "api.stripe.com",
            "api.resend.com",
            "us.posthog.com",
            "eu.posthog.com",
            "sentry.io",
            "api.vultr.com",
            "api.fastly.com",
            "admin-api.exa.ai",
            "cloud.mongodb.com",
            "login.microsoftonline.com",
            "management.azure.com",
            "api.polar.sh",
            "api.heroku.com",
            "api.revenuecat.com",
            "api.cloud.qdrant.io",
            "api.mistral.ai",
            "api.fireworks.ai",
            "api.fal.ai",
            "huggingface.co",
            "api.turso.tech",
            "api.baseten.co",
            "api.clickhouse.cloud",
            "api.linode.com",
            "api.runpod.io",
            "api.deepgram.com",
            "api.scaleway.com",
            "api.bunny.net",
            "grafana.com",
            "cloud.elastic.co",
            "api.datadoghq.com",
            "api.datadoghq.eu",
            "api.us3.datadoghq.com",
            "api.us5.datadoghq.com",
            "api.ap1.datadoghq.com",
            "api.ap2.datadoghq.com",
            "api.uk1.datadoghq.com",
            "api.novita.ai",
            "api.apify.com",
            "api.tavily.com",
            "api.deepinfra.com",
            "console.vast.ai",
            "api.firecrawl.dev",
            "cockroachlabs.cloud",
            "cloud.typesense.org",
            "api.aiven.io",
            "api.siliconflow.cn",
            "api.aimlapi.com",
            "api.stepfun.com",
            "api.stepfun.ai",
            "api.telnyx.com",
            "api.skysql.com",
            "api.ionos.com",
            "api.upcloud.com",
            "api.confluent.cloud",
            "rest.nexmo.com",
            "api.plivo.com",
            "rest.messagebird.com",
            "iam.cloud.ibm.com",
            "billing.cloud.ibm.com",
            "rest.clicksend.com",
            "api.infobip.com",
            "rest.textmagic.com",
        ]
        #expect(apiHosts.isSubset(of: OutboundHosts.declaredHosts))
    }

    @Test("没接 live 的那几家不声明 API host：关于页不该列用不上的域名")
    func inactiveProvidersDeclareNoAPIHost() {
        #expect(!OutboundHosts.declaredHosts.contains("api.render.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.expo.dev"))
        #expect(!OutboundHosts.declaredHosts.contains("api.clerk.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.fly.io"))
        #expect(!OutboundHosts.declaredHosts.contains("cloudbilling.googleapis.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.slack.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.notion.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.figma.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.supabase.com"))
        #expect(!OutboundHosts.declaredHosts.contains("api.linear.app"))
        #expect(!OutboundHosts.declaredHosts.contains("api.pulumi.com"))
    }
}
