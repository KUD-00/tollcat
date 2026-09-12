package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.dashboard.DashboardInsightRow

@Composable
fun GalleryRowStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(title = stringResource(R.string.dev_gallery_rows), onBack = onBack, modifier = modifier) {
        Text(stringResource(R.string.dev_row_percent), style = MaterialTheme.typography.titleSmall)
        DashboardInsightRow(
            title = "AWS",
            subtitle = stringResource(R.string.dev_row_percent_sub),
            trailingText = "+62%",
            spokenLabel = "AWS +62%",
            trailingColor = MaterialTheme.colorScheme.error,
        )
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.dev_row_days), style = MaterialTheme.typography.titleSmall)
        DashboardInsightRow(
            title = "OpenAI",
            subtitle = stringResource(R.string.dashboard_balance_caption, "$42.00"),
            trailingText = stringResource(R.string.dashboard_days_remaining, 18),
            spokenLabel = "OpenAI 18",
        )
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.dev_row_amount), style = MaterialTheme.typography.titleSmall)
        DashboardInsightRow(
            title = "ChatGPT Plus",
            subtitle = "8 月 20 日",
            trailingText = "$20.00",
            spokenLabel = "ChatGPT Plus $20",
        )
    }
}
