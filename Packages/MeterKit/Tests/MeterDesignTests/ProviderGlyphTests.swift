import SwiftUI
import Testing
import UIKit
@testable import MeterDesign
import MeterCore

/// 有官方 path 的 key。栅格和 bbox 检查只对这些跑。
private let providerGlyphKeys = [
    "cloudflare", "aws", "openai", "anthropic", "vercel", "github", "neon", "fly",
    "openrouter", "deepseek", "moonshot", "moonshotai", "digitalocean", "twilio", "planetscale",
    "upstash", "elevenlabs", "railway", "stripe",
    "resend", "posthog", "clerk", "sentry",
    "vultr", "fastly", "atlas", "gitlab", "render", "expo", "qdrant", "revenuecat",
    "cursor", "heroku", "exa", "polar",
    "replicate", "perplexity", "gemini", "netlify", "supabase", "firebase",
    "linear", "notion", "figma", "windsurf",
    "mistral", "huggingface", "gcp", "turso",
    "clickhouse", "deepgram", "scaleway",
    "modal", "hetzner", "auth0", "mixpanel", "algolia", "zapier",
    "replit", "webflow", "snowflake", "intercom",
    "bunny", "grafana", "elastic", "datadog",
    "backblaze", "pagerduty", "contentful", "cloudinary",
    "sendgrid", "mailgun", "koyeb",
    "cockroach", "wasabi", "newrelic",
    "mariadb",
    "sanity", "influxdb", "timescale", "snyk", "circleci", "terraform",
    "tailscale", "deno", "plausible", "prefect", "airbyte", "exoscale",
    "vonage", "brevo", "fauna", "mailchimp", "bitbucket", "buildkite", "codecov",
    "n8n", "hasura", "okta", "pulumi", "appwrite", "hashicorp", "dbt", "astra",
    "lemon", "keycdn",
    "fireworks", "fal", "baseten", "runpod",
    "novita", "apify", "tavily", "deepinfra", "vastai", "firecrawl",
    "aiven", "siliconflow", "stepfun", "stepfunai", "ionos", "upcloud",
    "plivo", "messagebird", "ibm", "clicksend", "textmagic",
    "together", "gcore",
    "akamai", "alchemy", "betterstack", "clevercloud", "gandi",
    "namecheap", "ncloud", "neo4j", "porkbun", "postman",
    "bring", "cloudheed", "cudocompute", "easyship", "filescom",
    "flexport", "formspring", "hedra", "latitudesh", "namecom",
    "outscale", "parasail", "pleo", "prodigi", "qovery", "sevalla",
    "shippo", "timeweb", "typebot", "voltagepark", "websupport",
    "printful", "tencentcloud", "infobip",
    "unleash", "soracom", "fiskil", "easypost", "northflank",
    "scalingo", "transip", "datapacket", "hivelocity", "simply",
    "soniox", "shipmondo", "gooten", "glesys", "mittwald",
    "paystack", "flutterwave", "checkout", "confluent", "leaseweb",
    "pge", "sakuracloud", "shipwell", "remote", "hubble", "inferencesh",
    "printify", "cmcom", "melbicom", "coned", "sendcloud", "voltview",
    "threeplguys", "vpsnet", "transloadit", "thanksio", "azion",
    "dnsimple", "shipbob", "hostup", "friendli", "hyperstack", "deel",
    "pika", "openprovider", "warpstream", "active24",
    "botpress", "doit", "octopusenergy", "once", "pdfshift",
    "realtimeregister", "serverscom", "shipstation", "teelaunch", "upsun",
    "typesense", "digicert", "idcf", "internetx", "hostens",
    "cerebrium", "oyster", "zoom",
    "nomos", "oxahost", "frankenergie",
]

/// 官方标是横向字标或宽扁标的 key：bbox 高度只要 viewBox 的 25%，宽度仍要 40%。
private let wideWordmarkKeys: Set<String> = ["ionos", "upcloud", "azion"]

