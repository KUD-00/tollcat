package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.AttentionItem
import com.zhechengqi.tollcat.dashboard.AttentionSummary
import com.zhechengqi.tollcat.dashboard.AttentionCarousel
import com.zhechengqi.tollcat.dashboard.DashboardAttentionSection

/** 「需要注意」：最急一件的横幅 + 横滑大数字小卡的各种组合，外加轮播备选版式。 */
@Composable
fun GalleryAttentionStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val aws = AttentionItem.Anomaly(AnomalyRow("aws", "AWS", "+62%", "对比 7 月同期 $13.20", 0.62))
    val openAiLow = AttentionItem.Balance(BalanceAlertRow("openai", "OpenAI", "$42.00", 18, "余额 $42.00"))
    val openAiCritical = AttentionItem.Balance(BalanceAlertRow("openai", "OpenAI", "$6.00", 3, "余额 $6.00"))
    val vercel = AttentionItem.Quota(FreeQuotaRow("vercel", "Vercel", "vercel", 84, "用了 84%"))
    val vercelFull = AttentionItem.Quota(FreeQuotaRow("vercel", "Vercel", "vercel", 96, "用了 96%"))
    GalleryScaffold(
        title = stringResource(R.string.dashboard_attention),
        onBack = onBack,
        modifier = modifier,
    ) {
        GalleryExhibit(title = "主页：AWS 涨了 → 横幅；余额和额度 → 小卡") {
            DashboardAttentionSection(AttentionSummary(urgent = aws, others = listOf(openAiLow, vercel)), onOpen = {})
        }
        GalleryExhibit(title = "只有一件急事：横幅四角都是大圆角") {
            DashboardAttentionSection(AttentionSummary(urgent = openAiCritical, others = emptyList()), onOpen = {})
        }
        GalleryExhibit(title = "额度用到九成也算急事") {
            DashboardAttentionSection(AttentionSummary(urgent = vercelFull, others = listOf(openAiLow)), onOpen = {})
        }
        GalleryExhibit(title = "没有急事：只有小卡，标题带件数") {
            DashboardAttentionSection(AttentionSummary(urgent = null, others = listOf(openAiLow, vercel)), onOpen = {})
        }
        GalleryExhibit(title = "备选：一条轮播，第一张最宽（画布 R2-2）") {
            AttentionCarousel(AttentionSummary(urgent = aws, others = listOf(openAiLow, vercel)), onOpen = {})
        }
        GalleryExhibit(title = stringResource(R.string.dev_attn_zero)) {
            Text(
                stringResource(R.string.dev_attn_zero_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryAttentionStatesViewPreview() {
    TollCatTheme {
        GalleryAttentionStatesView(onBack = {})
    }
}
