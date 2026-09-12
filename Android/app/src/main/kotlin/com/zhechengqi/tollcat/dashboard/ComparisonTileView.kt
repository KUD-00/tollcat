@file:OptIn(androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.LocalTollCatColors
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@Composable
fun ComparisonTileView(
    content: ComparisonContent,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
    onClick: (() -> Unit)? = null,
) {
    val percentColor = when (content.tone) {
        ComparisonContent.Tone.Up -> LocalTollCatColors.current.spendUp.main
        ComparisonContent.Tone.Down -> LocalTollCatColors.current.spendDown.main
        ComparisonContent.Tone.Flat, ComparisonContent.Tone.Unknown ->
            MaterialTheme.colorScheme.onSecondaryContainer
    }
    val symbol = when (content.tone) {
        ComparisonContent.Tone.Up -> MaterialSymbol.TrendingUp
        ComparisonContent.Tone.Down -> MaterialSymbol.TrendingDown
        ComparisonContent.Tone.Flat, ComparisonContent.Tone.Unknown -> MaterialSymbol.TrendingFlat
    }
    val hint = stringResource(R.string.dashboard_comparison_hint)
    val clickableModifier = if (onClick != null) {
        Modifier.clickable(onClick = onClick)
    } else {
        Modifier
    }
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .then(clickableModifier)
            .semantics {
                contentDescription = if (onClick != null) {
                    "${content.spokenLabel}。$hint"
                } else {
                    content.spokenLabel
                }
            },
    ) {
        Column(
            modifier = Modifier.padding(MeterSpacing.lg),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.module_comparison),
                    style = MaterialTheme.typography.labelLarge,
                    modifier = Modifier.weight(1f),
                )
                if (onClick != null) {
                    SymbolIcon(
                        MaterialSymbol.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f),
                    )
                }
            }
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
            ) {
                SymbolIcon(symbol, contentDescription = null)
                Text(
                    text = content.percentText,
                    style = MaterialTheme.typography.headlineSmall.copy(
                        fontWeight = FontWeight.SemiBold,
                        fontFeatureSettings = "tnum",
                    ),
                    color = percentColor,
                    maxLines = 1,
                )
            }
            ComparisonBars(content)
        }
    }
}

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

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ComparisonTileViewPreview() {
    TollCatTheme {
        ComparisonTileView(
            content = ComparisonContent(
                percentText = "+62%",
                caption = "对比 7月同期 $29.10",
                spokenLabel = "+62%. 对比 7月同期 $29.10",
                currentWeight = 1f,
                previousWeight = 1f / 1.62f,
                currentLabel = "本月",
                previousLabel = "上月",
                tone = ComparisonContent.Tone.Up,
            ),
            onClick = {},
        )
    }
}

@Preview(name = "Unknown Light", showBackground = true)
@Preview(name = "Unknown Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ComparisonTileViewUnknownPreview() {
    TollCatTheme {
        ComparisonTileView(
            content = ComparisonContent(
                percentText = "—",
                caption = "还不能对比",
                spokenLabel = "还不能和上月同期对比",
                currentWeight = 1f,
                previousWeight = 1f,
                currentLabel = "本月",
                previousLabel = "上月",
                tone = ComparisonContent.Tone.Unknown,
            ),
            onClick = {},
        )
    }
}
