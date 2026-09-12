package com.zhechengqi.tollcat

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MediumFlexibleTopAppBar
import androidx.compose.material3.MediumFloatingActionButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.services.ProviderSubscriptionSheet
import com.zhechengqi.tollcat.services.ServiceListSort
import com.zhechengqi.tollcat.services.ServiceRelativeTime
import com.zhechengqi.tollcat.services.ServiceRow
import com.zhechengqi.tollcat.services.ServicesEmpty
import com.zhechengqi.tollcat.services.arrangeSections
import com.zhechengqi.tollcat.services.buildServiceRows
import com.zhechengqi.tollcat.services.categoryTitleRes
import com.zhechengqi.tollcat.services.formatMoney
import com.zhechengqi.tollcat.services.kindTitleRes
import com.zhechengqi.tollcat.services.subscriptionCaption
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ServicesScreen(session: TollCatSession, modifier: Modifier = Modifier) {
    session.dataRevision
    session.dashboard
    val archivedMemberships = session.archivedMemberships()
    val allUnaffiliated = session.unaffiliatedSubscriptions()
    val unaffiliated = allUnaffiliated.filter { !session.hasEnded(it) }
    // 退掉的挪到最下面单开一节：它们不再花钱，但过去几个月的账里有它们。
    val endedUnaffiliated = allUnaffiliated.filter { session.hasEnded(it) }
    val fullyEmpty = session.memberships().isEmpty() && allUnaffiliated.isEmpty()
    val hasPast = endedUnaffiliated.isNotEmpty() || archivedMemberships.isNotEmpty()
    var sort by rememberSaveable { mutableStateOf(ServiceListSort.Kind) }
    var editingManual by remember { mutableStateOf<SubscriptionRow?>(null) }
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val context = LocalContext.current
    val nowMillis = session.nowMillis()
    val scoped = remember(session.dashboard, session.displayCurrency, session.clockOverrideMillis) {
        session.serviceScopedDashboard()
    }
    val rows = buildServiceRows(
        session = session,
        scoped = scoped,
        nowMillis = nowMillis,
        freeQuota = context.getString(R.string.services_free_quota),
        quotaUsed = { context.getString(R.string.services_quota_used, it) },
        typed = context.getString(R.string.services_typed),
        paidRefresh = context.getString(R.string.services_paid_refresh),
        noAmount = context.getString(R.string.services_no_amount),
        balance = { context.getString(R.string.services_balance, it) },
        usageCount = { context.getString(R.string.services_usage_count, it) },
        kindTitle = { context.getString(kindTitleRes(it)) },
        relative = { ServiceRelativeTime.caption(context, it, nowMillis) },
    )
    val sections = arrangeSections(rows, sort, session.catalog.categoryOrder)
    // 排序切换/增删行走 animateItem；「移除动画」时保留 fade、关掉位移（M3 降级定式）。
    val reduceMotion = LocalReduceMotion.current
    val itemPlacement = MaterialTheme.motionScheme.defaultSpatialSpec<IntOffset>()
        .takeUnless { reduceMotion }
    val itemFade = MaterialTheme.motionScheme.fastEffectsSpec<Float>()
    // 分组排序下多于一组才画小标题。一组标题是废话。
    val showSectionTitles = sort != ServiceListSort.Price && sections.size > 1
    val detailHint = stringResource(R.string.services_hint_detail)

    Scaffold(
        modifier = modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            MediumFlexibleTopAppBar(
                title = { Text(stringResource(R.string.tab_services)) },
                actions = {
                    IconButton(
                        onClick = { session.refreshAll() },
                        enabled = !session.isRefreshing && !fullyEmpty,
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(
                            MaterialSymbol.Refresh,
                            contentDescription = stringResource(R.string.services_refresh_bills),
                        )
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
        floatingActionButton = {
            if (!fullyEmpty) {
                val addSpoken = stringResource(R.string.action_add_service)
                MediumFloatingActionButton(
                    onClick = { session.openAdd() },
                    modifier = Modifier
                        .semantics { contentDescription = addSpoken }
                        .testTag(UITestId.SERVICES_ADD),
                ) {
                    SymbolIcon(MaterialSymbol.Add, contentDescription = stringResource(R.string.action_add_service))
                }
            }
        },
    ) { inner ->
        if (fullyEmpty) {
            ServicesEmpty(
                onAdd = { session.openAdd() },
                modifier = Modifier
                    .padding(inner)
                    .fillMaxSize(),
            )
        } else {
            val refreshState = rememberPullToRefreshState()
            PullToRefreshBox(
                isRefreshing = session.isRefreshing,
                onRefresh = { session.refreshAll() },
                modifier = Modifier
                    .padding(inner)
                    .fillMaxSize(),
                state = refreshState,
            ) {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 88.dp),
                    verticalArrangement = Arrangement.spacedBy(Bento.gap),
                ) {
                    if (rows.isNotEmpty()) {
                        // 排序拉到明面上——筛选 chips 行，不藏进溢出菜单。
                        item(key = "sort-chips") {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                modifier = Modifier
                                    .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                    .padding(bottom = 5.dp),
                            ) {
                                SortChip(
                                    selected = sort == ServiceListSort.Kind,
                                    label = stringResource(R.string.services_sort_kind),
                                    onClick = { sort = ServiceListSort.Kind },
                                )
                                SortChip(
                                    selected = sort == ServiceListSort.Category,
                                    label = stringResource(R.string.services_sort_category),
                                    onClick = { sort = ServiceListSort.Category },
                                )
                                SortChip(
                                    selected = sort == ServiceListSort.Price,
                                    label = stringResource(R.string.services_sort_price),
                                    onClick = { sort = ServiceListSort.Price },
                                )
                            }
                        }
                    }
                    if (sections.isEmpty()) {
                        item {
                            Text(
                                text = stringResource(R.string.services_empty_connected_footer),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(vertical = 20.dp),
                            )
                        }
                    } else {
                        sections.forEach { section ->
                            if (showSectionTitles) {
                                item(key = "header-${section.id}") {
                                    Text(
                                        text = section.category?.let { stringResource(categoryTitleRes(it)) }
                                            ?: stringResource(kindTitleRes(section.kind ?: "usage")),
                                        style = MaterialTheme.typography.titleMediumEmphasized,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier
                                            .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                            .padding(start = 4.dp, top = 13.dp, bottom = 5.dp),
                                    )
                                }
                            }
                            itemsIndexed(section.rows, key = { _, row -> row.id }) { index, row ->
                                ServiceRow(
                                    row = row,
                                    onClick = { session.openDetail(row.providerId) },
                                    hint = detailHint,
                                    modifier = Modifier
                                        .animateItem(
                                            fadeInSpec = itemFade,
                                            placementSpec = itemPlacement,
                                            fadeOutSpec = itemFade,
                                        )
                                        .testTag(UITestId.servicesRow(row.providerId)),
                                    shape = Bento.groupShape(
                                        first = index == 0,
                                        last = index == section.rows.lastIndex,
                                    ),
                                )
                            }
                        }
                    }
                    if (unaffiliated.isNotEmpty()) {
                        item {
                            Text(
                                text = stringResource(R.string.services_manual_subscription),
                                style = MaterialTheme.typography.titleMediumEmphasized,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(start = 4.dp, top = 13.dp, bottom = 5.dp),
                            )
                        }
                        itemsIndexed(unaffiliated, key = { _, item -> "sub-${item.id}" }) { index, item ->
                            val period = subscriptionCaption(item, hasEnded = false)
                            ListItem(
                                onClick = { editingManual = item },
                                modifier = Modifier
                                    .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                    .clip(
                                        Bento.groupShape(
                                            first = index == 0,
                                            last = index == unaffiliated.lastIndex,
                                        ),
                                    ),
                                colors = ListItemDefaults.colors(
                                    containerColor = MaterialTheme.colorScheme.surfaceContainer,
                                ),
                                supportingContent = { Text(period) },
                                trailingContent = {
                                    Text(
                                        formatMoney(item.amountUsd),
                                        style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                                    )
                                },
                                content = { Text(item.name) },
                            )
                        }
                    }
                    // 停掉的那些不占主列表——主列表回答「我现在每个月付多少」。
                    // 给一个入口，想查再进去。Android 的「添加服务」是 FAB，
                    // 所以这一行落在列表末尾自己一组。
                    if (hasPast) {
                        item {
                            ListItem(
                                onClick = { session.openPast() },
                                modifier = Modifier.clip(Bento.solo),
                                colors = ListItemDefaults.colors(
                                    containerColor = MaterialTheme.colorScheme.surfaceContainer,
                                ),
                                leadingContent = {
                                    SymbolIcon(MaterialSymbol.History, contentDescription = null)
                                },
                                trailingContent = {
                                    SymbolIcon(MaterialSymbol.KeyboardArrowRight, contentDescription = null)
                                },
                                content = { Text(stringResource(R.string.services_past_services)) },
                            )
                        }
                    }
                }
            }
        }
    }

    editingManual?.let { item ->
        ProviderSubscriptionSheet(
            providerId = item.providerId,
            accountId = item.accountId,
            editing = item,
            onDismiss = { editingManual = null },
            onSave = { row ->
                session.saveSubscription(row)
                editingManual = null
            },
            onDelete = { id ->
                session.deleteSubscription(id)
                editingManual = null
            },
        )
    }
}

@Composable
private fun SortChip(selected: Boolean, label: String, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(label) },
        leadingIcon = if (selected) {
            {
                SymbolIcon(
                    MaterialSymbol.Check,
                    contentDescription = null,
                    size = FilterChipDefaults.IconSize,
                )
            }
        } else {
            null
        },
    )
}
