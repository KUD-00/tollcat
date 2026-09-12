import CoreGraphics
import ImageIO
import SwiftUI

/// App 图标本身。位图由 `scripts/render-app-icon.py` 和 `AppIcon.appiconset`
/// 同一次渲染装进来——**不要在这里另画一只猫**：手画那版和真图标的构图
/// （脸部 crop、天上的 $）对不上，换了图标也不会跟着变。
///
/// 圆角在这里切：位图是方的，脚本里蒙 PIL 的普通圆角会和系统 squircle 差一圈。
public struct BrandMark: View {
    /// iOS 图标网格的圆角比：1024 的图标圆角是 229。
    private static let cornerRatio: CGFloat = 0.2237

    /// `Image("BrandIcon", bundle: .module)` 找不到它——那条路只查 asset catalog，
    /// 而这是 SPM `.process` 原样拷进 bundle 的散装 PNG。所以自己按 URL 读。
    /// 走 ImageIO，不经过 `UIImage`（和 `RasterImage` 同一条线）。
    private static let bitmap: CGImage? = {
        guard let url = Bundle.module.url(forResource: "BrandIcon", withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }()

    private let side: CGFloat

    public init(side: CGFloat = MeterSpacing.brandMark) {
        self.side = side
    }

    public var body: some View {
        Group {
            if let bitmap = Self.bitmap {
                Image(decorative: bitmap, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                // 位图丢了也不要开个洞：底色和图标同一支靛蓝。
                Color(hex: 0x5856D6)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * Self.cornerRatio, style: .continuous))
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: MeterSpacing.md) {
        BrandMark(side: 28)
        BrandMark()
        BrandMark(side: 88)
    }
    .padding()
}
