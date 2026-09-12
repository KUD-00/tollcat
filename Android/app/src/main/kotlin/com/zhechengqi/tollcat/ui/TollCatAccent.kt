package com.zhechengqi.tollcat.ui

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * M3「define static colors」定式的四角色语义色：main/onMain 用在 surface 之上，
 * container/onContainer 是保证对比的成对填色。禁止把 main 印到别的 container 上——
 * 只有 on- 配对有对比度保障。
 */
@Immutable
data class TollCatAccent(
    val main: Color,
    val onMain: Color,
    val container: Color,
    val onContainer: Color,
)

/**
 * 趋势语义色。spendUp（花费上涨=坏）直接借 error 系——M3 明确「红色语义不用自定义」；
 * spendDown（花费下降=好）是自定义静态绿，色值由 MCU 从绿 seed 生成，两主题恒定语义。
 */
@Immutable
data class TollCatSemanticColors(
    val spendUp: TollCatAccent,
    val spendDown: TollCatAccent,
)

val LocalTollCatColors = staticCompositionLocalOf<TollCatSemanticColors> {
    error("LocalTollCatColors not provided")
}
