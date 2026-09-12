package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.sharedProviderContainer
import com.zhechengqi.tollcat.ui.sharedProviderElement

@Composable
fun ServiceRow(
    row: ServiceRowUi,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    hint: String? = null,
    shape: Shape = RectangleShape,
) {
    val staleLabel = if (row.isStale) stringResource(R.string.services_stale) else null
    val spoken = buildString {
        append(row.displayName)
        append("，")
        append(row.amountText)
        if (staleLabel != null) {
            append("，")
            append(staleLabel)
        }
        if (row.subtitle.isNotBlank()) {
            append("，")
            append(row.subtitle)
        }
        if (hint != null) {
            append("。")
            append(hint)
        }
    }
    ListItem(
        onClick = onClick,
        modifier = modifier
            .sharedProviderContainer(row.providerId, shape)
            .clip(shape)
            .semantics { contentDescription = spoken },
        colors = ListItemDefaults.colors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer,
        ),
        leadingContent = {
            ServiceGlyph(
                name = row.displayName,
                colorKey = row.colorKey,
                modifier = Modifier.sharedProviderElement(row.providerId),
            )
        },
        trailingContent = {
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = row.amountText,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontFeatureSettings = "tnum",
                        fontWeight = FontWeight.Medium,
                        color = if (row.usesSecondaryValue) {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        } else {
                            MaterialTheme.colorScheme.onSurface
                        },
                    ),
                )
                if (staleLabel != null) {
                    Text(
                        text = staleLabel,
                        style = MaterialTheme.typography.labelSmall,
                        color = staleOrange(),
                    )
                }
            }
        },
        supportingContent = if (row.subtitle.isNotBlank()) {
            { Text(row.subtitle) }
        } else {
            null
        },
        content = { Text(row.displayName) },
    )
}

/** iOS `MeterColor.warn` = 系统橙。深浅各一档，压在 surfaceContainer 上要能读。 */
@Composable
private fun staleOrange(): Color {
    val dark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    return if (dark) Color(0xFFFFB74D) else Color(0xFFEF6C00)
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ServiceRowPreview() {
    TollCatTheme {
        ServiceRow(
            row = ServiceRowUi(
                providerId = "cloudflare",
                displayName = "Cloudflare",
                colorKey = "cloudflare",
                kind = "usage",
                category = "networkEdge",
                amountText = "$11.05",
                amountValue = 11.05,
                subtitle = "用量后付费",
                usesSecondaryValue = false,
            ),
            onClick = {},
            shape = Bento.solo,
        )
    }
}

@Preview(name = "Stale Light", showBackground = true)
@Preview(name = "Stale Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ServiceRowStalePreview() {
    TollCatTheme {
        ServiceRow(
            row = ServiceRowUi(
                providerId = "aws",
                displayName = "AWS",
                colorKey = "aws",
                kind = "usage",
                category = "hosting",
                amountText = "$21.40",
                amountValue = 21.40,
                subtitle = "3 小时前",
                usesSecondaryValue = false,
                isStale = true,
                lastSuccessMillis = 1_725_000_000_000,
            ),
            onClick = {},
            shape = Bento.solo,
        )
    }
}
