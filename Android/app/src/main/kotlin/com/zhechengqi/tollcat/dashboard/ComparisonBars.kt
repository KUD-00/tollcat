package com.zhechengqi.tollcat.dashboard

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp

/** 较上月同期详情里的两根对照柱（本月 / 上月同期）。 */
@Composable
internal fun ComparisonBars(content: ComparisonContent) {
    val current = MaterialTheme.colorScheme.primary
    val previous = MaterialTheme.colorScheme.primary.copy(alpha = 0.35f)
    val showsPrevious = content.tone != ComparisonContent.Tone.Unknown
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        ComparisonBar(label = content.currentLabel, weight = content.currentWeight, color = current)
        if (showsPrevious) {
            ComparisonBar(label = content.previousLabel, weight = content.previousWeight, color = previous)
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ComparisonBar(label: String, weight: Float, color: androidx.compose.ui.graphics.Color) {
    var target by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(weight) { target = weight.coerceIn(0.08f, 1f) }
    val animated by animateFloatAsState(
        targetValue = target,
        animationSpec = MaterialTheme.motionScheme.defaultSpatialSpec(),
        label = "comparison-bar",
    )
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(label, style = MaterialTheme.typography.labelSmall)
        Box(
            modifier = Modifier
                .fillMaxWidth(animated.coerceIn(0f, 1f))
                .height(8.dp)
                .clip(MaterialTheme.shapes.extraSmall)
                .background(color),
        )
    }
}
