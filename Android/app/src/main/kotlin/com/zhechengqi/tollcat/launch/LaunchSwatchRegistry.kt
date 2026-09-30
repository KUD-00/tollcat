package com.zhechengqi.tollcat.launch

import androidx.compose.runtime.Stable
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned

/**
 * 冷启动过渡要知道构成卡片里每一段的落点（条头那块服务小块）在屏幕上的位置：
 * 口袋里的圆牌要飞过去落在上面。只在启动那一两秒提供；分享图、小组件拿不到它。
 */
@Stable
class LaunchSwatchRegistry {
    /** 图例段 id → 落点（根坐标，px）。 */
    val targets = mutableStateMapOf<String, Rect>()

    /** 圆牌还在路上的那几块先藏起来（0），落地前那一小段淡进来；不在表里就是 1。 */
    val alpha = mutableStateMapOf<String, Float>()
}

val LocalLaunchSwatches = staticCompositionLocalOf<LaunchSwatchRegistry?> { null }

/** 构成条头的小块把自己报给启动过渡。没有 registry 时原样返回。 */
fun Modifier.launchSwatch(registry: LaunchSwatchRegistry?, id: String): Modifier {
    if (registry == null || id.isEmpty()) return this
    return this
        .onGloballyPositioned { registry.targets[id] = it.boundsInRoot() }
        .alpha(registry.alpha[id] ?: 1f)
}
