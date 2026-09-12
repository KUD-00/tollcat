package com.zhechengqi.tollcat.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.material3.ButtonGroup
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ButtonGroupScope
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun OverflowButtonGroup(
    modifier: Modifier = Modifier,
    content: ButtonGroupScope.() -> Unit,
) {
    // ButtonGroup 自己 fillMaxWidth 时，overflow 会把剩余宽度减成负数然后崩。
    Box(modifier, contentAlignment = Alignment.CenterStart) {
        ButtonGroup(
            overflowIndicator = { ButtonGroupDefaults.OverflowIndicator(it) },
            content = content,
        )
    }
}
