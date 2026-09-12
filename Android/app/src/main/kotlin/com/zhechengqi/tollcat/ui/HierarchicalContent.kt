package com.zhechengqi.tollcat.ui

import androidx.activity.BackEventCompat
import androidx.activity.compose.PredictiveBackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.launch

/**
 * 层级推进：前进 fadeIn + 1/8 宽度的横向滑入（M3 forward/backward 的空间模型——
 * fade-through 留给顶级 Tab），返回 fadeIn + scaleOut(0.7)。Sheet / Dialog 不走这里。
 * 系统「移除动画」时全部退化为纯 fade。
 *
 * 传入 [onPop] 之后由这里接管返回手势：页面跟着手指缩小并挪向对侧，
 * 松手取消就弹回原位，划到头才真正出栈。M3 预测性返回的缩放下限是 0.9，
 * 提交后容器从手势残留的比例回弹到 1，出栈动画在里面照常播。
 *
 * 每一层用 [rememberSaveableStateHolder] 按 [contentKey] 存一份 UI 状态。
 * AnimatedContent 出栈会把父页卸出组合树，不这样包的话滚动位置会丢，
 * 返回就跳回顶部。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun <T> HierarchicalContent(
    targetState: T,
    depth: Int,
    modifier: Modifier = Modifier,
    canPop: Boolean = false,
    onPop: (() -> Unit)? = null,
    contentKey: (T) -> Any? = { it },
    content: @Composable (T) -> Unit,
) {
    var lastDepth by remember { mutableIntStateOf(depth) }
    val popping = depth < lastDepth
    SideEffect { lastDepth = depth }
    val fade = MaterialTheme.motionScheme.defaultEffectsSpec<Float>()
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    val slide = MaterialTheme.motionScheme.defaultSpatialSpec<IntOffset>()
    val reduceMotion = LocalReduceMotion.current

    val gesture = remember { Animatable(0f) }
    var gestureEdge by remember { mutableIntStateOf(BackEventCompat.EDGE_LEFT) }
    val scope = rememberCoroutineScope()
    val saveableStateHolder = rememberSaveableStateHolder()
    if (onPop != null) {
        PredictiveBackHandler(enabled = canPop) { events ->
            try {
                events.collect { event ->
                    gestureEdge = event.swipeEdge
                    gesture.snapTo(event.progress)
                }
                onPop()
                scope.launch { gesture.animateTo(0f, spatial) }
            } catch (e: CancellationException) {
                scope.launch { gesture.animateTo(0f, spatial) }
                throw e
            }
        }
    }

    // 手势里圆角是常量，不跟进度走：AnimatedContent 每帧都在重组，
    // 没必要再为形状多算一轮；0.05 进度就满圆角，肉眼读成「一开始就是圆的」。
    val gestureShape = remember { RoundedCornerShape(28.dp) }
    AnimatedContent(
        targetState = targetState,
        modifier = modifier.graphicsLayer {
            val k = gesture.value
            if (k > 0f) {
                val scale = 1f - 0.1f * k
                scaleX = scale
                scaleY = scale
                translationX = size.width * 0.05f * k *
                    (if (gestureEdge == BackEventCompat.EDGE_LEFT) 1f else -1f)
                shape = gestureShape
                clip = true
            }
        },
        transitionSpec = {
            when {
                reduceMotion -> ContentTransform(
                    fadeIn(fade),
                    fadeOut(fade),
                )
                popping -> ContentTransform(
                    fadeIn(fade),
                    scaleOut(targetScale = 0.7f),
                )
                else -> ContentTransform(
                    fadeIn(fade) + slideInHorizontally(slide) { it / 8 },
                    fadeOut(fade),
                )
            }
        },
        contentKey = contentKey,
        label = "hierarchical",
    ) { state ->
        val visibility = this
        saveableStateHolder.SaveableStateProvider(contentKey(state) ?: state ?: Unit) {
            CompositionLocalProvider(LocalAnimatedVisibilityScope provides visibility) {
                content(state)
            }
        }
    }
}
