package com.zhechengqi.tollcat.ui

import androidx.compose.animation.AnimatedVisibilityScope
import androidx.compose.animation.BoundsTransform
import androidx.compose.animation.ExperimentalSharedTransitionApi
import androidx.compose.animation.SharedTransitionScope
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Shape

@OptIn(ExperimentalSharedTransitionApi::class)
val LocalSharedTransitionScope = compositionLocalOf<SharedTransitionScope?> { null }

val LocalAnimatedVisibilityScope = compositionLocalOf<AnimatedVisibilityScope?> { null }

/** 列表行 ↔ 详情，对齐 Jetcaster `sharedElement` + Androidify `slowSpatialSpec`。 */
@OptIn(ExperimentalSharedTransitionApi::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun Modifier.sharedProviderElement(providerId: String): Modifier {
    if (LocalReduceMotion.current) return this
    val shared = LocalSharedTransitionScope.current ?: return this
    val visibility = LocalAnimatedVisibilityScope.current ?: return this
    val spatial = MaterialTheme.motionScheme.slowSpatialSpec<Rect>()
    return with(shared) {
        this@sharedProviderElement.sharedElement(
            sharedContentState = rememberSharedContentState(key = "provider:$providerId"),
            animatedVisibilityScope = visibility,
            boundsTransform = BoundsTransform { _, _ -> spatial },
            clipInOverlayDuringTransition = OverlayClip(MaterialTheme.shapes.medium),
        )
    }
}

/**
 * 行 ↔ 详情头的 container transform：整行容器变形为详情 hero 卡，
 * 比只共享 glyph 的关系强得多（M3 transition-patterns：浅层级「展开看细节」首选，
 * persistent element 通常就是容器本身）。行侧传行形状、详情侧传卡形状，
 * 过渡里由 overlay 裁切完成 10dp↔28dp 的圆角 morph。glyph 的 [sharedProviderElement]
 * 继续叠加在内部，保证图标连续。「移除动画」时整体退化为 fade（返回原 Modifier）。
 */
@OptIn(ExperimentalSharedTransitionApi::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun Modifier.sharedProviderContainer(providerId: String, shape: Shape): Modifier {
    if (LocalReduceMotion.current) return this
    val shared = LocalSharedTransitionScope.current ?: return this
    val visibility = LocalAnimatedVisibilityScope.current ?: return this
    val spatial = MaterialTheme.motionScheme.slowSpatialSpec<Rect>()
    return with(shared) {
        this@sharedProviderContainer.sharedBounds(
            sharedContentState = rememberSharedContentState(key = "provider-container:$providerId"),
            animatedVisibilityScope = visibility,
            boundsTransform = BoundsTransform { _, _ -> spatial },
            resizeMode = SharedTransitionScope.ResizeMode.RemeasureToBounds,
            clipInOverlayDuringTransition = OverlayClip(shape),
        )
    }
}
