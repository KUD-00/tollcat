package com.zhechengqi.tollcat.ui

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape

/**
 * 骨架块（M3 transition-patterns 的 skeleton loader 定式）：微弱脉冲表 indeterminate，
 * [delayMillis] 让各块相位错开、从左上向右下推进；内容就绪后由外层 fade 盖上来。
 * 「移除动画」时静止在中间透明度。
 */
@Composable
fun SkeletonBox(
    shape: Shape,
    modifier: Modifier = Modifier,
    delayMillis: Int = 0,
) {
    val transition = rememberInfiniteTransition(label = "skeleton")
    val pulse by transition.animateFloat(
        initialValue = 0.35f,
        targetValue = 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 700, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse,
            initialStartOffset = StartOffset(delayMillis),
        ),
        label = "skeleton-pulse",
    )
    val alpha = if (LocalReduceMotion.current) 0.5f else pulse
    Box(
        modifier.background(
            MaterialTheme.colorScheme.surfaceContainerHigh.copy(alpha = alpha),
            shape,
        ),
    )
}
