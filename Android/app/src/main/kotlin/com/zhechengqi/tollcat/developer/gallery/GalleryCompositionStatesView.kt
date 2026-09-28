package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.CompositionBarsCard
import com.zhechengqi.tollcat.dashboard.CompositionSegmentsCard
import com.zhechengqi.tollcat.dashboard.CompositionShapeCluster
import com.zhechengqi.tollcat.dashboard.CompositionTreemap
import com.zhechengqi.tollcat.developer.GalleryFixtures

private val styles = listOf("横向粗条", "分段条", "形状拼贴", "树图")

/**
 * 构成的四种画法 × 五种数据形状。主页用横向粗条；其余三种在这里对照。
 * 顶上切画法，下面每一块是一种数据形状（1 家 / 2 家 / 5 家 / 超过 5 家 / 一家独大）。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun GalleryCompositionStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var style by remember { mutableIntStateOf(0) }
    GalleryScaffold(title = stringResource(R.string.module_composition), onBack = onBack, modifier = modifier) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween),
            modifier = Modifier.fillMaxWidth(),
        ) {
            styles.forEachIndexed { index, label ->
                ToggleButton(
                    checked = style == index,
                    onCheckedChange = { if (it) style = index },
                    modifier = Modifier.weight(1f),
                    shapes = when (index) {
                        0 -> ButtonGroupDefaults.connectedLeadingButtonShapes()
                        styles.lastIndex -> ButtonGroupDefaults.connectedTrailingButtonShapes()
                        else -> ButtonGroupDefaults.connectedMiddleButtonShapes()
                    },
                ) {
                    Text(label, maxLines = 1)
                }
            }
        }
        block(stringResource(R.string.dev_comp_5), GalleryFixtures.specComposition, style)
        block(stringResource(R.string.dev_comp_8), GalleryFixtures.eightProviderComposition, style)
        block(
            stringResource(R.string.dev_comp_2),
            GalleryFixtures.composition(
                listOf(
                    Triple("aws", "AWS", "$70.00" to 70),
                    Triple("cloudflare", "Cloudflare", "$30.00" to 30),
                ),
            ),
            style,
        )
        block(stringResource(R.string.dev_comp_1), GalleryFixtures.composition(listOf(Triple("aws", "AWS", "$100.00" to 100))), style)
        block(
            stringResource(R.string.dev_comp_100),
            GalleryFixtures.composition(listOf(Triple("openai", "OpenAI", "$100.00" to 100))),
            style,
        )
    }
}

@Composable
private fun block(title: String, rows: List<CompositionRow>, style: Int) {
    GalleryExhibit(title = title) {
        when (style) {
            0 -> CompositionBarsCard(rows = rows, onOpenRow = {}, onOpenAll = {})
            1 -> CompositionSegmentsCard(rows = rows, onOpenRow = {}, onOpenAll = {})
            2 -> CompositionShapeCluster(rows = rows, onOpenRow = {})
            else -> CompositionTreemap(rows = rows, onOpenRow = {})
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryCompositionStatesViewPreview() {
    TollCatTheme {
        GalleryCompositionStatesView(onBack = {})
    }
}
