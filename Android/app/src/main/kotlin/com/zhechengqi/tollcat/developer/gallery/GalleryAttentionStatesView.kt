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
import com.zhechengqi.tollcat.dashboard.AnomalyModuleView
import com.zhechengqi.tollcat.developer.GalleryFixtures

@Composable
fun GalleryAttentionStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(
        title = stringResource(R.string.dashboard_attention),
        onBack = onBack,
        modifier = modifier,
    ) {
        Text(stringResource(R.string.dev_attn_zero), style = MaterialTheme.typography.titleSmall)
        Text(
            stringResource(R.string.dev_attn_zero_body),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.dev_attn_one), style = MaterialTheme.typography.titleSmall)
        AnomalyModuleView(
            items = GalleryFixtures.anomaly(listOf("aws" to "AWS")),
            onOpenProvider = {},
        )
        Spacer(Modifier.height(12.dp))
        Text(stringResource(R.string.dev_attn_four), style = MaterialTheme.typography.titleSmall)
        AnomalyModuleView(
            items = GalleryFixtures.anomaly(
                listOf(
                    "aws" to "AWS",
                    "openai" to "OpenAI",
                    "cloudflare" to "Cloudflare",
                    "neon" to "Neon",
                ),
            ),
            onOpenProvider = {},
        )
    }
}
