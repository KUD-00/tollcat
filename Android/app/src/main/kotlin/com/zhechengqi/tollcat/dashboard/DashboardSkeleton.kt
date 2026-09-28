package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.SkeletonBox

/**
 * 已有服务但首笔账单还没回来时的骨架：照着新版式占位（顶栏 → 纸 → 注意横幅与两张小卡 → 构成），
 * 数据到了由 fade-through 盖上去，布局不跳。
 */
@Composable
fun DashboardSkeleton(modifier: Modifier = Modifier) {
    val spoken = stringResource(R.string.dashboard_loading)
    Column(
        modifier = modifier
            .fillMaxSize()
            .semantics { contentDescription = spoken },
    ) {
        SkeletonBox(
            shape = RectangleShape,
            modifier = Modifier
                .fillMaxWidth()
                .height(272.dp),
        )
        Column(
            modifier = Modifier
                .pullUp(DashboardSheetOverlap)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = DashboardSheetOverlap, topEnd = DashboardSheetOverlap))
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 12.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            SkeletonBox(
                shape = RoundedCornerShape(28.dp, 28.dp, 8.dp, 8.dp),
                modifier = Modifier.fillMaxWidth().height(84.dp),
                delayMillis = 120,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                SkeletonBox(
                    shape = RoundedCornerShape(8.dp, 8.dp, 8.dp, 28.dp),
                    modifier = Modifier.width(164.dp).height(150.dp),
                    delayMillis = 200,
                )
                SkeletonBox(
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier.width(164.dp).height(150.dp),
                    delayMillis = 240,
                )
            }
            SkeletonBox(
                shape = RoundedCornerShape(28.dp),
                modifier = Modifier.fillMaxWidth().height(260.dp),
                delayMillis = 300,
            )
        }
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
