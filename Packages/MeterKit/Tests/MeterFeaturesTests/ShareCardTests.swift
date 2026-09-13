import CoreImage
import Foundation
import SwiftUI
import Testing
import MeterCore
import MeterDesign
import MeterPersistence
import MeterProviders
@testable import MeterFeatures
@testable import MeterModules

@MainActor
struct ShareCardTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))! }

    private func monthToDate(changeRatio: Double? = 0.18) -> MonthToDate {
        MonthToDate(
            totalUSD: Money(usd: Decimal(string: "47.20")!),
            projectedMonthEndUSD: Money(usd: 94),
            confidence: .estimated,
            estimatedAccounts: [AccountID.fixture(for: .aws)],
            facts: [],
            changeRatio: changeRatio,
            variableUSD: Money(usd: Decimal(string: "47.20")!),
            projectedVariableUSD: Money(usd: 94)
        )
    }

    private func segments(_ count: Int) -> [CompositionSegment] {
        let ids: [ProviderID] = [.aws, .cloudflare, .openai, .github, .neon, .vercel, .fly]
        return (0..<count).map { index in
            CompositionSegment(
                accountID: AccountID.fixture(for: ids[index]),
                providerID: ids[index],
                displayName: ids[index].rawValue,
                colorKey: ids[index].rawValue,
                amount: Money(usd: Decimal(10 - index)),
                fraction: 1.0 / Double(count),
                percent: Int(100.0 / Double(count))
            )
        }
    }

    private func content(segmentCount: Int = 3) -> ShareCardContent {
        ShareCardBuilder.content(
            monthToDate: monthToDate(),
            composition: segments(segmentCount),
            now: now,
            calendar: calendar
        )
    }

    // MARK: - 内容

    @Test("卡上带金额：总数、预计月底、每家的钱都在")
    func cardCarriesAmounts() {
        let card = content()
        // 金额不挂精度记号，估算与否都写纯数字。
        #expect(card.totalText == "$47.20")
        #expect(card.projectionText?.contains("94") == true)
        #expect(card.segments.allSatisfy { !$0.amountText.isEmpty })
        #expect(card.subscriptionText == nil)
    }

    @Test("分享卡跟仪表走：算进订阅时主角是合计，日期上面写括号里的订阅")
    func subscriptionLineFollowsTheDashboard() {
        let month = MonthToDate(
            totalUSD: Money(roundedUSD: 67.20),
            projectedMonthEndUSD: Money(usd: 114),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [],
            variableUSD: Money(roundedUSD: 47.20),
            subscriptionUSD: Money(usd: 20),
            projectedVariableUSD: Money(usd: 94)
        )
        let card = ShareCardBuilder.content(
            monthToDate: month,
            composition: [],
            now: now,
            calendar: calendar
        )
        #expect(card.totalText.contains("67.20"))
        #expect(card.subscriptionText?.contains("20") == true)
        #expect(card.subscriptionText?.contains("已计入") != true)
        #expect(card.subscriptionText?.hasPrefix("（") == true)
        #expect(card.projectionText?.contains("114") == true)
    }

    @Test("涨跌幅太小或算不出来时整行不画，不写「+0%」")
    func negligibleComparisonIsOmitted() {
        for ratio in [nil, 0.0, 0.004, Double.nan, Double.infinity] {
            let card = ShareCardBuilder.content(
                monthToDate: monthToDate(changeRatio: ratio),
                composition: [],
                now: now,
                calendar: calendar
            )
            #expect(card.comparison == nil, "ratio \(String(describing: ratio)) 不该画这一行")
        }
    }

    @Test("最多列 5 家，第 6 名往后合并成其他，跟仪表构成环同一条线")
    func segmentsAreCapped() {
        let many = content(segmentCount: 7)
        #expect(many.segments.count == ShareCardBuilder.namedLimit + 1)
        #expect(many.segments.last?.isOther == true)
        #expect(content(segmentCount: 2).segments.count == 2)
        #expect(content(segmentCount: 5).segments.allSatisfy { !$0.isOther })
    }

    @Test("还没有账单时也能出卡，不是崩或者空白")
    func emptyStateStillRenders() {
        let card = ShareCardBuilder.content(
            monthToDate: nil,
            composition: [],
            now: now,
            calendar: calendar
        )
        #expect(!card.totalText.isEmpty)
        #expect(card.segments.isEmpty)
        #expect(card.qrPayload == ShareCardBuilder.shareURL)
    }

    @Test("二维码地址写死在代码里，不从目录或远程读")
    func qrPayloadIsCompiledIn() {
        #expect(ShareCardBuilder.shareURL == "https://tollcat.app")
        #expect(content().qrPayload == ShareCardBuilder.shareURL)
    }

    @Test("落款用品牌主句，不另写自我介绍；主机名跟二维码同一份")
    func footerUsesTheBrandSentence() {
        let card = content()
        #expect(card.qrCaption == "把各家云账单，装进口袋。")
        #expect(card.footnote == ShareCardBuilder.shareHost)
        #expect(card.qrPayload == "https://\(card.footnote)")
    }

    // MARK: - 二维码

    @Test("二维码扫得回来——生成完真的用探测器读一遍")
    func qrCodeRoundTrips() throws {
        let image = try #require(QRCode.image(for: ShareCardBuilder.shareURL, side: 512))
        let detector = try #require(
            CIDetector(
                ofType: CIDetectorTypeQRCode,
                context: nil,
                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            )
        )
        let features = detector.features(in: CIImage(cgImage: image))
        let payloads = features.compactMap { ($0 as? CIQRCodeFeature)?.messageString }
        #expect(payloads == [ShareCardBuilder.shareURL])
    }

    @Test("放大不靠插值，边缘还是硬的（糊掉的码扫不出来）")
    func qrCodeScalesWithoutBlurring() throws {
        let small = try #require(QRCode.image(for: "https://tollcat.app", side: 64))
        let large = try #require(QRCode.image(for: "https://tollcat.app", side: 512))
        #expect(large.width > small.width)
        // 两个尺寸都要能扫出来。
        for image in [small, large] {
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
            let found = detector?.features(in: CIImage(cgImage: image)).count ?? 0
            #expect(found == 1, "\(image.width)×\(image.height) 这一版扫不出来")
        }
    }

    // MARK: - 渲图

    @Test("渲出来就是 1080×1920：手机屏幕的比例，不是一张矮胖的方图")
    func rendersAtTheDeclaredSize() throws {
        let image = try #require(ShareCardView.rasterize(.preview))
        #expect(image.width == Int(ShareCardView.size.width))
        #expect(image.height == Int(ShareCardView.size.height))
        #expect(abs(Double(image.width) / Double(image.height) - 9.0 / 16.0) < 0.001)
        // 渲图倍率必须是整数倍，否则位图边缘会带半像素。
        #expect(ShareCardView.renderScale == ShareCardView.size.height / ShareCardView.layoutSize.height)
    }

    /// 卡的四条边都要留出页边距那一圈底色。
    ///
    /// 这一条守的是「二维码被切掉一半」：内容顶穿卡的下沿时不会报错，只会少半个码。
    /// 所以不看视图代码，看渲出来那张图的边缘像素。
    @Test("四边都不切内容——内容最满的那份也一样", arguments: [
        ShareCardContent.preview,
        ShareCardContent.previewCrowded,
    ])
    func cardNeverClipsItsContent(content: ShareCardContent) throws {
        let image = try #require(ShareCardView.rasterize(content))
        // 页边距 lg，量它的一半就够，四舍五入和抗锯齿都躲开了。
        let band = Int(MeterSpacing.lg / 2 * ShareCardView.renderScale)
        for edge in ShareCardEdgeScan.Edge.allCases {
            let offenders = try ShareCardEdgeScan.nonBackgroundPixels(
                in: image,
                edge: edge,
                thickness: band
            )
            #expect(offenders == 0, "\(edge) 这一边有 \(offenders) 个像素压到了页边距上")
        }
    }

    /// 月份跟仪表大标题同一档：主色、不是 caption 灰。
    ///
    /// 卡上看不到导航栏，「八月」必须自己把那一档撑起来。渲出来的位图里
    /// 月份那一块要有墨色像素——还是次要灰的话，就是又被收成脚注了。
    @Test("月份跟仪表大标题走：主色，不是 caption 灰")
    func periodTitleUsesPrimaryInk() throws {
        let image = try #require(ShareCardView.rasterize(.preview))
        let scale = ShareCardView.renderScale
        // 品牌行高 = 图标边长；下面隔 md 才是月份。
        let month = CGRect(
            x: MeterSpacing.lg * scale,
            y: (MeterSpacing.lg + MeterSpacing.brandMark + MeterSpacing.md) * scale,
            width: 160 * scale,
            height: 40 * scale
        )
        #expect(
            try ShareCardEdgeScan.contains(0x111318, in: image, rect: month),
            "月份不是主色——被收成 caption 灰了"
        )
    }

    /// 左上角那颗必须是 **App 图标本体**，不是手画的近似物，也不是一个空框。
    ///
    /// `Image(_:bundle:)` 找不到 SPM 散装 PNG 时不会报错，只会画一片空白——
    /// 所以这条闸去数像素：图标的靛蓝底和浅色猫脸必须都在那一小块里。
    @Test("左上角那颗是 App 图标本身")
    func brandMarkIsTheAppIcon() throws {
        let image = try #require(ShareCardView.rasterize(.preview))
        let scale = ShareCardView.renderScale
        let mark = CGRect(
            x: MeterSpacing.lg * scale,
            y: MeterSpacing.lg * scale,
            width: MeterSpacing.brandMark * scale,
            height: MeterSpacing.brandMark * scale
        )
        // 图标的两支颜色，和 scripts/render-app-icon.py 里的 INDIGO / PALE 同一对。
        #expect(try ShareCardEdgeScan.contains(0x5856D6, in: image, rect: mark), "没有图标的靛蓝底")
        #expect(try ShareCardEdgeScan.contains(0xF4F4FF, in: image, rect: mark), "没有图标上那只浅色猫")
    }

    @Test("卡片锁成浅色：分享者开深色模式也不该渲出一张黑卡")
    func cardIgnoresTheSharersColorScheme() throws {
        func render(_ scheme: ColorScheme) throws -> Data {
            let renderer = ImageRenderer(
                content: ShareCardView(content: .preview).environment(\.colorScheme, scheme)
            )
            renderer.scale = ShareCardView.renderScale
            renderer.isOpaque = true
            renderer.proposedSize = ProposedViewSize(ShareCardView.layoutSize)
            let image = try #require(renderer.cgImage)
            return try #require(RasterImage.pngData(from: image))
        }
        let light = try render(.light)
        let dark = try render(.dark)
        #expect(light == dark)
    }

    @Test("卡上带着构成和对比，不是一张只有数字的海报")
    func previewCardCarriesDashboardPieces() {
        let card = ShareCardContent.preview
        #expect(card.segments.count == 5)
        #expect(card.comparison != nil)
        #expect(card.trend != nil)
        #expect(card.comparison?.showsBars == true)
    }

    // MARK: - 模块区（卡 = 仪表盘）

    /// 卡不是固定那三四块：模块塞进去之后卡自己往下长，不裁内容。
    @Test("模块把卡撑长，宽度不变，也不从下沿切内容")
    func cardGrowsForModules() throws {
        let plain = try #require(ShareCardView.rasterize(.preview))
        let tall = try #require(
            ShareCardView.rasterize(.preview) {
                VStack(spacing: MeterSpacing.sm) {
                    ForEach(0..<6, id: \.self) { _ in
                        Color.white.frame(height: 120)
                    }
                }
            }
        )
        #expect(tall.width == plain.width)
        #expect(tall.height > plain.height)
        // 二维码在最下面：下沿那一圈还得是页边距底色，不然就是被切了。
        let band = Int(MeterSpacing.lg / 2 * ShareCardView.renderScale)
        for edge in ShareCardEdgeScan.Edge.allCases {
            let offenders = try ShareCardEdgeScan.nonBackgroundPixels(
                in: tall,
                edge: edge,
                thickness: band
            )
            #expect(offenders == 0, "\(edge) 这一边有 \(offenders) 个像素压到了页边距上")
        }
    }

    /// 卡上嵌的是仪表盘那批模块视图，它们走系统语义色（`Color(.label)` 那些）。
    /// 那些色解析的是**绘制时的 trait**，不是 SwiftUI 的 `colorScheme` 环境值——
    /// 所以分享者开着深色时，不压这一层就会渲出浅灰字压白卡。
    #if canImport(UIKit)
    @Test("模块也锁成浅色：分享者开深色模式，图上的字不跟着变浅")
    func moduleColorsAreLockedToLight() throws {
        @Sendable func render() -> CGImage? {
            ShareCardView.rasterize(.preview) {
                VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                    Text(verbatim: "Cloudflare")
                        .font(MeterFont.body)
                        .foregroundStyle(Color.meterLabel)
                    Text(verbatim: "$11.05")
                        .font(MeterFont.footnote)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MeterSpacing.sm)
                .background(Color.meterSecondaryGroupedBackground)
            }
        }
        var inDark: CGImage?
        UITraitCollection(userInterfaceStyle: .dark).performAsCurrent {
            inDark = render()
        }
        let darkImage = try #require(inDark)
        let lightImage = try #require(render())
        let dark = try #require(RasterImage.pngData(from: darkImage))
        let light = try #require(RasterImage.pngData(from: lightImage))
        #expect(dark == light)
    }
    #endif

    @Test("卡上的模块就是仪表盘上那些：合计和构成留给英雄区，其余按用户排的顺序")
    func moduleListFollowsTheDashboard() async throws {
        let model = try await seededDashboard()
        model.setModuleOrder([.subscriptions, .composition, .heatmap, .services])
        let ids = ShareCardModules.moduleIDs(for: model)
        #expect(!ids.contains(.monthToDate))
        #expect(!ids.contains(.composition))
        #expect(
            ids == model.visibleModuleIDs.filter { $0 != .monthToDate && $0 != .composition },
            "卡上的模块清单必须就是仪表盘那一份"
        )
    }

    /// Photos 在后台队列跑 change block。闭包若继承 `@MainActor`，Swift 6
    /// 运行时在入口核对 executor，对不上就 EXC_BREAKPOINT。
    @Test("存到相册的 change block 必须离开主 actor")
    func saveToPhotosChangeBlockLeavesMainActor() throws {
        let text = try GuardrailSourceScan.sourceText(named: "ShareCardModel.swift")
        #expect(
            text.contains("nonisolated private static func persistPNG"),
            "performChanges 必须从 nonisolated 上下文调用，不能写在 @MainActor 方法里"
        )
        #expect(
            text.contains("performChanges { @Sendable in"),
            "change block 必须标 @Sendable，否则会继承主 actor 隔离"
        )
    }

    @Test("构成关掉之后，卡上的环和近几个月也一起没了")
    func compositionOffTakesTheDonutWithIt() async throws {
        let model = try await seededDashboard()
        let on = ShareCardModel(dashboard: model).content
        #expect(!on.segments.isEmpty)
        model.setModule(.composition, enabled: false)
        let off = ShareCardModel(dashboard: model).content
        #expect(off.segments.isEmpty)
        #expect(off.trend == nil)
        // 大数字还在——合计是钉住的那一块。
        #expect(off.totalText == on.totalText)
    }

    private func seededDashboard() async throws -> DashboardModel {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let model = DashboardModel(
            providers: [:],
            container: container,
            credentials: InMemoryCredentialStore(),
            clock: .design,
            httpClient: StubHTTPClient()
        )
        try await model.seedDemoData()
        // 折叠在后台排（见 `DashboardModel.loadFromPersistence` 结尾那个 Task）。
        //
        // 一趟 `syncLedger()` 不够：它和那个后台 Task 是两路并发的折叠，
        // `LedgerSync.sync` 发现期间库又变过（`storeRevision` 动了）就回 nil，
        // 于是这一趟什么都不换，账本还是空的——构成没有段，卡上没有环。
        // 本机快，后台那趟一般先跑完；CI 的机器忙，就翻出来了。
        // 等到账本真有行为止，而不是赌一次调用的时序。
        for _ in 0..<100 where model.ledger.latest.isEmpty {
            try await Task.sleep(for: .milliseconds(20))
            await model.syncLedger()
        }
        #expect(!model.ledger.latest.isEmpty, "演示种子折完之前不要往下断言")
        return model
    }
}

