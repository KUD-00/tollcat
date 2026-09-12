package com.zhechengqi.tollcat.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Modifier

/**
 * 顶层 Tab：对齐 Androidify `NavDisplay.transitionSpec`，只走 effects fade。
 *
 * 每个目标按 [contentKey] 留一份 Saveable 状态。Tab 切走会卸掉组合树，
 * 不包的话再切回来列表会从顶部开始。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun <T> FadeThroughContent(
    targetState: T,
    modifier: Modifier = Modifier,
    contentKey: (T) -> Any? = { it },
    content: @Composable (T) -> Unit,
) {
    val fade = MaterialTheme.motionScheme.defaultEffectsSpec<Float>()
    val saveableStateHolder = rememberSaveableStateHolder()
    AnimatedContent(
        targetState = targetState,
        modifier = modifier,
        transitionSpec = {
            ContentTransform(
                fadeIn(fade),
                fadeOut(fade),
            )
        },
        contentKey = contentKey,
        label = "fade-through",
    ) { state ->
        val visibility = this
        saveableStateHolder.SaveableStateProvider(contentKey(state) ?: state ?: Unit) {
            CompositionLocalProvider(LocalAnimatedVisibilityScope provides visibility) {
                content(state)
            }
        }
    }
}
