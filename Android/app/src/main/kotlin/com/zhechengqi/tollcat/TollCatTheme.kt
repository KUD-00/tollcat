package com.zhechengqi.tollcat

import android.os.Build
import androidx.compose.animation.ExperimentalSharedTransitionApi
import androidx.compose.animation.SharedTransitionLayout
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialExpressiveTheme
import androidx.compose.material3.MotionScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import com.zhechengqi.tollcat.settings.ColorSourcePreference
import com.zhechengqi.tollcat.ui.AppearanceMode
import com.zhechengqi.tollcat.ui.AppearancePreferences
import com.zhechengqi.tollcat.ui.LocalAppearancePreferences
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.LocalSharedTransitionScope
import com.zhechengqi.tollcat.ui.LocalTollCatColors
import com.zhechengqi.tollcat.ui.TollCatAccent
import com.zhechengqi.tollcat.ui.TollCatSemanticColors
import com.zhechengqi.tollcat.ui.rememberContrastTier
import com.zhechengqi.tollcat.ui.rememberReduceMotion

@OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalSharedTransitionApi::class)
@Composable
fun TollCatTheme(
    appearance: AppearanceMode? = null,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val stored = remember { AppearancePreferences(context) }
    DisposableEffect(stored) {
        onDispose { stored.dispose() }
    }
    val mode = appearance ?: stored.mode
    val dark = mode.resolvesDark(isSystemInDarkTheme())
    CompositionLocalProvider(
        LocalAppearancePreferences provides stored,
        LocalReduceMotion provides rememberReduceMotion(),
    ) {
        val colorScheme = tollCatColorScheme(dark)
        ProvideTollCatColors(colorScheme) {
            MaterialExpressiveTheme(
                colorScheme = colorScheme,
                motionScheme = MotionScheme.expressive(),
                content = {
                    SharedTransitionLayout {
                        CompositionLocalProvider(LocalSharedTransitionScope provides this) {
                            content()
                        }
                    }
                },
            )
        }
    }
}

/**
 * 趋势语义色跟着当前 scheme 走：spendUp 借 error 四角色（M3「红色语义用现成 error 系」），
 * spendDown 是 MCU 生成的静态绿。设置页的外观预览主题也要包这一层，
 * 否则预览里的语义色还停在外层主题的明暗。
 */
@Composable
fun ProvideTollCatColors(colorScheme: ColorScheme, content: @Composable () -> Unit) {
    val dark = colorScheme.surface.luminance() < 0.5f
    val semantic = TollCatSemanticColors(
        spendUp = TollCatAccent(
            main = colorScheme.error,
            onMain = colorScheme.onError,
            container = colorScheme.errorContainer,
            onContainer = colorScheme.onErrorContainer,
        ),
        spendDown = tollCatSpendDown(dark),
    )
    CompositionLocalProvider(LocalTollCatColors provides semantic, content = content)
}

/**
 * 配色来源二选一：动态取色（API 31+，对比度由系统面板自带），
 * 或 TollCat 蓝品牌静态方案（全 API，按系统对比度设置切三档，也是 API < 31 的唯一路径）。
 */
@Composable
fun tollCatColorScheme(dark: Boolean): ColorScheme {
    val context = LocalContext.current
    val source = LocalAppearancePreferences.current.colorSource
    val dynamic = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        source == ColorSourcePreference.DYNAMIC
    return when {
        dynamic && dark -> dynamicDarkColorScheme(context)
        dynamic -> dynamicLightColorScheme(context)
        else -> tollCatBrandScheme(dark, rememberContrastTier())
    }
}
