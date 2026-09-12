package com.zhechengqi.tollcat.widget

import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp

/** SPEC 第 09 节三种结构，不是把中号拉伸。 */
enum class WidgetFamily {
    Small,
    Medium,
    Large,
    ;

    companion object {
        val smallSize = DpSize(110.dp, 110.dp)
        val mediumSize = DpSize(250.dp, 110.dp)
        val largeSize = DpSize(250.dp, 250.dp)

        fun from(size: DpSize): WidgetFamily = when {
            size.height >= largeSize.height -> Large
            size.width >= mediumSize.width -> Medium
            else -> Small
        }
    }
}
