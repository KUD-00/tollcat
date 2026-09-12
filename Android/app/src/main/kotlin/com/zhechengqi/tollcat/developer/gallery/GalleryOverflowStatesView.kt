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
import com.zhechengqi.tollcat.services.ServiceRow
import com.zhechengqi.tollcat.services.ServiceRowUi

@Composable
fun GalleryOverflowStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(
        title = stringResource(R.string.dev_gallery_overflow),
        onBack = onBack,
        modifier = modifier,
    ) {
        Text(stringResource(R.string.dev_overflow_provider), style = MaterialTheme.typography.titleSmall)
        ServiceRow(
            row = ServiceRowUi(
                providerId = "cloudflare",
                displayName = "Cloudflare Workers Paid Plan Plus Extra Long Display Name",
                colorKey = "cloudflare",
                kind = "usage",
                category = "networkEdge",
                amountText = "$1,234,567.89",
                amountValue = 1_234_567.89,
                subtitle = stringResource(R.string.dev_overflow_sub),
                usesSecondaryValue = false,
            ),
            onClick = {},
        )
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.dev_overflow_sub_title), style = MaterialTheme.typography.titleSmall)
        DashboardInsightRow(
            title = "ChatGPT Team Annual Seats Super Long Subscription Name",
            subtitle = stringResource(R.string.dev_overflow_sub_line),
            trailingText = "$240.00",
            spokenLabel = stringResource(R.string.dev_overflow_sub_a11y),
        )
    }
}
