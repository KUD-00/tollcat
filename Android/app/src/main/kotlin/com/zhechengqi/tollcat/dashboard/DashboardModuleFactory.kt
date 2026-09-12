package com.zhechengqi.tollcat.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.UpcomingRow
import com.zhechengqi.tollcat.ui.Bento

internal fun dashboardAttentionTarget(accountId: String, providerId: String): String? {
    return accountId.ifBlank { providerId }.takeIf { it.isNotBlank() }
}

internal fun dashboardOpenAction(
    accountId: String,
    providerId: String,
    onOpen: (String) -> Unit,
): (() -> Unit)? {
    val target = dashboardAttentionTarget(accountId, providerId) ?: return null
    return { onOpen(target) }
}

object DashboardModuleFactory {
    @OptIn(ExperimentalMaterial3ExpressiveApi::class)
    @Composable
    fun Attention(
        dashboard: DashboardSnapshot,
        onOpenProvider: (String) -> Unit,
        modifier: Modifier = Modifier,
        ids: List<String>? = null,
    ) {
        // 取景框在共享层生效：回看过去月份时这四组在 JNI 里就已是空。
        val anomalies = dashboard.anomalies
        val alerts = dashboard.balanceAlerts
        val upcoming = dashboard.upcoming
        val quota = dashboard.freeQuota
        val allowed = ids?.toSet()
        fun shows(id: String) = allowed == null || id in allowed
        // 非空模块结成自己的一组 bento：首件顶外沿、末件底外沿、组内 10dp 缝角。
        val sections = buildList<@Composable (Shape) -> Unit> {
            if (shows(DashboardModules.ANOMALY) && anomalies.isNotEmpty()) {
                add { shape -> AnomalyModuleView(items = anomalies, onOpenProvider = onOpenProvider, shape = shape) }
            }
            if (shows(DashboardModules.BALANCE) && alerts.isNotEmpty()) {
                add { shape -> BalanceAlertModuleView(items = alerts, onOpenProvider = onOpenProvider, shape = shape) }
            }
            if (shows(DashboardModules.UPCOMING) && upcoming.isNotEmpty()) {
                add { shape -> UpcomingChargesModuleView(items = upcoming, onOpenProvider = onOpenProvider, shape = shape) }
            }
            if (shows(DashboardModules.QUOTA) && quota.isNotEmpty()) {
                add { shape -> FreeQuotaModuleView(items = quota, onOpenProvider = onOpenProvider, shape = shape) }
            }
        }
        if (sections.isEmpty()) return
        Column(
            modifier = modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(Bento.gap),
        ) {
            Text(
                text = stringResource(R.string.dashboard_attention),
                style = MaterialTheme.typography.titleMediumEmphasized,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 17.dp, bottom = 9.dp, start = 4.dp),
            )
            sections.forEachIndexed { index, section ->
                section(Bento.groupShape(first = index == 0, last = index == sections.lastIndex))
            }
        }
    }

    @Composable
    fun view(
        id: DashboardModuleID,
        anomalies: List<AnomalyRow>,
        alerts: List<BalanceAlertRow>,
        upcoming: List<UpcomingRow>,
        quota: List<FreeQuotaRow>,
        onOpenProvider: (String) -> Unit,
    ) {
        when (id) {
            DashboardModuleID.Anomaly -> AnomalyModuleView(items = anomalies, onOpenProvider = onOpenProvider)
            DashboardModuleID.BalanceAlert -> BalanceAlertModuleView(items = alerts, onOpenProvider = onOpenProvider)
            DashboardModuleID.UpcomingCharges -> UpcomingChargesModuleView(items = upcoming, onOpenProvider = onOpenProvider)
            DashboardModuleID.FreeQuota -> FreeQuotaModuleView(items = quota, onOpenProvider = onOpenProvider)
            DashboardModuleID.MonthToDate,
            DashboardModuleID.Composition,
            DashboardModuleID.MonthlyHighlights,
            -> Unit
        }
    }
}
