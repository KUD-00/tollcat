package com.zhechengqi.tollcat.ui

import android.app.UiModeManager
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext

/** M3 的三档对比度（2025-05 起 color role 体系自带），品牌静态方案按档切换预生成 scheme。 */
enum class ContrastTier {
    Standard,
    Medium,
    High,
    ;

    companion object {
        fun fromSystem(contrast: Float): ContrastTier = when {
            contrast >= 2f / 3f -> High
            contrast >= 1f / 3f -> Medium
            else -> Standard
        }
    }
}

/**
 * 系统对比度设置（Android 14+ 的「对比度」）。动态取色由系统面板自己带对比度，
 * 这里只服务品牌静态方案；API < 34 恒为 Standard。
 */
@Composable
fun rememberContrastTier(): ContrastTier {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return ContrastTier.Standard
    val context = LocalContext.current
    val manager = remember(context) { context.getSystemService(UiModeManager::class.java) }
        ?: return ContrastTier.Standard
    var tier by remember { mutableStateOf(ContrastTier.fromSystem(manager.contrast)) }
    DisposableEffect(manager) {
        val listener = UiModeManager.ContrastChangeListener { value ->
            tier = ContrastTier.fromSystem(value)
        }
        manager.addContrastChangeListener(context.mainExecutor, listener)
        onDispose { manager.removeContrastChangeListener(listener) }
    }
    return tier
}
