package com.zhechengqi.tollcat.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp

/**
 * 仪表与列表都按一组 bento 排：卡与卡之间只留 3dp 缝，组外沿 28dp 大圆角、
 * 组内缝 10dp 小圆角。辨识度来自「一组」而不是一摞等距同形的卡。
 */
internal object Bento {
    /** 组内缝。16dp 是「一摞卡」，3dp 才是「一组」。 */
    val gap = 3.dp

    private val outer = 28.dp
    private val inner = 10.dp

    fun shape(
        topStart: Boolean = false,
        topEnd: Boolean = false,
        bottomStart: Boolean = false,
        bottomEnd: Boolean = false,
    ) = RoundedCornerShape(
        topStart = if (topStart) outer else inner,
        topEnd = if (topEnd) outer else inner,
        bottomStart = if (bottomStart) outer else inner,
        bottomEnd = if (bottomEnd) outer else inner,
    )

    fun groupShape(first: Boolean, last: Boolean) = shape(
        topStart = first,
        topEnd = first,
        bottomStart = last,
        bottomEnd = last,
    )

    val top = shape(topStart = true, topEnd = true)
    val middle = shape()
    val bottom = shape(bottomStart = true, bottomEnd = true)

    /** 独立一张、不属于任何组的卡。 */
    val solo = shape(topStart = true, topEnd = true, bottomStart = true, bottomEnd = true)

    /** 猫的聊天气泡（M3 会话样式，20dp 圆角）：左上收 4dp，尾角指向左侧的猫头像。 */
    val speech = RoundedCornerShape(
        topStart = 4.dp,
        topEnd = 20.dp,
        bottomStart = 20.dp,
        bottomEnd = 20.dp,
    )

    /** 气泡在猫上方时的变体：右下收 4dp，尾角朝下指向坐在下一张卡沿上的猫。 */
    val speechDown = RoundedCornerShape(
        topStart = 20.dp,
        topEnd = 20.dp,
        bottomStart = 20.dp,
        bottomEnd = 4.dp,
    )
}

/**
 * 一组 bento 的通用容器：组透明、成员自带底色（[Bento.middle] 缝角），
 * 行间 3dp 缝，整组再裁一刀 28dp——成员不需要知道自己是首是末。
 */
@Composable
internal fun BentoGroup(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp)),
        verticalArrangement = Arrangement.spacedBy(Bento.gap),
        content = content,
    )
}

/** bento 组成员 `ListItem` 的统一底色。 */
@Composable
internal fun bentoRowColors() = ListItemDefaults.colors(
    containerColor = MaterialTheme.colorScheme.surfaceContainer,
)
