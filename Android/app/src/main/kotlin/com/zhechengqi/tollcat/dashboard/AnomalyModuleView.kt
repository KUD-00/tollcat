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
import com.zhechengqi.tollcat.AnomalyRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.LocalTollCatColors

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AnomalyModuleView(
    items: List<AnomalyRow>,
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
                text = stringResource(R.string.module_anomaly),
                style = MaterialTheme.typography.titleLargeEmphasized,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            )
            items.forEach { item ->
                DashboardInsightRow(
                    title = item.displayName,
                    glyphKey = item.providerId.takeIf { it.isNotBlank() },
                    subtitle = item.caption,
                    trailingText = item.signedPercent,
                    spokenLabel = "${item.displayName}，${item.signedPercent}，${item.caption}",
                    trailingColor = LocalTollCatColors.current.spendUp.main,
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
private fun AnomalyModuleViewPreview() {
    TollCatTheme {
        AnomalyModuleView(
            items = DashboardPreviewData.snapshot.anomalies,
            onOpenProvider = {},
        )
    }
}
