import Testing
import SwiftUI
import CoreGraphics
import UIKit
@testable import MeterDesign

/// 猫改成 `Canvas` 画之后，必须证明它在**离屏**也画得出来。
///
/// Widget 不是实时渲染的：WidgetKit 把视图归档，在另一个进程里栅格化成快照。
/// `ImageRenderer` 走的是同一类离屏路径，所以这组测试能挡住「Canvas 在
/// 非实时环境里画出一张空图」这种事故 —— 那种事故在模拟器里跑 App 是看不见的。
@Suite("猫的离屏栅格化")
@MainActor
struct CatRasterTests {

    @Test("七种表情的静态帧都画得出东西", arguments: CatMood.allCases)
    func staticFrameRasterises(mood: CatMood) throws {
        let coverage = try coverage(of: CatView(mood: mood, size: 64, isAnimated: false))
        // 猫的剪影占画面一半以上，压到 8% 以下只可能是画糊了或者没画。
        #expect(coverage > 0.08, "\(mood.rawValue) 栅格化后几乎是空的：\(coverage)")
    }

    @Test("Widget 尺寸下也不是空的")
    func widgetSizeRasterises() throws {
        let coverage = try coverage(of: CatView(mood: .normal, size: MeterSpacing.catWidget, isAnimated: false))
        #expect(coverage > 0.08)
    }

    @Test("睡觉的 ZZZ 在离屏也画得出来")
    func sleepingDrawsMoreThanTheBody() throws {
        let sleeping = try coverage(of: CatView(mood: .sleeping, size: 180, isAnimated: false))
        let normal = try coverage(of: CatView(mood: .normal, size: 180, isAnimated: false))
        // ZZZ 是额外的墨，睡觉那张必须比平常那张多。
        #expect(sleeping > normal)
    }

    @Test("省到了是星眼加小O嘴")
    func savedUsesSparkleAndSmallO() {
        let parts = CatParts(.saved)
        #expect(parts.eyes == .sparkle)
        #expect(parts.mouth == .smallO)
        #expect(parts.accessory == .none)
        #expect(!parts.isUpsideDown)
    }

    @Test("小O嘴比吓到的大O小")
    func smallOIsSmallerThanShockedO() throws {
        let small = try #require(CatArtwork.mouthShape(for: .smallO)).boundingRect
        let big = try #require(CatArtwork.mouthShape(for: .o)).boundingRect
        #expect(small.width * small.height < big.width * big.height * 0.5)
    }

    @Test("眼皮压到最扁也不是空图")
    func fullBlinkStillRasterises() throws {
        let coverage = try coverage(
            of: CatView(
                parts: CatParts(.normal),
                size: 180,
                accessibilityLabel: CatMood.normal.accessibilityLabel,
                isAnimated: false,
                pose: CatMotionFrame(blink: 1)
            )
        )
        #expect(coverage > 0.08)
    }

    @Test("拧过的耳朵离屏也画得出东西")
    func rotatedEarsRasterise() throws {
        let coverage = try coverage(
            of: CatView(
                parts: CatParts(.normal),
                size: 180,
                accessibilityLabel: CatMood.normal.accessibilityLabel,
                isAnimated: false,
                pose: CatMotionFrame(leftEarDegrees: 12, rightEarDegrees: -8)
            )
        )
        #expect(coverage > 0.08)
    }

    @Test("0 度剪影就是原稿，耳尖还在")
    func restPoseKeepsIntegratedEars() {
        let rest = CatArtwork.silhouettePath.boundingRect
        let posed = CatArtwork.silhouettePath(leftEarDegrees: 0, rightEarDegrees: 0).boundingRect
        #expect(rest.minY < 250)
        #expect(posed == rest)
    }

    @Test("拧耳朵仍是同一条闭合剪影")
    func bendingEarsStaysOneSilhouette() {
        let rest = CatArtwork.silhouettePath.boundingRect
        let bent = CatArtwork.silhouettePath(leftEarDegrees: 12, rightEarDegrees: -8).boundingRect
        #expect(bent != rest)
        #expect(bent.minY < 280)
    }

    @Test("深色栅格的身体比浅色亮")
    func darkRasterBodyIsLighter() throws {
        let light = try medianBodyLuminance(scheme: .light)
        let dark = try medianBodyLuminance(scheme: .dark)
        #expect(dark > light + 0.02, "light=\(light) dark=\(dark)")
    }

    @Test("眼镜图层在离屏也画得出东西")
    func glassesRasterise() throws {
        var parts = CatParts(.normal)
        parts.wearsGlasses = true
        let coverage = try coverage(
            of: CatView(
                parts: parts,
                size: 180,
                accessibilityLabel: CatMood.normal.accessibilityLabel,
                isAnimated: false
            )
        )
        #expect(coverage > 0.08)
    }

