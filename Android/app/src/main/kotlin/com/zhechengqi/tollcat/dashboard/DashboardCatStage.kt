package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.TrendRow
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatView

/** 猫坐在卡缝上时的边长。viewBox 底部到剪影底边约 19% 是空的，落点按 81% 算。 */
private val catPerchSize = 84.dp

/** 剪影底边压过卡沿多少。0 是悬空贴边，正值是「坐进去」。 */
private val catPerchOverlap = 6.dp

/**
 * 主 bento 组里 hero 之下的部分：构成卡（猫坐在它的上沿、身子压在 hero 上）、
 * 对话气泡、对比 / 趋势瓷砖。[isGroupTail] 为真时最后一件带组外沿的大圆角。
 */
@Composable
fun DashboardCatStage(
    composition: List<CompositionRow>,
    comparison: ComparisonContent?,
    trend: List<TrendRow>,
    mood: DashboardCatMood,
    speech: String,
    onOpenComposition: () -> Unit,
    onOpenComparison: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
    isGroupTail: Boolean = true,
    showsCat: Boolean = true,
) {
    val moodLabel = stringResource(mood.labelRes)
    val hasTiles = comparison != null || trend.isNotEmpty()
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Bento.gap),
    ) {
        if (composition.isNotEmpty()) {
            if (showsCat) {
                // 会话样式：气泡收缩到内容宽、靠右悬在猫头顶左侧，
                // 右下 4dp 尾角指向坐在下一张卡沿上的猫。
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(end = 104.dp, bottom = 2.dp),
                    horizontalArrangement = Arrangement.End,
                ) {
                    SpeechBubble(
                        speech = speech,
                        moodLabel = moodLabel,
                        shape = Bento.speechDown,
                    )
                }
            }
            Box {
                CompositionModuleView(
                    rows = composition,
                    onOpen = onOpenComposition,
                    shape = if (isGroupTail && !hasTiles) Bento.bottom else Bento.middle,
                )
                if (showsCat) {
                    CatView(
                        mood = mood.art,
                        size = catPerchSize,
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = (-20).dp, y = catPerchOverlap - catPerchSize * 0.81f)
                            .semantics { contentDescription = moodLabel },
                    )
                }
            }
        } else if (showsCat) {
            // 会话样式：猫在左当头像，气泡在右，左上 4dp 尾角指向猫。
            Row(
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(vertical = 8.dp),
            ) {
                CatView(
                    mood = mood.art,
                    size = 80.dp,
                    modifier = Modifier.semantics { contentDescription = moodLabel },
                )
                SpeechBubble(
                    speech = speech,
                    moodLabel = moodLabel,
                    shape = Bento.speech,
                )
            }
        }
        if (hasTiles) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Bento.gap),
            ) {
                val trailingOnly = comparison == null || trend.isEmpty()
                if (comparison != null) {
                    ComparisonTileView(
                        content = comparison,
                        shape = Bento.shape(
                            bottomStart = isGroupTail,
                            bottomEnd = isGroupTail && trailingOnly,
                        ),
                        modifier = Modifier.weight(1f),
                        onClick = onOpenComparison,
                    )
                }
                if (trend.isNotEmpty()) {
                    // 混排跨度（官方 bento 模板是 ⅓+⅔）：图表比对比数字更值得宽。
                    TrendTileView(
                        points = trend,
                        shape = Bento.shape(
                            bottomStart = isGroupTail && trailingOnly,
                            bottomEnd = isGroupTail,
                        ),
                        modifier = Modifier.weight(if (comparison != null) 1.7f else 1f),
                    )
                }
            }
        }
    }
}

/** 会话气泡：宽度收缩到内容，由调用方决定停靠位置和尾角朝向。 */
@Composable
private fun SpeechBubble(
    speech: String,
    moodLabel: String,
    shape: androidx.compose.ui.graphics.Shape,
) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
        shape = shape,
    ) {
        Text(
            text = speech,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 12.dp)
                .semantics { contentDescription = "$moodLabel。$speech" },
        )
    }
}

/** 域内表情 → 画猫的表情。1:1 对应，猫包不认识账单。 */
internal val DashboardCatMood.art: CatMood
    get() = when (this) {
        DashboardCatMood.Normal -> CatMood.Normal
        DashboardCatMood.Sleeping -> CatMood.Sleeping
        DashboardCatMood.Saved -> CatMood.Saved
        DashboardCatMood.Alert -> CatMood.Alert
        DashboardCatMood.Shocked -> CatMood.Shocked
        DashboardCatMood.Awkward -> CatMood.Awkward
        DashboardCatMood.Dead -> CatMood.Dead
    }

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardCatStagePreview() {
    TollCatTheme {
        DashboardCatStage(
            composition = DashboardPreviewData.snapshot.composition,
            comparison = ComparisonContent(
                percentText = "+62%",
                caption = "对比 7月同期 $29.10",
                spokenLabel = "+62%. 对比 7月同期 $29.10",
                currentWeight = 1f,
                previousWeight = 1f / 1.62f,
                currentLabel = "本月",
                previousLabel = "上月",
                tone = ComparisonContent.Tone.Up,
            ),
            trend = DashboardPreviewData.snapshot.trend,
            mood = DashboardCatMood.Shocked,
            speech = "合计较上月同期涨了 62%。",
            onOpenComposition = {},
        )
    }
}
