package com.zhechengqi.tollcat.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.IntOffset

/**
 * 主角金额。`tnum` 等宽数字下逐位独立上下滚——涨从下方滚进，降从上方落下，
 * 像里程计而不是整串闪变。首帧不播动画，刷新时才动。
 * 字体走 [amountTextStyle]（系统字 + tnum）；「移除动画」时直接换数字。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AmountText(
    text: String,
    modifier: Modifier = Modifier,
    style: TextStyle = MaterialTheme.typography.displayMediumEmphasized,
    color: Color = Color.Unspecified,
) {
    val amountStyle = amountTextStyle(style)
    if (LocalReduceMotion.current) {
        Text(
            text = text,
            style = amountStyle,
            color = color,
            maxLines = 1,
            modifier = modifier.semantics(mergeDescendants = true) {},
        )
        return
    }
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<IntOffset>()
    val fade = MaterialTheme.motionScheme.defaultEffectsSpec<Float>()
    // mergeDescendants：读屏把整串并成一个结点，调用方的 contentDescription 照常生效。
    Row(modifier = modifier.semantics(mergeDescendants = true) {}) {
        text.forEachIndexed { index, char ->
            AnimatedContent(
                targetState = char,
                transitionSpec = {
                    val rollsUp = !(targetState.isDigit() && initialState.isDigit() && targetState < initialState)
                    val direction = if (rollsUp) 1 else -1
                    (slideInVertically(spatial) { it * direction } + fadeIn(fade)) togetherWith
                        (slideOutVertically(spatial) { -it * direction } + fadeOut(fade))
                },
                label = "amount-digit-$index",
            ) { value ->
                Text(
                    text = value.toString(),
                    style = amountStyle,
                    color = color,
                    maxLines = 1,
                )
            }
        }
    }
}
