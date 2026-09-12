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
        modifier = modifier
            .heightIn(min = height)
            .animateContentSize()
            .indication(interactionSource, ScaleIndicationNodeFactory(pressSpec)),
        enabled = enabled,
        interactionSource = interactionSource,
        shapes = ButtonDefaults.shapes(),
        contentPadding = ButtonDefaults.contentPaddingFor(height),
        content = content,
    )
}
