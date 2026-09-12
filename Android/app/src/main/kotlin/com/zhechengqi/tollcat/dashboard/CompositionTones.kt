package com.zhechengqi.tollcat.dashboard

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/**
 * 构成条 / 环的配色。**一档一档从当前 scheme 上取**，不另造调色板。
 *
 * 分享卡拿不到 `MaterialTheme`（它在 Canvas 上画，而且锁浅色），所以这里留一个
 * 收 `ColorScheme` 的重载——分享卡传亮色品牌方案进来，画出来和屏幕上是同一组色。
 * 它以前自己写了六个十六进制值，既不是这套也不是品牌色。
 */
object CompositionTones {
    const val namedLimit = 5

    @Composable
    fun color(index: Int, isOther: Boolean = false): Color =
        color(MaterialTheme.colorScheme, index, isOther)

    fun color(scheme: ColorScheme, index: Int, isOther: Boolean = false): Color {
        if (isOther) return scheme.outline
        val tones = listOf(
            scheme.primary,
            scheme.tertiary,
            scheme.secondary,
            scheme.primary.copy(alpha = 0.45f),
            scheme.tertiary.copy(alpha = 0.45f),
        )
        return tones[index.mod(tones.size)]
    }
}