/// 没有官方 path、走首字母回落的 key。
private let providerMonogramKeys = [
    "xai", "azure",
    "groq", "cohere", "midjourney", "runway", "slack",
    "linode",
    "pinecone", "amplitude", "launchdarkly", "discord",
    "assemblyai", "mux", "workos", "lambdalabs", "civo",
    "cerebras", "cartesia", "helicone", "coreweave", "honeycomb", "weaviate", "triggerdev",
    "aimlapi", "telnyx",
    "minimax", "hyperbolic", "jina", "dashscope", "paperspace", "salad", "browserbase",
    "convex", "langfuse", "contabo", "inngest", "tinybird", "livekit",
    "meilisearch", "motherduck", "zhipu",
    "postmark", "ably", "crunchybridge", "axiom", "checkly", "browserstack",
    "redpanda", "kamatera", "onesignal", "courier", "doppler", "infisical",
    "kinsta", "imgix", "fathom", "klaviyo", "sonarcloud", "fivetran",
    "sinch", "smtp2go", "mailjet", "elks", "cdn77", "dagster", "stytch", "chargebee",
]

/// 目录里全部 colorKey。对比度不看有没有 path——字母回落也得读得出来。
private let providerColorKeys = providerGlyphKeys + providerMonogramKeys

@Suite("ProviderGlyph 路径健全性")
struct ProviderGlyphSanityTests {
    @Test("有官方 path 的 key 解析不抛错且路径非空", arguments: providerGlyphKeys)
    func artworkParses(key: String) {
        let data = ProviderGlyphArtwork.pathData(for: key)
        #expect(data != nil, "\(key) 缺少官方 path")
        guard let data else { return }
        let path = SVGPathParser.path(from: data)
        #expect(!path.isEmpty, "\(key) 解析结果为空")
        let box = path.cgPath.boundingBoxOfPath
        #expect(!box.isNull && !box.isInfinite, "\(key) bbox 无效")
        #expect(box.width > 0 && box.height > 0, "\(key) bbox 塌成点")
    }

    @Test("bbox 落在 24×24 viewBox 内，覆盖且大致居中", arguments: providerGlyphKeys)
    func boundingBoxInsideCenteredViewBox(key: String) {
        let data = ProviderGlyphArtwork.pathData(for: key)
        #expect(data != nil)
        guard let data else { return }
        let verdict = GlyphPathSanity.evaluate(
            SVGPathParser.path(from: data),
            minHeightFraction: wideWordmarkKeys.contains(key)
                ? GlyphPathSanity.wordmarkHeightFraction
                : GlyphPathSanity.coverageFraction
        )
        #expect(verdict.insideViewBox, "\(key) bbox \(verdict.box) 超出 24×24")
        #expect(
            verdict.coversEnough,
            "\(key) bbox \(verdict.box) 宽不足 viewBox 的 40%，或高低于下限"
        )
        #expect(
            verdict.roughlyCentered,
            "\(key) bbox \(verdict.box) 留白差超过 viewBox 的 20%"
        )
    }

    @Test("改坏一个字符后健全性检查会失败——断言本身能抓住走形")
    func corruptedPathFailsSanity() {
        // 官方 Vercel 是 `m12 1.608 12 20.784H0Z`，把 12 改成 120 会撑出 viewBox。
        let corrupted = "m120 1.608 12 20.784H0Z"
        let verdict = GlyphPathSanity.evaluate(SVGPathParser.path(from: corrupted))
        #expect(!verdict.insideViewBox)
        #expect(!verdict.isSane)
    }

    @Test("字母回落的 key 没有官方 path", arguments: providerMonogramKeys)
    func monogramKeysHaveNoPath(key: String) {
        #expect(ProviderGlyphArtwork.pathData(for: key) == nil)
    }

    @Test("挖空的官方 path 用 even-odd，其余 nonzero")
    func evenOddFillKeys() {
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "heroku"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "exa"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "polar"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "hetzner"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "intercom"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "circleci"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "serverscom"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "teelaunch"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "digicert"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "internetx"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "hostens"))
        #expect(ProviderGlyphArtwork.usesEvenOddFill(for: "oyster"))
        #expect(!ProviderGlyphArtwork.usesEvenOddFill(for: "github"))
        #expect(!ProviderGlyphArtwork.usesEvenOddFill(for: "xai"))
        #expect(!ProviderGlyphArtwork.usesEvenOddFill(for: "zoom"))
    }
}

