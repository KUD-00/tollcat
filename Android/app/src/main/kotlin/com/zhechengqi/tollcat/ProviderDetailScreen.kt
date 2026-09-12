package com.zhechengqi.tollcat

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MediumFlexibleTopAppBar
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import android.content.res.Configuration
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.services.ConvertedNote
import com.zhechengqi.tollcat.services.CredentialManagementSheet
import com.zhechengqi.tollcat.services.HistoryRange
import com.zhechengqi.tollcat.services.ManualUsageEntrySheet
import com.zhechengqi.tollcat.services.ProviderHistory
import com.zhechengqi.tollcat.services.ProviderSubscriptionSheet
import com.zhechengqi.tollcat.services.ServiceRelativeTime
import com.zhechengqi.tollcat.services.SpendBreakdownPreviewSection
import com.zhechengqi.tollcat.services.SpendBreakdownScreen
import com.zhechengqi.tollcat.services.SpendBreakdownGrouping
import com.zhechengqi.tollcat.services.SpendLines
import com.zhechengqi.tollcat.services.amountCompositionCaption
import com.zhechengqi.tollcat.services.composedAmountText
import com.zhechengqi.tollcat.services.compositionForAccounts
import com.zhechengqi.tollcat.services.conversionRateCaptions
import com.zhechengqi.tollcat.services.rememberSpendBreakdown
import com.zhechengqi.tollcat.services.subscriptionCaption
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.services.formatMoney
import com.zhechengqi.tollcat.services.kindTitleRes
import com.zhechengqi.tollcat.services.walletBreakdown
import com.zhechengqi.tollcat.ui.AmountText
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.BentoGroup
import com.zhechengqi.tollcat.ui.HierarchicalContent
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.bentoRowColors
import com.zhechengqi.tollcat.ui.sharedProviderContainer
import com.zhechengqi.tollcat.ui.sharedProviderElement
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ProviderDetailScreen(
    session: TollCatSession,
    providerId: String,
    modifier: Modifier = Modifier,
) {
    session.dataRevision
    session.dashboard
    val context = LocalContext.current
    val locale = context.resources.configuration.locales[0]
    val provider = session.catalog.provider(providerId)
    val name = provider?.displayName ?: providerId
    val colorKey = provider?.colorKey?.ifBlank { null } ?: providerId
    val live = session.liveAccounts(providerId)
    val archived = session.accounts(providerId).filter { AccountExtras.isArchived(it) }
    val snapshots = session.snapshotsFor(providerId)
    val snapshot = live
        .mapNotNull { account -> snapshots.filter { it.accountId == account.accountId }.maxByOrNull { it.fetchedAtMillis } }
        .maxByOrNull { it.fetchedAtMillis }
        ?: session.latestSnapshot(providerId)
    val connected = live.filter { account ->
        session.hasCredentials(account) ||
            snapshotsForAccount(snapshots, account.accountId) ||
            AccountExtras.usesInbox(account)
    }
    val allSubscriptions = session.subscriptionsFor(providerId)
    // 退掉的挪进「历史订阅」——和还在付的混在一起列，「这个月要付多少」就成了一道加法题。
    val subscriptions = allSubscriptions.filter { !session.hasEnded(it) }
    val endedSubscriptions = allSubscriptions.filter { session.hasEnded(it) }
    val scoped = remember(session.dashboard, session.displayCurrency, session.clockOverrideMillis) {
        session.serviceScopedDashboard()
    }
    val liveIds = live.map { it.accountId }.toSet()
    val compositionRows = compositionForAccounts(scoped.composition, liveIds)
    val quota = scoped.freeQuota.filter { it.accountId in liveIds }.maxByOrNull { it.usedPercent }
    val hasLive = provider?.hasLiveFetch == true
    val inbox = provider?.supportsInbox == true
    val kind = snapshot?.kind?.ifBlank { null } ?: provider?.kind.orEmpty()
    val isEnded = live.isEmpty() &&
        subscriptions.isEmpty() &&
        (archived.isNotEmpty() || endedSubscriptions.isNotEmpty())
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    var confirmingDelete by rememberSaveable { mutableStateOf(false) }
    var confirmingEnd by rememberSaveable { mutableStateOf(false) }
    var addingSubscription by rememberSaveable { mutableStateOf(false) }
    var editingSubscription by remember { mutableStateOf<SubscriptionRow?>(null) }
    var showingUsageEntry by rememberSaveable { mutableStateOf(false) }
    var showingCredentials by rememberSaveable { mutableStateOf(false) }
    var historyRange by rememberSaveable { mutableStateOf(HistoryRange.Days30) }
    var showingBreakdown by rememberSaveable { mutableStateOf(false) }
    val spendLinesJson = remember(snapshots) { SpendLines.latestJson(snapshots) }
    val breakdown = rememberSpendBreakdown(spendLinesJson, SpendBreakdownGrouping.Category)
    val connectedIds = remember(connected) { connected.map { it.accountId } }
    var includeInGlobalRefresh by remember(connectedIds) {
        mutableStateOf(
            connectedIds.isNotEmpty() &&
                connectedIds.all { session.preferences.includeInGlobalRefresh(it) },
        )
    }

    val amountText = when {
        isEnded -> "—"
        quota != null && kind == "freeTier" -> stringResource(R.string.services_free_quota)
        else -> composedAmountText(compositionRows)
            ?: snapshot?.currentSpendUsd?.let { formatMoney(it) }
            ?: snapshot?.committedMonthlyUsd?.let { formatMoney(it) }
    }
    val compositionCaption = if (isEnded || kind == "freeTier") {
        null
    } else {
        amountCompositionCaption(
            snapshot = snapshot,
            composition = compositionRows,
            subscriptions = scoped.subscriptions?.items.orEmpty().filter {
                it.providerId == providerId && (it.accountId.isBlank() || it.accountId in liveIds)
            },
            usageLabel = stringResource(R.string.services_section_usage),
            subscriptionLabel = stringResource(R.string.services_section_subscription),
            locale = locale,
        )
    }
    val rateCaptions = conversionRateCaptions(snapshot?.convertedJson, snapshot?.walletsJson, locale)
    val wallets = walletBreakdown(snapshot?.walletsJson)
    val endedAt = archived.mapNotNull { AccountExtras.archivedAtMillis(it) }.maxOrNull()
    val endedCaption = when {
        !isEnded -> null
        endedAt != null -> stringResource(
            R.string.services_ended_provider,
            ServiceRelativeTime.yearMonth(endedAt, locale),
        )
        else -> stringResource(R.string.services_ended)
    }
    val lastRefreshMillis = snapshot?.fetchedAtMillis?.takeIf { it > 0L }
    val hasBilling = !isEnded && (connected.isNotEmpty() || subscriptions.isNotEmpty() || snapshot != null)
    val showsPaidRefresh = !isEnded && provider?.costsMoneyToRefresh == true && connected.isNotEmpty()
    val showsRefresh = !isEnded && connected.isNotEmpty()

    HierarchicalContent(
        targetState = showingBreakdown,
        depth = if (showingBreakdown) 1 else 0,
        modifier = modifier,
        canPop = showingBreakdown,
        onPop = { showingBreakdown = false },
        contentKey = { if (it) "breakdown" else "detail" },
    ) { showing ->
        if (showing) {
            SpendBreakdownScreen(
                linesJson = spendLinesJson,
                onBack = { showingBreakdown = false },
            )
            return@HierarchicalContent
        }
    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            MediumFlexibleTopAppBar(
                title = { Text(name) },
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
                actions = {
                    if (showsRefresh) {
                        IconButton(
                            onClick = { session.refreshProvider(providerId) },
                            enabled = !session.isRefreshing,
                            shapes = IconButtonDefaults.shapes(),
                        ) {
                            SymbolIcon(
                                MaterialSymbol.Refresh,
                                contentDescription = stringResource(R.string.action_refresh),
                            )
                        }
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier
                .testTag(UITestId.PROVIDER_DETAIL_LIST)
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            if (hasBilling || isEnded) {
                AmountHero(
                    providerId = providerId,
                    name = name,
                    colorKey = colorKey,
                    amountText = amountText ?: "—",
                    kind = kind,
                    quotaPercent = quota?.usedPercent,
                    compositionCaption = compositionCaption,
                    rateCaptions = rateCaptions,
                    wallets = wallets,
                    endedCaption = endedCaption,
                    lastRefreshMillis = lastRefreshMillis,
                    nowMillis = session.nowMillis(),
                    showsRefresh = showsRefresh,
                )
            }
            if (!breakdown.isEmpty) {
                SpendBreakdownPreviewSection(
                    content = breakdown,
                    onOpen = { showingBreakdown = true },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                )
            }
            if (showsPaidRefresh) {
                val includeLabel = stringResource(R.string.services_include_global_refresh)
                val includeHint = stringResource(R.string.services_include_global_refresh_a11y)
                BentoGroup(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                    ListItem(
                        onClick = {
                            val next = !includeInGlobalRefresh
                            includeInGlobalRefresh = next
                            connectedIds.forEach { id ->
                                session.preferences.setIncludeInGlobalRefresh(id, next)
                            }
                        },
                        supportingContent = {
                            Text(stringResource(R.string.services_include_global_refresh_hint))
                        },
                        trailingContent = {
                            Switch(
                                checked = includeInGlobalRefresh,
                                onCheckedChange = { next ->
                                    includeInGlobalRefresh = next
                                    connectedIds.forEach { id ->
                                        session.preferences.setIncludeInGlobalRefresh(id, next)
                                    }
                                },
                            )
                        },
                        modifier = Modifier
                            .clip(Bento.middle)
                            .semantics { contentDescription = "$includeLabel。$includeHint" },
                        colors = bentoRowColors(),
                        content = { Text(includeLabel) },
                    )
                }
            }

            if (!isEnded) {
                SectionLabel(stringResource(R.string.services_section_usage))
                UsageSection(
                    name = name,
                    connected = connected,
                    hasLive = hasLive,
                    inbox = inbox,
                    snapshots = snapshots,
                    amountByAccount = compositionRows.associate { it.accountId to it.amount },
                    fillUsageLabel = stringResource(
                        if (snapshot?.source == "manual") {
                            R.string.services_update_usage
                        } else {
                            R.string.services_fill_usage
                        },
                    ),
                    onConnect = { session.openUsageSetup(providerId) },
                    onFillUsage = { showingUsageEntry = true },
                    onInboxAttach = { session.openUsageSetup(providerId) },
                    onManageCredentials = { showingCredentials = true },
                )
            }
            if (snapshots.isNotEmpty()) {
                val chartsByRange = remember(snapshots) {
                    HistoryRange.entries.associateWith { session.historyChart(providerId, it) }
                }
                val showRangePicker = chartsByRange.values.any { it.hasPlot() }
                val chart = chartsByRange.getValue(historyRange)
                ProviderHistory(
                    snapshots = snapshots,
                    chart = chart,
                    range = historyRange,
                    onRange = { historyRange = it },
                    showRangePicker = showRangePicker,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    nowMillis = session.nowMillis(),
                )
            }

            SectionLabel(stringResource(R.string.services_section_subscription))
            if (subscriptions.isEmpty()) {
                Text(
                    text = stringResource(R.string.services_subscription_footer),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp),
                )
            }
            BentoGroup(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                subscriptions.forEach { item ->
                    ListItem(
                        onClick = { editingSubscription = item },
                        supportingContent = { Text(subscriptionCaption(item, hasEnded = false)) },
                        trailingContent = {
                            Text(
                                formatMoney(item.amountUsd),
                                style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                            )
                        },
                        modifier = Modifier.clip(Bento.middle),
                        colors = bentoRowColors(),
                        content = { Text(item.name) },
                    )
                }
                ListItem(
                    onClick = { addingSubscription = true },
                    modifier = Modifier.clip(Bento.middle),
                    colors = bentoRowColors(),
                    content = { Text(stringResource(R.string.services_add_subscription)) },
                )
            }

            // 退掉之后的订阅住在这里。**它们仍然算在过去那几个月的账里**——
            // 这一节存在的理由就是让「删除」和「结束」看起来不是一回事。
            if (endedSubscriptions.isNotEmpty()) {
                SectionLabel(stringResource(R.string.services_past_subscriptions))
                BentoGroup(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                    endedSubscriptions.forEach { item ->
                        ListItem(
                            onClick = { editingSubscription = item },
                            supportingContent = { Text(subscriptionCaption(item, session.hasEnded(item))) },
                            trailingContent = {
                                Text(
                                    formatMoney(item.amountUsd),
                                    style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            },
                            modifier = Modifier.clip(Bento.middle),
                            colors = bentoRowColors(),
                            content = {
                                Text(item.name, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            },
                        )
                    }
                }
            }

            Spacer(Modifier.height(16.dp))
            // 官网账单页。URL 编译进 .so（不来自远程目录），和 iOS 同一条红线。
            if (provider?.billingURL?.isNotBlank() == true) {
                BentoGroup(modifier = Modifier.padding(horizontal = 16.dp)) {
                    val uriHandler = androidx.compose.ui.platform.LocalUriHandler.current
                    ListItem(
                        onClick = { uriHandler.openUri(provider.billingURL) },
                        modifier = Modifier.clip(Bento.middle),
                        colors = bentoRowColors(),
                        content = { Text(stringResource(R.string.services_open_billing)) },
                    )
                }
                Spacer(Modifier.height(16.dp))
            }
            BentoGroup(modifier = Modifier.padding(horizontal = 16.dp)) {
                if (!isEnded && (connected.isNotEmpty() || subscriptions.isNotEmpty())) {
                    ListItem(
                        onClick = { confirmingEnd = true },
                        modifier = Modifier.clip(Bento.middle),
                        colors = bentoRowColors(),
                        content = {
                            Text(
                                text = stringResource(R.string.services_end, name),
                                color = MaterialTheme.colorScheme.error,
                            )
                        },
                    )
                }
                ListItem(
                    onClick = { confirmingDelete = true },
                    supportingContent = { Text(stringResource(R.string.services_remove_footer)) },
                    modifier = Modifier.clip(Bento.middle),
                    colors = bentoRowColors(),
                    content = {
                        Text(
                            text = stringResource(R.string.action_clear_provider, name),
                            color = MaterialTheme.colorScheme.error,
                        )
                    },
                )
            }
            Text(
                text = stringResource(R.string.services_end_footer),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
            )
            Spacer(Modifier.height(24.dp))
        }
    }
    }

    if (addingSubscription || editingSubscription != null) {
        ProviderSubscriptionSheet(
            providerId = providerId,
            accountId = live.singleOrNull()?.accountId,
            editing = editingSubscription,
            onDismiss = {
                addingSubscription = false
                editingSubscription = null
            },
            onSave = { row ->
                session.saveSubscription(row)
                addingSubscription = false
                editingSubscription = null
            },
            onDelete = { idToDelete ->
                session.deleteSubscription(idToDelete)
                addingSubscription = false
                editingSubscription = null
            },
        )
    }
    if (showingUsageEntry) {
        ManualUsageEntrySheet(
            updating = snapshot?.source == "manual",
            snapshots = snapshots,
            onDismiss = { showingUsageEntry = false },
            onSave = { amount, periodMillis ->
                session.saveManualUsage(
                    providerId,
                    live.singleOrNull()?.accountId,
                    amount,
                    periodMillis,
                )
                showingUsageEntry = false
            },
        )
    }
    if (showingCredentials) {
        CredentialManagementSheet(
            session = session,
            providerId = providerId,
            displayName = name,
            onDismiss = { showingCredentials = false },
            onRotate = { account ->
                showingCredentials = false
                session.openUsageSetup(providerId, account.accountId)
            },
            onAdd = {
                showingCredentials = false
                val extra = session.addUsageAccount(providerId)
                session.openUsageSetup(providerId, extra.accountId)
            },
        )
    }
    if (confirmingEnd) {
        AlertDialog(
            onDismissRequest = { confirmingEnd = false },
            title = { Text(stringResource(R.string.services_end_title, name)) },
            text = { Text(stringResource(R.string.services_end_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        session.archiveProvider(providerId)
                        confirmingEnd = false
                    },
                ) {
                    Text(stringResource(R.string.services_end_confirm))
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmingEnd = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
    if (confirmingDelete) {
        AlertDialog(
            onDismissRequest = { confirmingDelete = false },
            title = { Text(stringResource(R.string.services_remove_title, name)) },
            text = { Text(stringResource(R.string.services_remove_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        session.removeProvider(providerId)
                        confirmingDelete = false
                    },
                ) {
                    Text(
                        stringResource(R.string.services_remove_confirm),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmingDelete = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMediumEmphasized,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(start = 20.dp, end = 16.dp, top = 20.dp, bottom = 8.dp),
    )
}

private fun snapshotsForAccount(snapshots: List<SnapshotRow>, accountId: String): Boolean {
    return snapshots.any { it.accountId == accountId }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun AmountHero(
    providerId: String,
    name: String,
    colorKey: String,
    amountText: String,
    kind: String,
    quotaPercent: Int?,
    compositionCaption: String?,
    rateCaptions: List<String>,
    wallets: List<ConvertedNote>,
    endedCaption: String?,
    lastRefreshMillis: Long?,
    nowMillis: Long,
    showsRefresh: Boolean,
) {
    val context = LocalContext.current
    Surface(
        color = MaterialTheme.colorScheme.primaryContainer,
        contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
        shape = Bento.solo,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .sharedProviderContainer(providerId, Bento.solo),
    ) {
        Row(modifier = Modifier.padding(horizontal = 24.dp, vertical = 24.dp)) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    text = if (endedCaption != null) {
                        endedCaption
                    } else {
                        stringResource(R.string.services_this_month)
                    },
                    style = MaterialTheme.typography.titleMediumEmphasized,
                )
                AmountText(
                    text = amountText,
                    style = MaterialTheme.typography.displayMediumEmphasized,
                )
                if (kind == "freeTier" && quotaPercent != null) {
                    Text(
                        text = stringResource(R.string.services_quota_used, quotaPercent),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                } else if (endedCaption == null) {
                    Text(
                        text = stringResource(kindTitleRes(kind.ifBlank { "usage" })),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                }
                compositionCaption?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                    )
                }
                rateCaptions.forEach { caption ->
                    Text(
                        text = caption,
                        style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.72f),
                    )
                }
                wallets.forEach { wallet ->
                    Text(
                        text = wallet.walletLine(),
                        style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                    )
                }
                if (showsRefresh || lastRefreshMillis != null) {
                    val caption = if (lastRefreshMillis != null) {
                        stringResource(
                            R.string.services_last_refresh,
                            ServiceRelativeTime.caption(context, lastRefreshMillis, nowMillis),
                        )
                    } else {
                        stringResource(R.string.services_never_refresh)
                    }
                    Text(
                        text = caption,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.72f),
                    )
                }
            }
            ServiceGlyph(
                name = name,
                colorKey = colorKey,
                size = 56.dp,
                modifier = Modifier.sharedProviderElement(providerId),
            )
        }
    }
}

@Composable
private fun UsageSection(
    name: String,
    connected: List<AccountRow>,
    hasLive: Boolean,
    inbox: Boolean,
    snapshots: List<SnapshotRow>,
    amountByAccount: Map<String, String>,
    fillUsageLabel: String,
    onConnect: () -> Unit,
    onFillUsage: () -> Unit,
    onInboxAttach: () -> Unit,
    onManageCredentials: () -> Unit,
) {
    if (connected.isEmpty()) {
        BentoGroup(modifier = Modifier.padding(horizontal = 16.dp)) {
            if (hasLive) {
                val connectSpoken = stringResource(R.string.setup_title, name)
                ListItem(
                    onClick = onConnect,
                    modifier = Modifier
                        .clip(Bento.middle)
                        .semantics { contentDescription = connectSpoken }
                        .testTag(UITestId.PROVIDER_DETAIL_CONNECT),
                    colors = bentoRowColors(),
                    content = { Text(stringResource(R.string.action_connect_usage, name)) },
                )
            }
            if (inbox || !hasLive) {
                ListItem(
                    onClick = onFillUsage,
                    modifier = Modifier.clip(Bento.middle),
                    colors = bentoRowColors(),
                    content = { Text(fillUsageLabel) },
                )
            }
            if (inbox && !hasLive) {
                ListItem(
                    onClick = onInboxAttach,
                    modifier = Modifier.clip(Bento.middle),
                    colors = bentoRowColors(),
                    content = { Text(stringResource(R.string.services_inbox_attach)) },
                )
            }
        }
        val footer = when {
            inbox && !hasLive -> R.string.detail_inbox_hint
            !hasLive -> R.string.services_usage_empty_footer
            else -> R.string.detail_usage_empty
        }
        Text(
            text = stringResource(footer),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
        )
    } else {
        BentoGroup(modifier = Modifier.padding(horizontal = 16.dp)) {
            if (connected.size == 1) {
                val account = connected.first()
                val spend = amountByAccount[account.accountId]
                    ?: snapshots.filter { it.accountId == account.accountId }
                        .maxByOrNull { it.fetchedAtMillis }
                        ?.currentSpendUsd
                        ?.let { formatMoney(it) }
                ListItem(
                    trailingContent = {
                        Text(
                            spend ?: "—",
                            style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                        )
                    },
                    modifier = Modifier.clip(Bento.middle),
                    colors = bentoRowColors(),
                    content = {
                        Text(
                            AccountExtras.nickname(account)
                                ?: stringResource(R.string.services_section_usage),
                        )
                    },
                )
                if (inbox) {
                    ListItem(
                        onClick = onFillUsage,
                        modifier = Modifier.clip(Bento.middle),
                        colors = bentoRowColors(),
                        content = { Text(fillUsageLabel) },
                    )
                }
            } else {
                connected.forEachIndexed { index, account ->
                    val spend = amountByAccount[account.accountId]
                        ?: snapshots.filter { it.accountId == account.accountId }
                            .maxByOrNull { it.fetchedAtMillis }
                            ?.currentSpendUsd
                            ?.let { formatMoney(it) }
                    val title = AccountExtras.nickname(account)
                        ?: stringResource(R.string.services_account_n, index + 1)
                    ListItem(
                        trailingContent = {
                            Text(
                                spend ?: "—",
                                style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                            )
                        },
                        modifier = Modifier.clip(Bento.middle),
                        colors = bentoRowColors(),
                        content = { Text(title) },
                    )
                }
            }
            ListItem(
                onClick = onManageCredentials,
                modifier = Modifier.clip(Bento.middle),
                colors = bentoRowColors(),
                content = { Text(stringResource(R.string.action_manage_credentials)) },
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun AmountHeroPreview() {
    TollCatTheme {
        AmountHero(
            providerId = "cloudflare",
            name = "Cloudflare",
            colorKey = "cloudflare",
            amountText = "$16.05",
            kind = "usage",
            quotaPercent = null,
            compositionCaption = "（按量计费 $11.05 + 固定订阅 $5.00）",
            rateCaptions = listOf("（1 CNY = $0.1404）"),
            wallets = listOf(
                ConvertedNote("USD", "10.00", "1", "10.00"),
                ConvertedNote("CNY", "70.20", "0.1404", "9.86"),
            ),
            endedCaption = null,
            lastRefreshMillis = System.currentTimeMillis() - 30_000L,
            nowMillis = System.currentTimeMillis(),
            showsRefresh = true,
        )
    }
}
