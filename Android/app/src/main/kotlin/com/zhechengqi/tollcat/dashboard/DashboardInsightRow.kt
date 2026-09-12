package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.ProviderGlyph
import com.zhechengqi.tollcat.TollCatTheme

@Composable
fun DashboardInsightRow(
    title: String,
    subtitle: String,
    trailingText: String,
    spokenLabel: String,
    modifier: Modifier = Modifier,
    trailingColor: Color = MaterialTheme.colorScheme.onSurfaceVariant,
    glyphKey: String? = null,
    onClick: (() -> Unit)? = null,
) {
    val rowModifier = if (onClick != null) {
        modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .semantics { contentDescription = spokenLabel }
    } else {
        modifier
            .fillMaxWidth()
            .semantics { contentDescription = spokenLabel }
    }
    ListItem(
        headlineContent = { Text(title, style = MaterialTheme.typography.titleMedium) },
        supportingContent = {
            Text(
                subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
        leadingContent = { ProviderGlyph(title, colorKey = glyphKey) },
        trailingContent = {
            Text(
                trailingText,
                style = MaterialTheme.typography.titleMedium.copy(
                    fontWeight = FontWeight.Medium,
                    fontFeatureSettings = "tnum",
                ),
                color = trailingColor,
            )
        },
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
        modifier = rowModifier,
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardInsightRowPreview() {
    TollCatTheme {
        DashboardInsightRow(
            title = "AWS",
            subtitle = "对比 7 月同期 $13.20",
            trailingText = "+62%",
            spokenLabel = "AWS +62%",
            trailingColor = MaterialTheme.colorScheme.error,
        )
    }
}
