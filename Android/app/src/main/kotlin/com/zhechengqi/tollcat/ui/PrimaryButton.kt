package com.zhechengqi.tollcat.ui

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.indication
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun PrimaryButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable RowScope.() -> Unit,
) {
    val height = ButtonDefaults.MediumContainerHeight
    val interactionSource = remember { MutableInteractionSource() }
    val pressSpec = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    Button(
        onClick = onClick,
        // 放大要在 animateContentSize 外面：它自带按矩形裁切，放大画在里面的话，
        // 胶囊的圆角一按就被切成直角，像被一个盒子框住。
        modifier = modifier
            .heightIn(min = height)
            .indication(interactionSource, ScaleIndicationNodeFactory(pressSpec))
            .animateContentSize(),
        enabled = enabled,
        interactionSource = interactionSource,
        // 按下时的形状要跟高度同档：`shapes()` 给的是小号按钮的按压圆角，
        // 套在中号高度上一按就几乎成直角。
        shapes = ButtonDefaults.shapesFor(height),
        contentPadding = ButtonDefaults.contentPaddingFor(height),
        content = content,
    )
}