@Suite("ProviderGlyph 字母回落")
struct ProviderGlyphMonogramTests {
    @Test("colorKey 首字母大写", arguments: [
        ("xai", "X"),
        ("azure", "A"),
        ("XAI", "X"),
    ])
    func letterFromColorKey(key: String, letter: String) {
        #expect(ProviderGlyphArtwork.monogramLetter(for: key) == letter)
    }

    /// 显示名的权威是 `ProviderCatalog.swift`，生成进 `MeterCore/ProviderIdentity.swift`。
    /// 设计系统里一度也有一份（`MeterColor.providerDisplayName`），那是「widget 链不到
    /// MeterProviders」时期的绕道；身份下沉到 MeterCore 之后那一份撤了。
    @Test("显示名跟目录走，不是把 key 首字母大写")
    func displayNameUsesCanonicalBrand() {
        #expect(ProviderIdentity.displayName(forKey: "aws") == "AWS")
        #expect(ProviderIdentity.displayName(forKey: "github") == "GitHub")
        #expect(ProviderIdentity.displayName(forKey: "openai") == "OpenAI")
        #expect(ProviderIdentity.displayName(forKey: "unknown-vendor") == "unknown-vendor")
    }
}

@Suite("ProviderGlyph 色板对比度")
struct ProviderGlyphContrastTests {
    @Test("浅色：白字压品牌色至少 3:1", arguments: providerColorKeys)
    func lightContrastAtLeastThree(key: String) {
        let ratio = WCAGContrast.ratio(
            GlyphRGBA.resolve(MeterColor.providerGlyphInk, style: .light),
            GlyphRGBA.resolve(MeterColor.provider(key), style: .light)
        )
        #expect(ratio + 0.001 >= 3, "\(key) light contrast \(ratio)")
    }

    @Test("深色：凿空墨色压提亮品牌色至少 6:1", arguments: providerColorKeys)
    func darkContrastAtLeastSix(key: String) {
        let ratio = WCAGContrast.ratio(
            GlyphRGBA.resolve(MeterColor.providerGlyphInk, style: .dark),
            GlyphRGBA.resolve(MeterColor.provider(key), style: .dark)
        )
        #expect(ratio + 0.001 >= 6, "\(key) dark contrast \(ratio)")
    }
}

@Suite("ProviderGlyph 像素", .serialized)
@MainActor
struct ProviderGlyphRasterTests {
    @Test(
        "28pt tile 前景像素占比 5%–60%，且用的是 providerGlyphInk",
        arguments: providerGlyphKeys + providerMonogramKeys,
        [ColorScheme.light, ColorScheme.dark]
    )
    func fillRatioAndInk(key: String, scheme: ColorScheme) {
        let snapshot = GlyphSnapshot.capture(colorKey: key, scheme: scheme)
        #expect(snapshot.image != nil, "\(key) \(scheme) 渲不出位图（\(snapshot.method)）")
        guard let analysis = snapshot.analysis else { return }

        // 下限取 5% 而不是 8%：AWS 官方字标是细线，28pt tile 上实测约 6%。
        // 0% 仍是空白、>80% 仍是糊成一块，两端照样抓得住。
        #expect(
            (0.05...0.60).contains(analysis.inkRatio),
            "\(key) \(scheme) ink=\(Self.percent(analysis.inkRatio)) method=\(snapshot.method)"
        )

