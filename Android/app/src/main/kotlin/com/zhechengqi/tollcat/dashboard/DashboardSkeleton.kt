package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.SkeletonBox

/**
 * 已有服务但首笔账单还没回来时的仪表盘骨架：按 bento 版式占位
 * （hero → 瓷砖行 → 构成卡），稳住布局不让内容 pop in。
 */
@Composable
fun DashboardSkeleton(modifier: Modifier = Modifier) {
    val spoken = stringResource(R.string.dashboard_loading)
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .semantics { contentDescription = spoken },
        verticalArrangement = Arrangement.spacedBy(Bento.gap),
    ) {
        SkeletonBox(
            shape = Bento.top,
            modifier = Modifier
                .fillMaxWidth()
                .height(208.dp),
        )
        Row(horizontalArrangement = Arrangement.spacedBy(Bento.gap)) {
            SkeletonBox(
                shape = Bento.middle,
                modifier = Modifier
                    .weight(1.7f)
                    .height(148.dp),
                delayMillis = 120,
            )
            SkeletonBox(
                shape = Bento.middle,
                modifier = Modifier
                    .weight(1f)
                    .height(148.dp),
                delayMillis = 200,
            )
        }
        SkeletonBox(
            shape = Bento.bottom,
            modifier = Modifier
                .fillMaxWidth()
                .height(168.dp),
            delayMillis = 280,
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardSkeletonPreview() {
    TollCatTheme {
        DashboardSkeleton()
    }
}
