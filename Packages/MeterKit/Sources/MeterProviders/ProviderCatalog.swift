import Foundation
import MeterCore

/// 静态描述。URL 全部写死在这里，见 `ProviderDescriptor` 的安全红线。
public enum ProviderCatalog: Sendable {
    public static let all: [ProviderDescriptor] = [
        cloudflare, neon, aws, openai, anthropic, vercel, github, fly,
        openrouter, deepseek, moonshot, moonshotAI, xai, cursor,
        digitalocean, twilio, planetscale, upstash, elevenlabs,
        railway, stripe, resend, posthog, clerk, sentry,
        vultr, fastly, exa, atlas, azure, polar, heroku,
        revenuecat, gitlab, render, qdrant, expo,
        groq, together, replicate, perplexity, cohere, gemini,
        midjourney, runway, netlify, supabase, firebase,
        linear, notion, figma, slack, windsurf,
        mistral, fireworks, fal, huggingface, turso, gcp,
        baseten, clickhouse, linode, runpod, deepgram, scaleway,
        pinecone, modal, hetzner, auth0, mixpanel, amplitude, launchdarkly,
        algolia, zapier, discord, replit, webflow, snowflake, intercom,
        bunny, grafana, elastic, datadog,
        backblaze, assemblyai, mux, civo, koyeb, pagerduty, workos,
        contentful, cloudinary, sendgrid, mailgun, lambdalabs,
        novita, apify, tavily, deepinfra, vastai, firecrawl, cockroach, typesense,
        cerebras, cartesia, helicone, wasabi, coreweave, honeycomb, newrelic,
        weaviate, triggerdev,
        aiven, siliconflow, aimlapi, stepfun, stepfunAI, telnyx,
        minimax, hyperbolic, jina, dashscope, paperspace, salad, browserbase,
        convex, langfuse, gcore, contabo, northflank, inngest, tinybird, livekit,
        meilisearch, motherduck, zhipu,
        mariadb, ionos, upcloud, confluent,
        postmark, sanity, ably, crunchybridge, influxdb, axiom, checkly, timescale,
        browserstack, snyk, circleci, terraform, tailscale, deno, plausible, prefect,
        airbyte, exoscale,
        vonage, plivo, messagebird, ibm,
        brevo, redpanda, fauna, kamatera, onesignal, courier, doppler, infisical,
        kinsta, imgix, fathom, mailchimp, klaviyo, bitbucket, buildkite, codecov,
        sonarcloud, fivetran,
        clicksend, infobip, textmagic,
        betterstack, easypost, transloadit,
        sinch, smtp2go, mailjet, n8n, hasura, elks, keycdn, cdn77, astra, dagster,
        dbt, pulumi, hashicorp, appwrite, stytch, okta, chargebee, lemon,
        mapbox, googlemaps, docusign, typeform, kit,
        shipstation, thanksio, click2mail,
        api2pdf, hetrixtools,
        gelato, prodigi, qiniu, mysendingbox,
        stannp, phaxio, porkbun, namecheap, gandi,
        shippo, printful, gooten, easyship, huaweicloud,
        zilliz, soniox, quay, glesys, vpsnet, cloudsigma,
        voltagepark, surrealdb,
        smsc, openprovider, realtimeregister, stackit, unleash, rediscloud, pdfshift,
        simply, domeneshop, websupport, active24,
        azion, elastx, warpstream, neo4j, digicert, deel, remote, oyster, outscale, orangecloud, gridscale, rackspace, pika, hedra, tidbcloud, hyperstack, hostup, memset, mittwald, soracom, starlink, tibber, once, octopusenergy, pge, coned, dynatrace, zoom, namecom, ovhcloud, sakuracloud, akamai,
        hostens, binarylane, tierpoint, postman, sevenbridges, cmcom,
        shipbob, mikrocloud, leaseweb, qovery,
        phoenixnap, magalucloud,
        transip, serverscom, flexport,
        i3dnet, datapacket, cudocompute, shipwell, ocamba, inferencesh, voltview,
        clevercloud, utilityapi, dnsimple, latitudesh,
        alchemy, friendli, mixpeek, typebot, botpress, seeweb, parasail,
        bring, armada, mollie,
        checkout, printify, teelaunch,
        paypal, paystack, flutterwave,
        conoha,
        zcomcloud, idcf, internetx, melbicom,
        time4vps, bitlaunch, hivelocity,
        scalingo, upsun,
        ncloud, nomos, dnscale,
        formspring, hostcircle, loginet,
        idcloudhost,
        iwinv, frankenergie, dilmune, hubble,
        filescom, doit, timeweb, cloudheed, sevalla, catalystvm, oxahost, fiskil, threeplguys, pleo, cerebrium, shipmondo, sendcloud, alibabacloud, volcengine, kingsoftcloud, tencentcloud, make,
        amberelectric, shiphero, worldstream, imprezahost, bitwarden, sematext, crusoe, here, bluerocktel, ucloud,
        qingcloud, ctyun, ecloud, zenlayer, selectel, storyblok, elasticemail, baiducloud, jdcloud, apivideo,
        bitmovin, airtable, clickup, asana, zendesk, customerio, activecampaign, canva, hostinger, kakaocloud,
        mercari, linedevelopers, cybozu, onepassword, lastpass, duo, aftership, dhl, fedex, ups,
        royalmail, parcel2go, dpd, gls, appdynamics, infomaniak, webdock, cubbit, beehiiv, packiyo,
        greenely, gorgias, jwplayer, cachefly, cherryservers, sav, hover, epik, eurodns, mezmo,
        chronosphere, highlight, ultahost, hostpresto, whiplash, customcat, printedmint, shineon, eneco, locaweb,
        termina, withflex, requestfinance, extensiv, packlink, shippingbo, boxtal, myparcel, webshipper, coolrunner,
        billbee, beam, inferless, fluidstack, shadeform, thundercompute, tensordock, anyscale, ai21, sambanova,
        wandb, clarifai, easydns, binero, dogado, monday, teachable, thinkific, hex, mode,
        sigma, looker, statuspage, incidentio, rootly, cloudhealth, apptio, kubecost, softbankcloud, yahoojpcloud,
        nttdocomo, otc, statsig, noonahq, googleads, metabusiness, microsoftads, nebius, temporal, yandexcloud,
        oracleoci, pliant, atlassian, bandwidth, megaport, edf, eonnext, engie, vattenfall, britishgas,
        travelperk, payhawk, moss, soldo, ramp, brex, hubspot, shopifypartner, bigcommerce, salesforce,
        servicenow, workday, rippling, gusto, wefact, lago, factuarea, spaceinvoices, beel, invoiced,
        moneybird, economic, tripletex, fortnox, visma, fyatu, smsglobal, burstsms, serverspace, tilaa,
        qonto, factorial, personio, pandadoc, dropboxsign, adobevip, spendesk,
    ]

    /// 产品列表用这份。不接入的家仍在 `all` 里，画廊能看到图标和理由。
    public static var offered: [ProviderDescriptor] {
        all.filter(\.isOffered)
    }

    private static let index: [ProviderID: ProviderDescriptor] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func descriptor(id: ProviderID) -> ProviderDescriptor? {
        index[id]
    }
}
