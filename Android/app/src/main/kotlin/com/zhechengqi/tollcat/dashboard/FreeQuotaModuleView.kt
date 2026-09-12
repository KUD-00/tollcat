package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LinearWavyProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.FreeQuotaRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun FreeQuotaModuleView(
    items: List<FreeQuotaRow>,
    onOpenProvider: (String) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (items.isEmpty()) return
    val kind = stringResource(R.string.dashboard_quota_kind)
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(vertical = 8.dp)) {
            Text(
                text = stringResource(R.string.module_quota),
                style = MaterialTheme.typography.titleLargeEmphasized,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            )
            items.forEach { item ->
                Column(
                    modifier = Modifier.padding(bottom = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    DashboardInsightRow(
                        title = item.displayName,
                        glyphKey = item.providerId.takeIf { it.isNotBlank() },
                        subtitle = kind,
                        trailingText = "${item.usedPercent}%",
                        spokenLabel = "${item.displayName}，$kind，${item.caption}",
                        onClick = dashboardAttentionTarget(item.accountId, item.providerId)?.let { id ->
                            { onOpenProvider(id) }
                        },
                    )
                    LinearWavyProgressIndicator(
                        progress = { (item.usedPercent / 100f).coerceIn(0f, 1f) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 8.dp),
                    )
                }
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun FreeQuotaModuleViewPreview() {
    TollCatTheme {
        FreeQuotaModuleView(
            items = DashboardPreviewData.snapshot.freeQuota,
            onOpenProvider = {},
        )
    }
}