/// 按点数在渲出来那张图上取一块像素，用来核对「画出来的到底是什么」。
///
/// 卡的底色写死成 `0xF2F2F7`（`ShareCardView` 不走系统语义色），所以边缘那一圈
/// 只要出现别的颜色，就说明有内容压到了页边距上——也就是被切了。
enum ShareCardEdgeScan {
    enum Edge: CaseIterable {
        case top, bottom, leading, trailing
    }

    private static let background: UInt32 = 0xF2F2F7
    /// 位图和 SwiftUI 的取色差一两级是正常的，别让抗锯齿把这条闸变成噪声。
    private static let tolerance = 4

    /// 某一条边上「不是底色」的像素个数。`thickness` 是像素。
    static func nonBackgroundPixels(in image: CGImage, edge: Edge, thickness: Int) throws -> Int {
        let rect: CGRect = switch edge {
        case .top: CGRect(x: 0, y: 0, width: image.width, height: thickness)
        case .bottom: CGRect(x: 0, y: image.height - thickness, width: image.width, height: thickness)
        case .leading: CGRect(x: 0, y: 0, width: thickness, height: image.height)
        case .trailing: CGRect(x: image.width - thickness, y: 0, width: thickness, height: image.height)
        }
        return try pixels(in: image, rect: rect)
            .filter { !matches($0, background) }
            .count
    }

