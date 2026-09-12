package com.zhechengqi.tollcat.setup

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CatalogField
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.services.kindTitleRes
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.BentoGroup
import com.zhechengqi.tollcat.ui.LocalTollCatColors
import com.zhechengqi.tollcat.ui.bentoRowColors

@Composable
fun SetupUsageFactsSection(
    provider: CatalogProvider,
    fields: List<CatalogField>,
    modifier: Modifier = Modifier,
) {
    val level = SetupProviderFacts.supportLevel(provider)
    val tint = supportTint(level)
    val valueStyle = MaterialTheme.typography.bodyLarge
    val valueColor = MaterialTheme.colorScheme.onSurfaceVariant
    BentoGroup(modifier = modifier.fillMaxWidth()) {
        ListItem(
            trailingContent = {
                Text(
                    text = stringResource(kindTitleRes(provider.kind)),
                    style = valueStyle,
                    color = valueColor,
                )
            },
            modifier = Modifier.clip(Bento.middle),
            colors = bentoRowColors(),
        ) {
            Text(stringResource(R.string.services_setup_billing_kind))
        }
        val captionRes = SetupProviderFacts.supportCaptionRes(level)
        if (captionRes == null) {
            ListItem(
                trailingContent = {
                    SupportValue(filled = SetupProviderFacts.supportBars(level), tint = tint, title = stringResource(SetupProviderFacts.supportTitleRes(level)), style = valueStyle, color = valueColor)
                },
                modifier = Modifier.clip(Bento.middle),
                colors = bentoRowColors(),
            ) {
                Text(stringResource(R.string.setup_support_status))
            }
        } else {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = Bento.middle,
                color = MaterialTheme.colorScheme.surfaceContainer,
            ) {
                Column(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(stringResource(R.string.setup_support_status), style = MaterialTheme.typography.bodyLarge)
                        SupportValue(
                            filled = SetupProviderFacts.supportBars(level),
                            tint = tint,
                            title = stringResource(SetupProviderFacts.supportTitleRes(level)),
                            style = valueStyle,
                            color = valueColor,
                        )
                    }
                    Text(
                        text = stringResource(captionRes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
        if (fields.isNotEmpty()) {
            ListItem(
                trailingContent = {
                    Column(horizontalAlignment = Alignment.End) {
                        fields.forEach { field ->
                            Text(
                                text = field.label,
                                style = valueStyle,
                                color = valueColor,
                                textAlign = TextAlign.End,
                            )
                        }
                    }
                },
                modifier = Modifier.clip(Bento.middle),
                colors = bentoRowColors(),
            ) {
                Text(stringResource(R.string.services_setup_fields_header))
            }
        }
    }
}

@Composable
private fun SupportValue(
    filled: Int,
    tint: Color,
    title: String,
    style: TextStyle,
    color: Color,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        SupportSignalBars(filled = filled, tint = tint)
        Text(text = title, style = style, color = color)
    }
}

@Composable
private fun supportTint(level: SetupProviderFacts.SupportLevel): Color {
    val colors = LocalTollCatColors.current
    return when (level) {
        SetupProviderFacts.SupportLevel.Full -> colors.spendDown.main
        SetupProviderFacts.SupportLevel.Theoretical -> colors.spendUp.main
        SetupProviderFacts.SupportLevel.Inbox -> MaterialTheme.colorScheme.primary
        SetupProviderFacts.SupportLevel.Unavailable -> MaterialTheme.colorScheme.outline
    }
}

@Composable
private fun SupportSignalBars(filled: Int, tint: Color) {
    val heights = listOf(5.dp, 9.dp, 13.dp)
    val empty = MaterialTheme.colorScheme.outline.copy(alpha = 0.28f)
    Row(
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        heights.forEachIndexed { index, height ->
            Box(
                Modifier
                    .width(3.dp)
                    .height(height)
                    .clip(RoundedCornerShape(0.6.dp))
                    .background(if (index < filled) tint else empty),
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SetupUsageFactsSectionPreview() {
    TollCatTheme {
        SetupUsageFactsSection(
            provider = previewCatalogProvider(),
            fields = listOf(
                CatalogField("apiToken", "API Token", isSecret = true),
                CatalogField("accountID", "Account ID"),
            ),
            modifier = Modifier.padding(16.dp),
        )
    }
}

internal fun previewCatalogProvider(
    id: String = "cloudflare",
    displayName: String = "Cloudflare",
    kind: String = "usage",
    category: String = "networkEdge",
    colorKey: String = id,
    accessStatus: String = "available",
    declineReason: String = "",
    supportsInbox: Boolean = false,
    hasLiveFetch: Boolean = true,
    credentialSetupURL: String = "https://dash.cloudflare.com/profile/api-tokens",
    fields: List<CatalogField> = emptyList(),
) = CatalogProvider(
    id = id,
    displayName = displayName,
    kind = kind,
    category = category,
    tier = 1,
    tierReason = "",
    colorKey = colorKey,
    costsMoneyToRefresh = false,
    supportsInbox = supportsInbox,
    hasLiveFetch = hasLiveFetch,
    summary = "",
    searchKeywords = emptyList(),
    accessStatus = accessStatus,
    declineReason = declineReason,
    supportsDailyGranularity = true,
    historyLookbackMonths = 12,
    billingURL = "",
    credentialSetupURL = credentialSetupURL,
    fields = fields,
)
