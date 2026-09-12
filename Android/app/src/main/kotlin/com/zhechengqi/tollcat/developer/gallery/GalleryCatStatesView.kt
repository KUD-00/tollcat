package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.ComparisonContent
import com.zhechengqi.tollcat.dashboard.DashboardCatMood
import com.zhechengqi.tollcat.dashboard.DashboardCatStage
import com.zhechengqi.tollcat.dashboard.art
import com.zhechengqi.tollcat.developer.GalleryFixtures
import com.zhechengqi.tollcat.ui.cat.CatView
import kotlin.math.abs

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun GalleryCatStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val studio = remember { GalleryCatStudio() }
    val composition = GalleryFixtures.specComposition
    val trend = GalleryFixtures.trend
    val comparison = ComparisonContent(
        percentText = "+62%",
        caption = stringResource(R.string.dev_row_percent_sub),
        spokenLabel = "+62%",
        currentWeight = 1f,
        previousWeight = 1f / 1.62f,
        currentLabel = stringResource(R.string.hero_label),
        previousLabel = stringResource(R.string.hero_label),
        tone = ComparisonContent.Tone.Up,
    )
    val empty = studio.mood == DashboardCatMood.Sleeping
    GalleryScaffold(title = stringResource(R.string.dev_gallery_cats), onBack = onBack, modifier = modifier) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            CatView(mood = studio.mood.art, size = studio.sizeDp.dp)
        }
        Spacer(Modifier.height(8.dp))
        Slider(
            value = studio.sizeDp,
            onValueChange = { studio.sizeDp = it },
            valueRange = 36f..180f,
            modifier = Modifier.fillMaxWidth(),
        )
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            listOf(36f, 88f, 96f, 180f).forEach { named ->
                FilterChip(
                    selected = abs(studio.sizeDp - named) < 0.5f,
                    onClick = { studio.sizeDp = named },
                    label = { Text(named.toInt().toString()) },
                )
            }
        }
        Spacer(Modifier.height(8.dp))
        DashboardCatMood.entries.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                row.forEach { mood ->
                    val selected = studio.mood == mood
                    val spoken = stringResource(mood.labelRes)
                    Surface(
                        color = if (selected) {
                            MaterialTheme.colorScheme.secondaryContainer
                        } else {
                            MaterialTheme.colorScheme.surface
                        },
                        contentColor = if (selected) {
                            MaterialTheme.colorScheme.onSecondaryContainer
                        } else {
                            MaterialTheme.colorScheme.onSurface
                        },
                        shape = MaterialTheme.shapes.medium,
                        modifier = Modifier
                            .weight(1f)
                            .clickable { studio.apply(mood) }
                            .semantics { contentDescription = spoken },
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(8.dp),
                        ) {
                            CatView(mood = mood.art, size = 64.dp, isAnimated = false)
                            Text(mood.raw, style = MaterialTheme.typography.labelSmall, maxLines = 1)
                        }
                    }
                }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
            Spacer(Modifier.height(8.dp))
        }
        Spacer(Modifier.height(8.dp))
        DashboardCatStage(
            composition = if (empty) emptyList() else composition,
            comparison = if (studio.mood == DashboardCatMood.Shocked || studio.mood == DashboardCatMood.Dead) {
                comparison
            } else {
                null
            },
            trend = if (empty) emptyList() else trend,
            mood = studio.mood,
            speech = speechFor(studio.mood),
            onOpenComposition = {},
        )
    }
}

@Composable
private fun speechFor(mood: DashboardCatMood): String {
    return when (mood) {
        DashboardCatMood.Normal -> stringResource(R.string.dashboard_cat_speech_normal, "$47.20", "$87.70")
        DashboardCatMood.Sleeping -> stringResource(R.string.dashboard_cat_speech_sleeping)
        DashboardCatMood.Saved -> stringResource(R.string.dashboard_cat_speech_saved, 12)
        DashboardCatMood.Alert -> stringResource(R.string.dashboard_cat_speech_alert)
        DashboardCatMood.Shocked -> stringResource(R.string.dashboard_cat_speech_shocked, 62)
        DashboardCatMood.Awkward -> stringResource(R.string.dashboard_cat_speech_awkward)
        DashboardCatMood.Dead -> stringResource(R.string.dashboard_cat_speech_dead)
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryCatStatesViewPreview() {
    TollCatTheme {
        GalleryCatStatesView(onBack = {})
    }
}
