package com.zhechengqi.tollcat.ui.cat

import android.content.res.Configuration
import androidx.compose.animation.core.withInfiniteAnimationFrameNanos
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import kotlin.math.max

/**
 * TollCat。路径与动效逐一移植自 iOS `MeterDesign.CatView`。
 *
 * 整只猫画在一个 `Canvas` 里：十几个图层塌成一次绘制，时间值只在
 * draw 阶段读取，每帧只重画不重组。换表情时叠一次眨眼，在眼缝最窄处切脸。
 */
@Composable
fun CatView(
    mood: CatMood,
    size: Dp,
    modifier: Modifier = Modifier,
    isAnimated: Boolean = true,
) {
    CatView(
        parts = mood.parts,
        motion = mood.motion,
        size = size,
        modifier = modifier,
        isAnimated = isAnimated,
    )
}

/** 按图层和姿势拼一只猫。生产界面走命名表情。 */
@Composable
fun CatView(
    parts: CatParts,
    motion: CatMotionKind,
    size: Dp,
    modifier: Modifier = Modifier,
    isAnimated: Boolean = true,
) {
    // 系统关掉动画（含无障碍「移除动画」）时给静帧；LocalReduceMotion 会跟随设置实时变。
    val animate = isAnimated && !LocalReduceMotion.current && motion != CatMotionKind.Still
    val dark = MaterialTheme.colorScheme.surface.luminance() < 0.5f

    val time = remember { mutableDoubleStateOf(0.0) }
    if (animate) {
        LaunchedEffect(Unit) {
            while (true) {
                withInfiniteAnimationFrameNanos { nanos ->
                    time.doubleValue = nanos / 1_000_000_000.0
                }
            }
        }
    }

    var cover by remember { mutableStateOf<CatCover?>(null) }
    var shown by remember { mutableStateOf(parts) }
    if (shown != parts) {
        cover = if (animate) {
            val now = time.doubleValue
            CatCover(from = coverVisible(shown, cover, now), to = parts, start = now)
        } else {
            null
        }
        shown = parts
    }

    Canvas(modifier = modifier.size(size)) {
        val now = time.doubleValue
        val activeCover = if (animate) cover else null
        val visible = coverVisible(parts, activeCover, now)
        var frame = if (animate) CatMotion.frame(motion, now) else CatMotionFrame.still(motion)
        if (activeCover != null) {
            frame = frame.copy(
                blink = max(frame.blink, CatMotion.coverBlink(now - activeCover.start)),
            )
        }
        with(CatDrawer) { draw(visible, frame, dark) }
    }
}

/** 循环姿势是时间的纯函数；换脸是一次覆盖眨眼，也由同一只时钟取样。 */
private data class CatCover(val from: CatParts, val to: CatParts, val start: Double)

private fun coverVisible(parent: CatParts, cover: CatCover?, now: Double): CatParts {
    if (cover == null) return parent
    return if (now - cover.start < CatMotion.COVER_SWAP_ELAPSED) cover.from else cover.to
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CatViewPreview() {
    Column(
        modifier = Modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CatMood.entries.chunked(4).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                row.forEach { mood ->
                    Column {
                        CatView(mood = mood, size = 72.dp, isAnimated = false)
                        Text(mood.name, style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
    }
}
