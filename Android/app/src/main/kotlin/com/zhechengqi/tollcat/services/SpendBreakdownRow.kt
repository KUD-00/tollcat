package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.CompositionTones

private val Swatch = 8.dp

@Composable
fun SpendBreakdownRow(
    group: SpendBreakdownGroup,
    index: Int,
    modifier: Modifier = Modifier,
    compact: Boolean = false,
) {
    val color = CompositionTones.color(index, isOther = group.id == "__other__")
    val caption = if (compact) {
        null
    } else {
        listOfNotNull(group.detailCaption, group.allowanceCaption)
            .joinToString(" · ")
            .ifBlank { null }
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = group.spokenLabel }
            .padding(horizontal = 16.dp, vertical = if (compact) 10.dp else 12.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            Modifier
                .padding(top = 6.dp)
                .size(Swatch)
                .clip(CircleShape)
                .background(color),
        )
        Column(Modifier.weight(1f)) {
            Text(
                text = group.title,
                style = if (compact) {
                    MaterialTheme.typography.bodyLarge
                } else {
                    MaterialTheme.typography.titleMedium
                },
                maxLines = if (compact) 1 else 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (caption != null) {
                Text(
                    text = caption,
                    style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = group.amountCaption,
                style = if (compact) {
                    MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum")
                } else {
                    MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum")
                },
                maxLines = 1,
            )
            if (!compact) {
                group.shareCaption?.let { share ->
                    Text(
                        text = share,
                        style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

@Composable
fun SpendBreakdownItemRow(
    item: SpendBreakdownItem,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = item.spokenLabel }
            .padding(start = 32.dp, end = 16.dp, top = 8.dp, bottom = 8.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                text = item.title,
                style = MaterialTheme.typography.bodyLarge,
            )
            item.detailCaption?.let { detail ->
                Text(
                    text = detail,
                    style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = item.amountCaption,
                style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
            )
            item.listCaption?.let { list ->
                Text(
                    text = list,
                    style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textDecoration = TextDecoration.LineThrough,
                    maxLines = 1,
                )
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SpendBreakdownRowPreview() {
    TollCatTheme {
        Column(Modifier.background(Color.Transparent)) {
            SpendBreakdownRow(
                group = SpendBreakdownGroup(
                    id = "actions",
                    title = "actions",
                    amountCaption = "$4.00",
                    fraction = 0.57,
                    shareCaption = "57%",
                    detailCaption = "1,667 Minutes",
                    allowanceCaption = null,
                    isZeroBilled = false,
                    items = emptyList(),
                    spokenLabel = "actions，$4.00",
                ),
                index = 0,
            )
            SpendBreakdownItemRow(
                item = SpendBreakdownItem(
                    id = "a",
                    title = "Actions Linux · RelayOS",
                    amountCaption = "$3.00",
                    detailCaption = "1,667 Minutes",
                    listCaption = "原价 $4.12",
                    spokenLabel = "Actions Linux，$3.00",
                ),
            )
        }
    }
}
