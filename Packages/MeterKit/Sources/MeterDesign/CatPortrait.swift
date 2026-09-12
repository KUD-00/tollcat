import SwiftUI

/// 整只猫画在一个 `Canvas` 里。动效参数由外层的 `CatMotionFrame` 喂进来。
///
/// 为什么不是一叠 `Shape`：原来每个图层是一个独立的 View，一秒几十帧地重建，
/// 实测有 17% 的帧整只猫画不出来（同一帧里页面其它像素完全没变，只有猫没了）。
/// 一个 `Canvas` 是一次绘制，要么整只在要么整只不在，不可能出现「只剩尾巴」，
/// 而且十几个图层塌成一个 View，重建成本掉一个数量级。
struct CatPortrait: View {
    var parts: CatParts
    var frame: CatMotionFrame
    var size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let bodyPaint = MeterColor.catBody(for: colorScheme)
        Canvas(opaque: false, rendersAsynchronously: false) { context, canvas in
            draw(in: &context, canvas: canvas, bodyPaint: bodyPaint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, canvas: CGSize, bodyPaint: Color) {
        CatSquashAnchor.apply(
            to: &context,
            canvas: canvas,
            scaleX: scaleX,
            scaleY: scaleY,
            shake: frame.shake
        )
        // 之后一律用 viewBox 坐标画。
        let unit = canvas.width / CatArtwork.viewBox
        context.scaleBy(x: unit, y: unit)

        context.drawLayer { body in
            // 翻肚皮只翻身体和脸。挂件留在正面朝上 —— 跟着转 180° 的骷髅气泡
            // 在小尺寸上只剩一团灰，读不出是什么。
            if parts.isUpsideDown {
                body.translateBy(x: CatArtwork.bodyCenter.x, y: CatArtwork.bodyCenter.y)
                body.rotate(by: .degrees(180))
                body.translateBy(x: -CatArtwork.bodyCenter.x, y: -CatArtwork.bodyCenter.y)
            }
            body.drawLayer { tail in
                tail.translateBy(x: CatArtwork.tailPivot.x, y: CatArtwork.tailPivot.y)
                tail.rotate(by: .degrees(frame.tailDegrees))
                tail.translateBy(x: -CatArtwork.tailPivot.x, y: -CatArtwork.tailPivot.y)
                tail.fill(CatArtwork.tailPath, with: .color(bodyPaint))
            }
            body.fill(
                CatArtwork.silhouettePath(
                    leftEarDegrees: frame.leftEarDegrees,
                    rightEarDegrees: frame.rightEarDegrees
                ),
                with: .color(bodyPaint)
            )
            drawEyes(in: &body)
            drawMouth(in: &body)
            if parts.wearsGlasses {
                for lens in CatArtwork.glassesLensPaths {
                    body.fill(lens, with: .color(MeterColor.catInk), style: FillStyle(eoFill: true))
                }
                for piece in CatArtwork.glassesFramePaths {
                    body.fill(piece, with: .color(MeterColor.catInk))
                }
            }
        }

        drawAccessories(in: &context, bodyPaint: bodyPaint)
    }

    /// 眼珠跟视线走，眨眼是竖直压扁，不是换一张闭眼图。
    /// 眼镜不动：从镜片后面看过去，才像在看。
    private func drawEyes(in context: inout GraphicsContext) {
        let blink = min(max(frame.blink, 0), 1)
        let lid = parts.eyes.canBlink
            ? 1 - (1 - CatMotion.closedLidScale) * blink
            : 1
        for eye in CatArtwork.eyeballShapes(for: parts.eyes) {
            let box = eye.boundingRect
            let center = CGPoint(x: box.midX, y: box.midY)
            context.drawLayer { layer in
                layer.translateBy(x: center.x + frame.gazeX, y: center.y + frame.gazeY)
                layer.scaleBy(x: 1, y: lid)
                layer.translateBy(x: -center.x, y: -center.y)
                layer.fill(eye, with: .color(MeterColor.catInk))
            }
        }
        for mark in CatArtwork.eyeMarkShapes(for: parts.eyes) {
            context.drawLayer { layer in
                layer.translateBy(x: frame.gazeX, y: frame.gazeY)
                layer.fill(mark, with: .color(MeterColor.catInk))
            }
        }
    }

    /// 嘴跟着看，但走得少、到得晚。锁死成眼睛的缩放拷贝会呆。
    private func drawMouth(in context: inout GraphicsContext) {
        guard let mouth = CatArtwork.mouthShape(for: parts.mouth) else { return }
        let box = mouth.boundingRect
        let center = CGPoint(x: box.midX, y: box.midY)
        context.drawLayer { layer in
            layer.translateBy(x: center.x + frame.mouthX, y: center.y + frame.mouthY)
            layer.translateBy(x: -center.x, y: -center.y)
            layer.fill(mouth, with: .color(MeterColor.catInk))
        }
    }

    private func drawAccessories(in context: inout GraphicsContext, bodyPaint: Color) {
        switch parts.accessory {
        case .none:
            break
        case .zzz:
            drawZZZ(in: &context, bodyPaint: bodyPaint)
        case .bang:
            for mark in CatArtwork.bangPaths {
                context.fill(mark, with: .color(bodyPaint))
            }
        case .skull:
            context.fill(CatArtwork.skullHeadPath, with: .color(bodyPaint))
            for socket in CatArtwork.skullEyePaths {
                context.fill(socket, with: .color(MeterColor.catInk))
            }
            for dot in CatArtwork.bubbleDotPaths {
                context.fill(dot, with: .color(bodyPaint))
            }
        }
    }

    /// 三个 Z 贴着头顶右上斜排，越飘越大，相位错开，看起来是一串接着往上飘。
    private func drawZZZ(in context: inout GraphicsContext, bodyPaint: Color) {
        for (index, mark) in CatArtwork.zzzMarks.enumerated() {
            let phase = CatMotion.zzzPhase(lift: frame.zzzLift, index: index)
            let scale = mark.size / CatArtwork.zzzWidth
            let height = CatArtwork.zzzHeight * scale
            context.drawLayer { layer in
                layer.opacity = 0.5 + 0.5 * phase
                layer.translateBy(
                    x: mark.center.x - mark.size / 2,
                    y: mark.center.y - height / 2 - phase * 26
                )
                layer.scaleBy(x: scale, y: scale)
                layer.fill(CatArtwork.zzzPath, with: .color(bodyPaint))
            }
        }
    }

    private var scaleX: CGFloat {
        if frame.stretch > 0 {
            return 1 - (1 - CatMotion.shockedStretchX) * frame.stretch
        }
        return 1 + CatMotion.flatten * frame.squash
    }

    private var scaleY: CGFloat {
        if frame.stretch > 0 {
            return 1 + (CatMotion.shockedStretchY - 1) * frame.stretch
        }
        return 1 - CatMotion.flatten * frame.squash
    }
}
