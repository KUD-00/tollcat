package com.zhechengqi.tollcat.developer

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R

/**
 * 宽壳卡要看的四档宽度。内容宽写死——实验室量自己再回填，
 * 就是第一版把主线程转死的那条路。
 */
enum class DashboardLabWidthSample {
    Compact,
    Regular,
    Wide,
    Expanded,
    ;

    val contentWidth: Dp
        get() = when (this) {
            Compact -> 155.dp
            Regular -> 218.dp
            Wide -> 460.dp
            Expanded -> 628.dp
        }

    val outerWidth: Dp get() = contentWidth + cardPadding * 2

    val titleRes: Int
        get() = when (this) {
            Compact -> R.string.dev_lab_width_compact
            Regular -> R.string.dev_lab_width_regular
            Wide -> R.string.dev_lab_width_wide
            Expanded -> R.string.dev_lab_width_expanded
        }

    val captionRes: Int
        get() = when (this) {
            Compact -> R.string.dev_lab_width_compact_caption
            Regular -> R.string.dev_lab_width_regular_caption
            Wide -> R.string.dev_lab_width_wide_caption
            Expanded -> R.string.dev_lab_width_expanded_caption
        }

    companion object {
        val cardPadding: Dp = 16.dp
        val outerHeight: Dp = 240.dp
        val listContentWidth: Dp = 345.dp
    }
}