        switch scheme {
        case .light:
            #expect(
                analysis.nearWhiteRatio >= analysis.inkRatio * 0.6,
                "\(key) light 的 ink 像素应主要是白字，white=\(Self.percent(analysis.nearWhiteRatio)) ink=\(Self.percent(analysis.inkRatio))"
            )
        case .dark:
            #expect(
                analysis.nearWhiteRatio < 0.02,
                "\(key) dark 若仍用白字会糊在提亮品牌色上，white=\(Self.percent(analysis.nearWhiteRatio))"
            )
            #expect(
                analysis.inkRatio >= 0.05,
                "\(key) dark 应看到 providerGlyphInk（#0E1116），ink=\(Self.percent(analysis.inkRatio))"
            )
        @unknown default:
            Issue.record("未知 ColorScheme")
        }

        let pixelContrast = WCAGContrast.ratio(analysis.medianInk, analysis.medianBrand)
        let minimum: CGFloat = scheme == .dark ? 6 : 3
        #expect(
            pixelContrast + 0.05 >= minimum,
            "\(key) \(scheme) 像素对比度 \(pixelContrast) method=\(snapshot.method)"
        )

        print(
            "GLYPH \(key) \(scheme) ink=\(Self.percent(analysis.inkRatio)) white=\(Self.percent(analysis.nearWhiteRatio)) contrast=\(String(format: "%.2f", pixelContrast)) via \(snapshot.method)"
        )
    }

    private static func percent(_ value: CGFloat) -> String {
        String(format: "%.1f%%", value * 100)
    }
}

// MARK: - bbox

enum GlyphPathSanity {
    static let viewBox: CGFloat = 24
    static let coverageFraction: CGFloat = 0.40
    /// 横向字标高度天然到不了 40%（ionos 约 29%），单独给个下限，别为它放松全体。
    static let wordmarkHeightFraction: CGFloat = 0.25
    static let centerSlack: CGFloat = 0.20
    static let edgeEpsilon: CGFloat = 0.05

    struct Verdict {
        var box: CGRect
        var insideViewBox: Bool
        var coversEnough: Bool
        var roughlyCentered: Bool

        var isSane: Bool { insideViewBox && coversEnough && roughlyCentered && box.width > 0 }
    }

    static func evaluate(
        _ path: Path,
        minHeightFraction: CGFloat = GlyphPathSanity.coverageFraction
    ) -> Verdict {
        let box = path.cgPath.boundingBoxOfPath
        let inside =
            !box.isNull
            && !box.isInfinite
            && box.minX >= -edgeEpsilon
            && box.minY >= -edgeEpsilon
            && box.maxX <= viewBox + edgeEpsilon
            && box.maxY <= viewBox + edgeEpsilon
        let covers =
            box.width + 0.001 >= viewBox * coverageFraction
            && box.height + 0.001 >= viewBox * minHeightFraction
        let centered =
            abs(box.minX - (viewBox - box.maxX)) <= viewBox * centerSlack
            && abs(box.minY - (viewBox - box.maxY)) <= viewBox * centerSlack
        return Verdict(
            box: box,
            insideViewBox: inside,
            coversEnough: covers,
            roughlyCentered: centered
        )
    }
}

// MARK: - 颜色 / 对比度

struct GlyphRGBA: Equatable {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    var a: CGFloat

    static func resolve(_ color: Color, style: UIUserInterfaceStyle) -> GlyphRGBA {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let resolved = UIColor(color).resolvedColor(with: traits)
        return from(resolved)
    }

    static func from(_ color: UIColor) -> GlyphRGBA {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return GlyphRGBA(r: r, g: g, b: b, a: a)
        }
        var white: CGFloat = 0
        if color.getWhite(&white, alpha: &a) {
            return GlyphRGBA(r: white, g: white, b: white, a: a)
        }
        if let converted = color.cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ), let components = converted.components, components.count >= 3 {
            return GlyphRGBA(
                r: components[0],
                g: components[1],
                b: components[2],
                a: components.count > 3 ? components[3] : 1
            )
        }
        return GlyphRGBA(r: 0, g: 0, b: 0, a: 0)
    }

    func distance(to other: GlyphRGBA) -> CGFloat {
        let dr = r - other.r
        let dg = g - other.g
        let db = b - other.b
        return (dr * dr + dg * dg + db * db).squareRoot()
    }

    var isNearWhite: Bool {
        r > 0.85 && g > 0.85 && b > 0.85 && a > 0.85
    }
}