    /// 身体像素的中位相对亮度。白眼不进样本。
    private func medianBodyLuminance(scheme: ColorScheme) throws -> Double {
        let view = CatView(mood: .normal, size: 180, isAnimated: false)
            .environment(\.colorScheme, scheme)
            .preferredColorScheme(scheme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try #require(renderer.cgImage, "\(scheme) 栅格化失败")
        let samples = bodyLuminances(in: image)
        try #require(!samples.isEmpty, "\(scheme) 没有采到身体像素")
        let sorted = samples.sorted()
        return sorted[sorted.count / 2]
    }

    private func bodyLuminances(in image: CGImage) -> [Double] {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var samples: [Double] = []
        samples.reserveCapacity(width * height / 2)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = pixels[index + 3]
            guard alpha > 40 else { continue }
            let red = CGFloat(pixels[index]) / 255
            let green = CGFloat(pixels[index + 1]) / 255
            let blue = CGFloat(pixels[index + 2]) / 255
            if red > 0.85 && green > 0.85 && blue > 0.85 { continue }
            samples.append(
                Double(
                    WCAGContrast.relativeLuminance(
                        GlyphRGBA(r: red, g: green, b: blue, a: CGFloat(alpha) / 255)
                    )
                )
            )
        }
        return samples
    }

    /// 栅格化后不透明像素占比。
    private func coverage(of view: some View) throws -> Double {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try #require(renderer.cgImage, "ImageRenderer 什么都没给出来")
        let width = image.width
        let height = image.height
        #expect(width > 0 && height > 0)

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var opaque = 0
        for index in stride(from: 3, to: pixels.count, by: 4) where pixels[index] > 40 {
            opaque += 1
        }
        return Double(opaque) / Double(width * height)
    }
}

@Suite("猫的色板对比度")
struct CatColorTests {
    @Test("浅色身体仍是定稿灰")
    func lightBodyIsCanonicalGray() {
        #expect(matches(GlyphRGBA.resolve(MeterColor.catBody, style: .light), hex: 0x6E747B))
        #expect(
            matches(
                GlyphRGBA.resolve(MeterColor.catBody(for: .light), style: .light),
                hex: 0x6E747B
            )
        )
    }

    @Test("深色身体是抬亮的同一只冷灰")
    func darkBodyIsLiftedCoolGray() {
        #expect(matches(GlyphRGBA.resolve(MeterColor.catBody, style: .dark), hex: 0x858C93))
        #expect(
            matches(
                GlyphRGBA.resolve(MeterColor.catBody(for: .dark), style: .dark),
                hex: 0x858C93
            )
        )
    }

    @Test("深色身体比浅色亮")
    func darkBodyIsLighterThanLight() {
        let light = WCAGContrast.relativeLuminance(
            GlyphRGBA.resolve(MeterColor.catBody, style: .light)
        )
        let dark = WCAGContrast.relativeLuminance(
            GlyphRGBA.resolve(MeterColor.catBody, style: .dark)
        )
        #expect(dark > light)
    }

    @Test("白眼压在身体上至少 3:1", arguments: [ColorScheme.light, .dark])
    func inkOnBodyAtLeastThree(scheme: ColorScheme) {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        let body = GlyphRGBA.resolve(MeterColor.catBody, style: style)
        let ink = GlyphRGBA.resolve(MeterColor.catInk, style: style)
        let ratio = WCAGContrast.ratio(ink, body)
        #expect(ratio + 0.001 >= 3, "\(scheme) ink/body contrast \(ratio)")
    }

    @Test("身体压在 grouped 卡面上至少 3:1", arguments: [ColorScheme.light, .dark])
    func bodyOnGroupedCardAtLeastThree(scheme: ColorScheme) {
        let style: UIUserInterfaceStyle = scheme == .dark ? .dark : .light
        let body = GlyphRGBA.resolve(MeterColor.catBody, style: style)
        let card = GlyphRGBA.from(
            UIColor.secondarySystemGroupedBackground.resolvedColor(
                with: UITraitCollection(userInterfaceStyle: style)
            )
        )
        let ratio = WCAGContrast.ratio(body, card)
        #expect(ratio + 0.001 >= 3, "\(scheme) body/card contrast \(ratio)")
    }

    private func matches(_ color: GlyphRGBA, hex: UInt32, tolerance: CGFloat = 0.01) -> Bool {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        return abs(color.r - red) < tolerance
            && abs(color.g - green) < tolerance
            && abs(color.b - blue) < tolerance
            && color.a > 0.99
    }
}

