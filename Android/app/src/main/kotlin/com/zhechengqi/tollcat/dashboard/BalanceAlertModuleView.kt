package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.BalanceAlertRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun BalanceAlertModuleView(
    items: List<BalanceAlertRow>,
    onOpenProvider: (String) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (items.isEmpty()) return
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(vertical = 8.dp)) {
            Text(
                text = stringResource(R.string.module_balance),
                style = MaterialTheme.typography.titleLargeEmphasized,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            )
            items.forEach { item ->
                val subtitle = item.caption.ifBlank {
                    stringResource(R.string.dashboard_balance_caption, item.balance)
                }
                DashboardInsightRow(
                    title = item.displayName,
                    glyphKey = item.providerId.takeIf { it.isNotBlank() },
                    subtitle = subtitle,
                    trailingText = stringResource(R.string.dashboard_days_remaining, item.daysRemaining),
                    spokenLabel = "${item.displayName}，$subtitle",
                    onClick = dashboardAttentionTarget(item.accountId, item.providerId)?.let { id ->
                        { onOpenProvider(id) }
                    },
                )
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun BalanceAlertModuleViewPreview() {
    TollCatTheme {
        BalanceAlertModuleView(
            items = DashboardPreviewData.snapshot.balanceAlerts,
            onOpenProvider = {},
        )
    }
}