    /// 这一块里有没有出现某个颜色。用来确认某样东西**真的画出来了**。
    static func contains(_ color: UInt32, in image: CGImage, rect: CGRect) throws -> Bool {
        try pixels(in: image, rect: rect).contains { matches($0, color) }
    }

    /// `rect` 用图片自己的像素坐标，原点在左上。
    private static func pixels(in image: CGImage, rect: CGRect) throws -> [UInt32] {
        let width = Int(rect.width)
        let height = Int(rect.height)
        var raw = [UInt8](repeating: 0, count: width * height * 4)
        try raw.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw ShareCardEdgeScanError.contextUnavailable
            }
            // CGContext 原点在左下，整幅图挪到只剩要看的那一块落在画布里。
            context.draw(
                image,
                in: CGRect(
                    x: -rect.minX,
                    y: rect.maxY - CGFloat(image.height),
                    width: CGFloat(image.width),
                    height: CGFloat(image.height)
                )
            )
        }
        return stride(from: 0, to: raw.count, by: 4).map { index in
            UInt32(raw[index]) << 16 | UInt32(raw[index + 1]) << 8 | UInt32(raw[index + 2])
        }
    }

    private static func matches(_ pixel: UInt32, _ color: UInt32) -> Bool {
        for shift in [16, 8, 0] {
            let lhs = Int((pixel >> UInt32(shift)) & 0xFF)
            let rhs = Int((color >> UInt32(shift)) & 0xFF)
            if abs(lhs - rhs) > tolerance { return false }
        }
        return true
    }
}

enum ShareCardEdgeScanError: Error {
    case contextUnavailable
}

