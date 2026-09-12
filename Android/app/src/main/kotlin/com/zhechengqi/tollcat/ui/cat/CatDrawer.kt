package com.zhechengqi.tollcat.ui.cat

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate

/**
 * 把一只猫画进任意 [DrawScope]。界面 [CatView] 和桌面小部件静帧共用，
 * 避免小组件再抄一套 path。
 */
internal object CatDrawer {
    /** 定稿冷灰，不跟语义色 / 动态色走：坐在任何卡面上都认得出剪影。 */
    val bodyLight = Color(0xFF6E747B)
    val bodyDark = Color(0xFF858C93)
    val ink = Color.White

    fun bodyColor(dark: Boolean): Color = if (dark) bodyDark else bodyLight

    fun DrawScope.draw(parts: CatParts, frame: CatMotionFrame, dark: Boolean) {
        draw(parts, frame, bodyColor(dark), ink)
    }

    fun DrawScope.draw(parts: CatParts, frame: CatMotionFrame, body: Color, ink: Color) {
        val scaleX: Float
        val scaleY: Float
        if (frame.stretch > 0f) {
            scaleX = 1f - (1f - CatMotion.SHOCKED_STRETCH_X) * frame.stretch
            scaleY = 1f + (CatMotion.SHOCKED_STRETCH_Y - 1f) * frame.stretch
        } else {
            scaleX = 1f + CatMotion.FLATTEN * frame.squash
            scaleY = 1f - CatMotion.FLATTEN * frame.squash
        }
        // 压扁 / 拉长以底边中点为锚：变扁向两侧胀，回弹沿原路收回，脚不离地。
        translate(left = frame.shake * size.width * CatMotion.SHAKE_AMPLITUDE) {
            scale(scaleX, scaleY, pivot = Offset(size.width / 2f, size.height)) {
                val unit = size.width / CatArtwork.VIEW_BOX
                scale(unit, unit, pivot = Offset.Zero) {
                    drawBodyGroup(parts, frame, body, ink)
                    drawAccessories(parts, frame, body, ink)
                }
            }
        }
    }

    private fun DrawScope.drawBodyGroup(
        parts: CatParts,
        frame: CatMotionFrame,
        body: Color,
        ink: Color,
    ) {
        val group: DrawScope.() -> Unit = {
            rotate(frame.tailDegrees, pivot = CatArtwork.tailPivot) {
                drawPath(CatArtwork.tailPath, body)
            }
            drawPath(
                CatArtwork.silhouettePath(frame.leftEarDegrees, frame.rightEarDegrees),
                body,
            )
            drawEyes(parts, frame, ink)
            drawMouth(parts, frame, ink)
            if (parts.wearsGlasses) {
                for (lens in CatArtwork.glassesLensPaths) {
                    drawPath(lens, ink)
                }
                for (piece in CatArtwork.glassesFramePaths) {
                    drawPath(piece, ink)
                }
            }
        }
        // 翻肚皮只翻身体和脸。挂件留在正面朝上——跟着转 180° 的骷髅气泡
        // 在小尺寸上只剩一团灰，读不出是什么。
        if (parts.isUpsideDown) {
            rotate(180f, pivot = CatArtwork.bodyCenter) { group() }
        } else {
            group()
        }
    }

    /** 眼珠跟视线走，眨眼是竖直压扁，不是换一张闭眼图。眼镜不动：从镜片后面看过去，才像在看。 */
    private fun DrawScope.drawEyes(parts: CatParts, frame: CatMotionFrame, ink: Color) {
        val blink = frame.blink.coerceIn(0f, 1f)
        val lid = if (parts.eyes.canBlink) {
            1f - (1f - CatMotion.CLOSED_LID_SCALE) * blink
        } else {
            1f
        }
        for (eye in CatArtwork.eyeballShapes(parts.eyes)) {
            val center = eye.getBounds().center
            translate(center.x + frame.gazeX, center.y + frame.gazeY) {
                scale(1f, lid, pivot = Offset.Zero) {
                    translate(-center.x, -center.y) {
                        drawPath(eye, ink)
                    }
                }
            }
        }
        for (mark in CatArtwork.eyeMarkShapes(parts.eyes)) {
            translate(frame.gazeX, frame.gazeY) {
                drawPath(mark, ink)
            }
        }
    }

    /** 嘴跟着看，但走得少、到得晚。锁死成眼睛的缩放拷贝会呆。 */
    private fun DrawScope.drawMouth(parts: CatParts, frame: CatMotionFrame, ink: Color) {
        val mouth = CatArtwork.mouthShape(parts.mouth) ?: return
        translate(frame.mouthX, frame.mouthY) {
            drawPath(mouth, ink)
        }
    }

    private fun DrawScope.drawAccessories(
        parts: CatParts,
        frame: CatMotionFrame,
        body: Color,
        ink: Color,
    ) {
        when (parts.accessory) {
            CatAccessory.None -> Unit
            CatAccessory.Zzz -> drawZzz(frame, body)
            CatAccessory.Bang -> {
                for (mark in CatArtwork.bangPaths) {
                    drawPath(mark, body)
                }
            }
            CatAccessory.Skull -> {
                drawPath(CatArtwork.skullHeadPath, body)
                for (socket in CatArtwork.skullEyePaths) {
                    drawPath(socket, ink)
                }
                for (dot in CatArtwork.bubbleDotPaths) {
                    drawPath(dot, body)
                }
            }
        }
    }

    /** 三个 Z 贴着头顶右上斜排，越飘越大，相位错开，看起来是一串接着往上飘。 */
    private fun DrawScope.drawZzz(frame: CatMotionFrame, body: Color) {
        for ((index, mark) in CatArtwork.zzzMarks.withIndex()) {
            val phase = CatMotion.zzzPhase(frame.zzzLift, index)
            val markScale = mark.size / CatArtwork.ZZZ_WIDTH
            val height = CatArtwork.ZZZ_HEIGHT * markScale
            translate(
                left = mark.center.x - mark.size / 2f,
                top = mark.center.y - height / 2f - phase * 26f,
            ) {
                scale(markScale, markScale, pivot = Offset.Zero) {
                    drawPath(CatArtwork.zzzPath, body, alpha = 0.5f + 0.5f * phase)
                }
            }
        }
    }
}
