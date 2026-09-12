package com.zhechengqi.tollcat.ui

import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.material3.Card
import androidx.compose.material3.CardColors
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun ExpressiveCard(
    modifier: Modifier = Modifier,
    prominent: Boolean = false,
    colors: CardColors = CardDefaults.cardColors(
        containerColor = MaterialTheme.colorScheme.surfaceContainer,
    ),
    content: @Composable ColumnScope.() -> Unit,
) {
    Card(
        modifier = modifier,
        shape = if (prominent) {
            MaterialTheme.shapes.extraLargeIncreased
        } else {
            MaterialTheme.shapes.extraLarge
        },
        colors = colors,
        content = content,
    )
}
