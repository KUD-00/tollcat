import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// 二维码。CoreImage 自带，不引第三方（ARCHITECTURE.md：一个都不要）。
public enum QRCode: Sendable {
    /// 纠错级别取 H（约 30% 冗余）：分享卡会被转发、压缩、截图再截图，
    /// 低纠错的码在这条链路上很容易扫不出来。
    private static let correctionLevel = "H"

    /// 生成一张不透明的位图。
    ///
    /// CoreImage 出来的原图只有几十像素，直接放大会被插值糊掉，所以用
    /// `CGAffineTransform` 整数倍放大——最近邻式的硬边才扫得动。
    public static func image(for payload: String, side: CGFloat) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = correctionLevel
        guard let output = filter.outputImage else { return nil }

        let scale = max(1, side / output.extent.width)
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        return context.createCGImage(scaled, from: scaled.extent)
    }
}

/// 卡片里那一小块二维码。扫不出来时留白，不画一个假的方块骗人。
public struct QRCodeView: View {
    private let payload: String
    private let side: CGFloat

    public init(payload: String, side: CGFloat) {
        self.payload = payload
        self.side = side
    }

    public var body: some View {
        Group {
            if let image = QRCode.image(for: payload, side: side * 3) {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: MeterRadius.glyph, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            }
        }
        .frame(width: side, height: side)
        // 二维码必须是黑码白底。跟着深色模式反过来的话相机识别率会掉。
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: MeterRadius.glyph, style: .continuous))
    }
}

#Preview("Light") {
    QRCodeView(payload: "https://tollcat.app", side: 88)
        .padding()
}

#Preview("Dark") {
    QRCodeView(payload: "https://tollcat.app", side: 88)
        .padding()
        .preferredColorScheme(.dark)
}
