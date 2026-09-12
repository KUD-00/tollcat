package com.zhechengqi.tollcat.dashboard

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.R

@Composable
fun dashboardFilterNote(
    filter: DashboardFilterState,
    accounts: List<DashboardFilterAccount>,
): String? {
    if (!filter.isActive) return null
    val parts = mutableListOf<String>()
    val names = accounts
        .filter { it.accountId in filter.excludedAccountIds }
        .map { it.displayName }
        .distinct()
    if (names.isNotEmpty()) {
        parts += stringResource(R.string.dashboard_filter_excluding, names.joinToString("、"))
    }
    return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
}
