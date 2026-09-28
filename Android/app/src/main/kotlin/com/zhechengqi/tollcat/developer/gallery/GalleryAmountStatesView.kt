package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.DashboardHeroHeader
import com.zhechengqi.tollcat.dashboard.DashboardHeroPreview
import com.zhechengqi.tollcat.dashboard.DashboardSheet
import com.zhechengqi.tollcat.ui.PrimaryButton
import kotlinx.coroutines.delay

/**
 * 总数顶栏的各种状态。卡片形态（fullBleed = false）排在前面方便对照，
 * 最后一块是主页上真实的铺满形态 + 下面那张纸。
 */
@Composable
fun GalleryAmountStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var amountIndex by remember { mutableIntStateOf(0) }
    var autoCycles by remember { mutableStateOf(false) }
    var includesSubscriptions by remember { mutableStateOf(true) }
    val amounts = listOf("$9.99", "$47.20", "$1,234.56", "$1,234,567.89", "$0.00", "-$12.34")
    val projected = listOf("$20.00", "$87.70", "$2,400.00", "$2,000,000.00", "$0.00", "-$20.00")
    LaunchedEffect(autoCycles) {
        if (!autoCycles) return@LaunchedEffect
        while (true) {
            delay(2000)
            amountIndex = (amountIndex + 1) % amounts.size
        }
    }
    val base = DashboardHeroPreview.state
    GalleryScaffold(title = stringResource(R.string.dev_gallery_hero), onBack = onBack, modifier = modifier) {
        GalleryExhibit(title = "位数轮换（里程计滚动 + 字号随位数缩）") {
            DashboardHeroHeader(
                state = base.copy(
                    amount = amounts[amountIndex],
                    projected = projected[amountIndex],
                    includesSubscriptions = includesSubscriptions,
                ),
                fullBleed = false,
                onToggleSubscriptions = { includesSubscriptions = it },
            )
            PrimaryButton(
                onClick = { amountIndex = (amountIndex + 1) % amounts.size },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.dev_gallery_next_amount))
            }
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                Text("自动循环", style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                Switch(checked = autoCycles, onCheckedChange = { autoCycles = it })
            }
        }
        GalleryExhibit(title = "回看过去的月份：没有月底预计、没有进度条") {
            DashboardHeroHeader(
                state = base.copy(periodTitle = "7 月", amount = "$56.40", projected = null, monthProgress = null),
                fullBleed = false,
                onToggleSubscriptions = {},
            )
        }
        GalleryExhibit(title = "只看用量 + 订阅没算进去 + 1 家没更新 + 有筛选") {
            DashboardHeroHeader(
                state = base.copy(
                    amount = "$43.20",
                    projected = "$83.70",
                    includesSubscriptions = false,
                    subscriptionNote = "本月订阅 $24.00 · 未计入",
                    staleCaption = "部分数据陈旧，仍显示上次成功的数字",
                    filterNote = "排除 AWS",
                ),
                fullBleed = false,
                onToggleSubscriptions = {},
            )
        }
        GalleryExhibit(title = "没有订阅：没有口径切换，只剩数字和进度") {
            DashboardHeroHeader(
                state = base.copy(showsScopeToggle = false, subscriptionNote = null),
                fullBleed = false,
            )
        }
        GalleryExhibit(title = "主页形态：铺满顶部，内容纸从下面盖上来") {
            DashboardHeroHeader(
                state = base,
                onFilter = {},
                onShare = {},
                onToggleSubscriptions = {},
            )
            DashboardSheet {
                Spacer(Modifier.height(96.dp))
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryAmountStatesViewPreview() {
    TollCatTheme {
        GalleryAmountStatesView(onBack = {})
    }
}
