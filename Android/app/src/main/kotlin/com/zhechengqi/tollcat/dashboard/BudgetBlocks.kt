package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.invisibleToUser
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing
import kotlin.math.roundToInt

/**
 * 预算格子：两排、默认二十列。超预算全染成红——格子只说「满了」，超了多少看数字。
 */
@Composable
fun BudgetBlocks(
    fraction: Float,
    isOver: Boolean,
    isClose: Boolean,
    modifier: Modifier = Modifier,
    columns: Int = 20,
    rows: Int = 2,
) {
    val tint = when {
        isOver -> MaterialTheme.colorScheme.error
        isClose -> MaterialTheme.colorScheme.tertiary
        else -> MaterialTheme.colorScheme.primary
    }
    val empty = MaterialTheme.colorScheme.outlineVariant
    val total = columns * rows
    val filled = when {
        fraction <= 0f -> 0
        else -> minOf(total, maxOf(1, (total * fraction.coerceAtMost(1f)).roundToInt()))
    }
    val radius = RoundedCornerShape(3.dp)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .semantics { invisibleToUser() },
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.budgetBlockGap),
    ) {
        repeat(rows) { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.budgetBlockGap),
            ) {
                repeat(columns) { column ->
                    val index = row * columns + column
                    Box(
                        Modifier
                            .weight(1f)
                            .aspectRatio(1f)
                            .clip(radius)
                            .background(if (index < filled) tint else empty),
                    )
                }
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun BudgetBlocksPreview() {
    TollCatTheme {
        Column(Modifier.padding(MeterSpacing.md), verticalArrangement = Arrangement.spacedBy(MeterSpacing.md)) {
            BudgetBlocks(fraction = 0.59f, isOver = false, isClose = false)
            BudgetBlocks(fraction = 1.14f, isOver = true, isClose = true)
        }
    }
}
