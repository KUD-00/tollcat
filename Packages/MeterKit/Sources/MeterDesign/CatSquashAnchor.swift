import SwiftUI

/// 压扁 / 拉长的锚点。
///
/// 旧实现把原点放在画布左下角：`scaleX > 1` 时整只猫只往右长，看起来像在平移。
/// 正确的呼吸是底边中点为锚——变扁向两侧胀，回弹沿原路收回，脚不离开地面。
enum CatSquashAnchor {
    static func apply(
        to context: inout GraphicsContext,
        canvas: CGSize,
        scaleX: CGFloat,
        scaleY: CGFloat,
        shake: CGFloat
    ) {
        let originX = canvas.width / 2 + shake * canvas.width * CatMotion.shakeAmplitude
        context.translateBy(x: originX, y: canvas.height)
        context.scaleBy(x: scaleX, y: scaleY)
        context.translateBy(x: -canvas.width / 2, y: -canvas.height)
    }

    /// 画布坐标里的一点经过压扁之后落在哪。给测试用，和 `apply` 同一套矩阵。
    static func map(
        _ point: CGPoint,
        canvas: CGSize,
        scaleX: CGFloat,
        scaleY: CGFloat,
        shake: CGFloat = 0
    ) -> CGPoint {
        let originX = canvas.width / 2 + shake * canvas.width * CatMotion.shakeAmplitude
        return CGPoint(
            x: (point.x - canvas.width / 2) * scaleX + originX,
            y: (point.y - canvas.height) * scaleY + canvas.height
        )
    }
}
