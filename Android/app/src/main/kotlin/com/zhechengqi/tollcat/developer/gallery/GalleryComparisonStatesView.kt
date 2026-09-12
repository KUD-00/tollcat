package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.ComparisonContent
import com.zhechengqi.tollcat.dashboard.ComparisonTileView

@Composable
fun GalleryComparisonStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val current = stringResource(R.string.dashboard_comparison_this_month)
    val previous = stringResource(R.string.dashboard_comparison_last_month)
    val unavailable = stringResource(R.string.dashboard_comparison_unavailable)
    GalleryScaffold(
        title = stringResource(R.string.module_comparison),
        onBack = onBack,
        modifier = modifier,
    ) {
        // AWS 21.40/13.20 + Cloudflare 11.05/58.40 → 32.45 vs 71.60 = -55%。
        tile(
            title = stringResource(R.string.dev_compare_all),
            content = comparisonContent(
                percentText = "-55%",
                caption = "对比 7月同期 $71.60",
                current = 32.45f,
                previous = 71.60f,
                currentLabel = current,
                previousLabel = previous,
                tone = ComparisonContent.Tone.Down,
            ),
        )
        // AWS 21.40/13.20 + Neon 3.13 无同期 → 24.53 vs 13.20 = +86%。
        tile(
            title = stringResource(R.string.dev_compare_partial),
            content = comparisonContent(
                percentText = "+86%",
                caption = stringResource(R.string.dev_row_percent_sub),
                current = 24.53f,
                previous = 13.20f,
                currentLabel = current,
                previousLabel = previous,
                tone = ComparisonContent.Tone.Up,
            ),
        )
        Text(
            stringResource(R.string.dashboard_comparison_incomparable_footer),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        tile(
            title = stringResource(R.string.dev_compare_none),
            content = ComparisonContent(
                percentText = "—",
                caption = unavailable,
                spokenLabel = unavailable,
                currentWeight = 1f,
                previousWeight = 1f,
                currentLabel = current,
                previousLabel = previous,
                tone = ComparisonContent.Tone.Unknown,
            ),
        )
    }
}

@Composable
private fun tile(title: String, content: ComparisonContent) {
    Spacer(Modifier.height(12.dp))
    Text(title, style = MaterialTheme.typography.titleSmall)
    ComparisonTileView(content = content)
}

private fun comparisonContent(
    percentText: String,
    caption: String,
    current: Float,
    previous: Float,
    currentLabel: String,
    previousLabel: String,
    tone: ComparisonContent.Tone,
): ComparisonContent {
    val max = maxOf(current, previous, 0.01f)
    return ComparisonContent(
        percentText = percentText,
        caption = caption,
        spokenLabel = "$percentText. $caption",
        currentWeight = current / max,
        previousWeight = previous / max,
        currentLabel = currentLabel,
        previousLabel = previousLabel,
        tone = tone,
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryComparisonStatesViewPreview() {
    TollCatTheme {
        GalleryComparisonStatesView(onBack = {})
    }
}
