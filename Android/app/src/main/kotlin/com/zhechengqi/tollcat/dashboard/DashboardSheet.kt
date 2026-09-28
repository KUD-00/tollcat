package com.zhechengqi.tollcat.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** 内容纸压住顶栏下沿的深度。顶栏底边距要把它算进去，否则最后一行字会被盖住。 */
internal val DashboardSheetOverlap = 32.dp

/**
 * 顶栏下面那张「纸」：32dp 上圆角、surface 底，往上提 [DashboardSheetOverlap] 盖住顶栏下沿。
 * 子项自己管左右边距——横滑卡片要贴到屏幕边缘，不能被这里的 padding 截住。
 */
@Composable
fun DashboardSheet(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier
            .pullUp(DashboardSheetOverlap)
            .fillMaxWidth()
            .clip(RoundedCornerShape(topStart = DashboardSheetOverlap, topEnd = DashboardSheetOverlap))
            .background(MaterialTheme.colorScheme.surface)
            .padding(top = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        content = content,
    )
}

/** 往上提一段、同时把占位高度减掉同样的量：后面的兄弟不会跟着留一条缝。 */
internal fun Modifier.pullUp(amount: Dp): Modifier = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints)
    val shift = amount.roundToPx()
    layout(placeable.width, (placeable.height - shift).coerceAtLeast(0)) {
        placeable.place(0, -shift)
    }
}
