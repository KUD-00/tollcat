import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// `CGImage` → PNG。走 ImageIO，不经过 `UIImage`。
public enum RasterImage: Sendable {
    public static func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
