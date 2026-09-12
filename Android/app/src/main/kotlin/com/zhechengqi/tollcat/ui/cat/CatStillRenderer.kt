package com.zhechengqi.tollcat.ui.cat

import android.graphics.Bitmap
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection

/** Glance 没有 Canvas。静帧渲成位图，小组件当角标贴。 */
object CatStillRenderer {
    fun bitmap(mood: CatMood, sizePx: Int, dark: Boolean): Bitmap {
        val side = sizePx.coerceAtLeast(1)
        val image = ImageBitmap(side, side)
        CanvasDrawScope().draw(
            density = Density(1f),
            layoutDirection = LayoutDirection.Ltr,
            canvas = Canvas(image),
            size = Size(side.toFloat(), side.toFloat()),
        ) {
            with(CatDrawer) {
                draw(mood.parts, CatMotionFrame.still(mood), dark)
            }
        }
        return image.asAndroidBitmap()
    }
}
