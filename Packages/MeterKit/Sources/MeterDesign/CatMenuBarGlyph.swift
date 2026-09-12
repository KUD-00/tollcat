#if os(macOS)
import AppKit
import SwiftUI

/// 菜单栏里那只猫。
///
/// 出的是模板图：只有 alpha，颜色由菜单栏按深浅和高亮自己填，
/// 所以眼睛和嘴是从剪影上抠出来的洞，不是仪表盘那样压上去的白。
/// 表情跟仪表盘走，挂件（ZZZ / 惊叹号 / 骷髅）在 18pt 里只剩一团灰，不画；
/// 翻肚皮也不翻，翻了就认不出是猫。
public enum CatMenuBarGlyph {
    /// 菜单栏常驻图标的惯用高度。
    public static let pointSize: CGFloat = 18

    @MainActor private static var cache: [CatMood: NSImage] = [:]

    @MainActor
    public static func image(for mood: CatMood) -> NSImage {
        if let cached = cache[mood] {
            return cached
        }
        let image = render(parts: mood.parts, pointSize: pointSize)
        cache[mood] = image
        return image
    }

    /// 1x 和 2x 各画一份位图。不走 `drawingHandler`：抠洞靠 `destinationOut`，
    /// 那种合成只能在自己的透明位图里做，直接画到菜单栏上会把底擦掉。
    static func render(parts: CatParts, pointSize: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        for scale in [CGFloat(1), 2] {
            if let bitmap = renderBitmap(parts: parts, pointSize: pointSize, scale: scale) {
                let rep = NSBitmapImageRep(cgImage: bitmap)
                rep.size = NSSize(width: pointSize, height: pointSize)
                image.addRepresentation(rep)
            }
        }
        image.isTemplate = true
        return image
    }

    private static func renderBitmap(parts: CatParts, pointSize: CGFloat, scale: CGFloat) -> CGImage? {
        let pixels = Int((pointSize * scale).rounded(.up))
        guard let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let body = CatArtwork.silhouettePath(leftEarDegrees: 0, rightEarDegrees: 0)
        let tail = CatArtwork.tailPath
        let bounds = body.boundingRect.union(tail.boundingRect)
        let unit = CGFloat(pixels) / max(bounds.width, bounds.height)

        // 位图原点在左下，路径坐标是 SVG 的 y 朝下：先翻过来，再把猫居中。
        context.translateBy(x: 0, y: CGFloat(pixels))
        context.scaleBy(x: 1, y: -1)
        context.translateBy(
            x: (CGFloat(pixels) - bounds.width * unit) / 2 - bounds.minX * unit,
            y: (CGFloat(pixels) - bounds.height * unit) / 2 - bounds.minY * unit
        )
        context.scaleBy(x: unit, y: unit)

        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.addPath(tail.cgPath)
        context.fillPath()
        context.addPath(body.cgPath)
        context.fillPath()

        context.setBlendMode(.destinationOut)
        for eye in CatArtwork.eyeballShapes(for: parts.eyes) {
            context.addPath(eye.cgPath)
            context.fillPath()
        }
        for mark in CatArtwork.eyeMarkShapes(for: parts.eyes) {
            context.addPath(mark.cgPath)
            context.fillPath()
        }
        if let mouth = CatArtwork.mouthShape(for: parts.mouth) {
            context.addPath(mouth.cgPath)
            context.fillPath()
        }
        return context.makeImage()
    }
}
#endif
