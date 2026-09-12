package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.AccountExtras
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SubscriptionRow
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 不再花钱、但过去花过的那些。
 *
 * 单开一页而不是在服务列表底下挂一节：主列表回答的是「我现在每个月付多少」，
 * 已经停掉的东西留在那儿只是噪音。它们又必须留着——过去几个月的账里有它们，
 * 删掉才是真的把那段历史抹了。
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun PastServicesScreen(session: TollCatSession, modifier: Modifier = Modifier) {
    session.dataRevision
    val context = LocalContext.current
    val locale = context.resources.configuration.locales[0]
    val endedProviders = session.archivedMemberships().mapNotNull { membership ->
        val provider = session.catalog.provider(membership.providerId) ?: return@mapNotNull null
        val endedAt = session.accounts(membership.providerId)
            .mapNotNull { AccountExtras.archivedAtMillis(it) }
            .maxOrNull()
        endedProviderRow(
            provider = provider,
            endedAtMillis = endedAt,
            ended = context.getString(R.string.services_ended),
            endedMonth = { context.getString(R.string.services_ended_provider, it) },
            yearMonth = { ServiceRelativeTime.yearMonth(it, locale) },
        )
    }
    val ended = session.unaffiliatedSubscriptions().filter { session.hasEnded(it) }
    var editing by remember { mutableStateOf<SubscriptionRow?>(null) }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.services_past_title)) },
                navigationIcon = {
                    IconButton(
                        onClick = { session.popServices() },
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(
                            MaterialSymbol.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                },
            )
        },
    ) { inner ->
        PastServicesList(
            endedProviders = endedProviders,
            endedSubscriptions = ended,
            onOpenProvider = { session.openDetail(it) },
            onEditSubscription = { editing = it },
            modifier = Modifier
                .padding(inner)
                .fillMaxSize(),
        )
    }

    editing?.let { item ->
        ProviderSubscriptionSheet(
            providerId = item.providerId,
            accountId = item.accountId,
            editing = item,
            onDismiss = { editing = null },
            onSave = { row ->
                session.saveSubscription(row)
                editing = null
            },
            onDelete = { id ->
                session.deleteSubscription(id)
                editing = null
            },
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun PastServicesList(
    endedProviders: List<ServiceRowUi>,
    endedSubscriptions: List<SubscriptionRow>,
    onOpenProvider: (String) -> Unit,
    onEditSubscription: (SubscriptionRow) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        if (endedProviders.isNotEmpty()) {
            item {
                Text(
                    text = stringResource(R.string.services_past_title),
                    style = MaterialTheme.typography.titleMediumEmphasized,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 4.dp, bottom = 5.dp),
                )
            }
            itemsIndexed(endedProviders, key = { _, row -> "ended-${row.id}" }) { index, row ->
                ServiceRow(
                    row = row,
                    onClick = { onOpenProvider(row.providerId) },
                    hint = stringResource(R.string.services_hint_detail),
                    shape = Bento.groupShape(
                        first = index == 0,
                        last = index == endedProviders.lastIndex,
                    ),
                )
            }
        }
        if (endedSubscriptions.isNotEmpty()) {
            item {
                Text(
                    text = stringResource(R.string.services_past_subscriptions),
                    style = MaterialTheme.typography.titleMediumEmphasized,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(
                        start = 4.dp,
                        top = if (endedProviders.isEmpty()) 0.dp else 13.dp,
                        bottom = 5.dp,
                    ),
                )
            }
            itemsIndexed(endedSubscriptions, key = { _, item -> "sub-${item.id}" }) { index, item ->
                ListItem(
                    onClick = { onEditSubscription(item) },
                    modifier = Modifier.clip(
                        Bento.groupShape(first = index == 0, last = index == endedSubscriptions.lastIndex),
                    ),
                    colors = ListItemDefaults.colors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    ),
                    supportingContent = { Text(subscriptionCaption(item, hasEnded = true)) },
                    trailingContent = {
                        Text(
                            formatMoney(item.amountUsd),
                            style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    },
                    content = {
                        Text(item.name, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    },
                )
            }
        }
        item {
            Text(
                text = stringResource(R.string.services_end_footer_set),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 4.dp, top = 12.dp, bottom = 8.dp),
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun PastServicesPreview() {
    TollCatTheme {
        PastServicesList(
            endedProviders = listOf(
                ServiceRowUi(
                    providerId = "openai",
                    displayName = "OpenAI",
                    colorKey = "openai",
                    kind = "prepaid",
                    category = "aiInference",
                    amountText = "—",
                    amountValue = 0.0,
                    subtitle = "已结束 · 2026年6月",
                    usesSecondaryValue = true,
                    isEnded = true,
                ),
            ),
            endedSubscriptions = listOf(
                SubscriptionRow(
                    id = "sub-1",
                    name = "ChatGPT Plus",
                    amountUsd = "20",
                    period = "monthly",
                    anchorYear = 2026,
                    anchorMonth = 1,
                    anchorDay = 1,
                    endYear = 2026,
                    endMonth = 6,
                    endDay = 1,
                ),
            ),
            onOpenProvider = {},
            onEditSubscription = {},
        )
    }
}
