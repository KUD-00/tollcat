import SwiftUI

/// Simple Icons 的 viewBox 固定 24×24，按传入 rect 等比铺满。
struct SVGPathShape: Shape {
    var d: String

    func path(in rect: CGRect) -> Path {
        let parsed = SVGPathParser.path(from: d)
        let transform = CGAffineTransform(
            a: rect.width / Self.viewBox,
            b: 0,
            c: 0,
            d: rect.height / Self.viewBox,
            tx: rect.minX,
            ty: rect.minY
        )
        return parsed.applying(transform)
    }

    private static let viewBox: CGFloat = 24
}
