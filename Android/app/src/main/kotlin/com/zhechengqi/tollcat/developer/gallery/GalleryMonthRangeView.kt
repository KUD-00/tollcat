package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.zhechengqi.tollcat.dashboard.DashboardFilterSheet
import com.zhechengqi.tollcat.dashboard.DashboardFilterState

@Composable
fun GalleryMonthRangeView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    DashboardFilterSheet(
        state = DashboardFilterState(),
        accounts = emptyList(),
        nowMillis = System.currentTimeMillis(),
        onApply = { onBack() },
        onDismiss = onBack,
    )
}