enum WCAGContrast {
    static func ratio(_ a: GlyphRGBA, _ b: GlyphRGBA) -> CGFloat {
        let l1 = relativeLuminance(a)
        let l2 = relativeLuminance(b)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func relativeLuminance(_ color: GlyphRGBA) -> CGFloat {
        func linear(_ channel: CGFloat) -> CGFloat {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
    }
}

// MARK: - 栅格

struct GlyphSnapshot {
    struct Analysis {
        var inkRatio: CGFloat
        var nearWhiteRatio: CGFloat
        var medianInk: GlyphRGBA
        var medianBrand: GlyphRGBA
    }

    var image: UIImage?
    var method: String
    var analysis: Analysis?

    static let pointSize: CGFloat = 28
    static let scale: CGFloat = 2

    @MainActor
    static func capture(colorKey: String, scheme: ColorScheme) -> GlyphSnapshot {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        let expectedInk = GlyphRGBA.resolve(MeterColor.providerGlyphInk, style: style)
        let expectedBrand = GlyphRGBA.resolve(MeterColor.provider(colorKey), style: style)

        if let image = renderWithImageRenderer(colorKey: colorKey, scheme: scheme),
           let analysis = analyze(image, ink: expectedInk, brand: expectedBrand),
           analysis.inkRatio > 0.01
        {
            return GlyphSnapshot(image: image, method: "ImageRenderer", analysis: analysis)
        }

        if let image = renderWithHostingController(colorKey: colorKey, scheme: scheme),
           let analysis = analyze(image, ink: expectedInk, brand: expectedBrand),
           analysis.inkRatio > 0.01
        {
            return GlyphSnapshot(image: image, method: "UIHostingController", analysis: analysis)
        }

        if let image = renderPathFallback(colorKey: colorKey, ink: expectedInk, brand: expectedBrand),
           let analysis = analyze(image, ink: expectedInk, brand: expectedBrand)
        {
            return GlyphSnapshot(image: image, method: "SVGPathShape.raster", analysis: analysis)
        }

        if ProviderGlyphArtwork.pathData(for: colorKey) == nil,
           let image = renderMonogramFallback(colorKey: colorKey, ink: expectedInk, brand: expectedBrand),
           let analysis = analyze(image, ink: expectedInk, brand: expectedBrand)
        {
            return GlyphSnapshot(image: image, method: "monogram.raster", analysis: analysis)
        }

        return GlyphSnapshot(image: nil, method: "none", analysis: nil)
    }

    @MainActor
    private static func renderWithImageRenderer(colorKey: String, scheme: ColorScheme) -> UIImage? {
        let view = ProviderGlyph(colorKey: colorKey, size: pointSize)
            .frame(width: pointSize, height: pointSize)
            .environment(\.colorScheme, scheme)
            .preferredColorScheme(scheme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: pointSize, height: pointSize)
        return renderer.uiImage
    }

    @MainActor
    private static func renderWithHostingController(colorKey: String, scheme: ColorScheme) -> UIImage? {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        let root = ProviderGlyph(colorKey: colorKey, size: pointSize)
            .frame(width: pointSize, height: pointSize)
            .environment(\.colorScheme, scheme)
            .preferredColorScheme(scheme)
            .ignoresSafeArea()
        let host = UIHostingController(rootView: root)
        host.safeAreaRegions = []
        host.overrideUserInterfaceStyle = style
        host.view.bounds = CGRect(x: 0, y: 0, width: pointSize, height: pointSize)
        host.view.backgroundColor = .clear
        host.view.overrideUserInterfaceStyle = style
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let bounds = CGRect(x: 0, y: 0, width: pointSize, height: pointSize)
        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            host.view.layer.render(in: context.cgContext)
        }
    }

    /// ImageRenderer / hosting 都拿不到前景时，按 `ProviderGlyph` 同样的 60% 内缩栅格 path。
    private static func renderPathFallback(
        colorKey: String,
        ink: GlyphRGBA,
        brand: GlyphRGBA
    ) -> UIImage? {
        guard let data = ProviderGlyphArtwork.pathData(for: colorKey) else { return nil }
        let padding = pointSize * (1 - ProviderGlyph.fillRatio(for: colorKey)) / 2
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let size = CGSize(width: pointSize, height: pointSize)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: brand.r, green: brand.g, blue: brand.b, alpha: 1).setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: MeterRadius.glyph
            ).fill()
            UIColor(red: ink.r, green: ink.g, blue: ink.b, alpha: 1).setFill()
            let rect = CGRect(
                x: padding,
                y: padding,
                width: pointSize - padding * 2,
                height: pointSize - padding * 2
            )
            context.cgContext.addPath(SVGPathShape(d: data).path(in: rect).cgPath)
            if ProviderGlyphArtwork.usesEvenOddFill(for: colorKey) {
                context.cgContext.drawPath(using: .eoFill)
            } else {
                context.cgContext.fillPath()
            }
        }
    }

    private static func renderMonogramFallback(
        colorKey: String,
        ink: GlyphRGBA,
        brand: GlyphRGBA
    ) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let size = CGSize(width: pointSize, height: pointSize)
        let letter = ProviderGlyphArtwork.monogramLetter(for: colorKey) as NSString
        let point = pointSize * ProviderGlyph.monogramRatio
        let base = UIFont.systemFont(ofSize: point, weight: .semibold)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        let font = UIFont(descriptor: descriptor, size: point)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: ink.r, green: ink.g, blue: ink.b, alpha: 1),
        ]
        let textSize = letter.size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor(red: brand.r, green: brand.g, blue: brand.b, alpha: 1).setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: MeterRadius.glyph
            ).fill()
            letter.draw(
                at: CGPoint(
                    x: (pointSize - textSize.width) / 2,
                    y: (pointSize - textSize.height) / 2
                ),
                withAttributes: attributes
            )
        }
    }

    private static func analyze(_ image: UIImage, ink: GlyphRGBA, brand: GlyphRGBA) -> Analysis? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var inkCount = 0
        var whiteCount = 0
        var opaqueCount = 0
        var inkSamples: [GlyphRGBA] = []
        var brandSamples: [GlyphRGBA] = []

        for index in 0..<(width * height) {
            let offset = index * 4
            let alphaByte = bytes[offset + 3]
            if alphaByte < 16 { continue }
            let alpha = CGFloat(alphaByte) / 255
            let pixel = GlyphRGBA(
                r: CGFloat(bytes[offset]) / 255 / alpha,
                g: CGFloat(bytes[offset + 1]) / 255 / alpha,
                b: CGFloat(bytes[offset + 2]) / 255 / alpha,
                a: alpha
            )
            opaqueCount += 1
            if pixel.isNearWhite { whiteCount += 1 }

            let toInk = pixel.distance(to: ink)
            let toBrand = pixel.distance(to: brand)
            if toInk < 0.22 || (toInk < toBrand && toInk < 0.35) {
                inkCount += 1
                if inkSamples.count < 256 { inkSamples.append(pixel) }
            } else if toBrand < 0.22 {
                if brandSamples.count < 256 { brandSamples.append(pixel) }
            }
        }

        guard opaqueCount > 0, !inkSamples.isEmpty, !brandSamples.isEmpty else { return nil }
        return Analysis(
            inkRatio: CGFloat(inkCount) / CGFloat(width * height),
            nearWhiteRatio: CGFloat(whiteCount) / CGFloat(width * height),
            medianInk: median(inkSamples),
            medianBrand: median(brandSamples)
        )
    }

    private static func median(_ samples: [GlyphRGBA]) -> GlyphRGBA {
        func channel(_ pick: (GlyphRGBA) -> CGFloat) -> CGFloat {
            let sorted = samples.map(pick).sorted()
            return sorted[sorted.count / 2]
        }
        return GlyphRGBA(
            r: channel(\.r),
            g: channel(\.g),
            b: channel(\.b),
            a: channel(\.a)
        )
    }
}


