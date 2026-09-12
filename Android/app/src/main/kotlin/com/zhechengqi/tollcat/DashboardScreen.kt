package com.zhechengqi.tollcat

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.HorizontalFloatingToolbar
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MediumFlexibleTopAppBar
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.dashboard.ComparisonDetailView
import com.zhechengqi.tollcat.dashboard.CompositionDetailView
import com.zhechengqi.tollcat.dashboard.DashboardEmptyView
import com.zhechengqi.tollcat.dashboard.DashboardFilterAccount
import com.zhechengqi.tollcat.dashboard.dashboardFilterNote
import com.zhechengqi.tollcat.dashboard.DashboardEditSheet
import com.zhechengqi.tollcat.dashboard.DashboardFilterSheet
import com.zhechengqi.tollcat.dashboard.CategoriesDetailView
import com.zhechengqi.tollcat.dashboard.HeatmapDetailView
import com.zhechengqi.tollcat.dashboard.SubscriptionsDetailView
import com.zhechengqi.tollcat.dashboard.DashboardPopulatedView
import com.zhechengqi.tollcat.dashboard.DashboardRoute
import com.zhechengqi.tollcat.dashboard.DashboardSkeleton
import com.zhechengqi.tollcat.share.ShareCardBuilder
import com.zhechengqi.tollcat.share.ShareCardExporter
import com.zhechengqi.tollcat.ui.FadeThroughContent
import com.zhechengqi.tollcat.ui.HierarchicalContent
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun DashboardScreen(session: TollCatSession, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val dashboard = session.dashboard
    var route by rememberSaveable { mutableStateOf(DashboardRoute.Home) }
    var showFilter by remember { mutableStateOf(false) }
    var showEdit by remember { mutableStateOf(false) }
    var showMore by remember { mutableStateOf(false) }
    val accounts = DashboardFilterAccount.from(session)
    val filterNote = dashboardFilterNote(session.filter, accounts)
    val shareContent = ShareCardBuilder.content(
        dashboard = dashboard,
        filterNote = filterNote,
        emptyTotal = stringResource(R.string.dashboard_empty_title),
        projectedCaption = if (dashboard.allowsProjection) {
            stringResource(R.string.projected_caption, dashboard.formattedProjected)
        } else {
            null
        },
        subscriptionCaption = dashboard.subscriptionCaption,
        otherLabel = stringResource(R.string.dashboard_composition_other),
        tagline = stringResource(R.string.share_card_tagline),
    )
    val shareChooser = stringResource(R.string.action_share_to)
    val shareA11y = stringResource(R.string.dashboard_share_a11y)
    // 筛选是重算：JNI 返回的构成已经带着取景框，这里不再二次过滤。
    val composition = dashboard.composition

    val persistenceStatus = session.persistenceStatus()
    val periodTitle = dashboard.periodCaption.ifBlank { dashboard.monthTitle }
    val showPeriodBar = !dashboard.empty && route == DashboardRoute.Home
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val subscriptionAccountId = dashboard.subscriptions?.items
        ?.map { it.accountId }
        ?.filter { it.isNotBlank() }
        ?.distinct()
        ?.singleOrNull()

    TrackScreen(dashboardUsageScreen(route))
    Scaffold(
        modifier = if (showPeriodBar) modifier.nestedScroll(scrollBehavior.nestedScrollConnection) else modifier,
        topBar = {
            if (showPeriodBar) {
                MediumFlexibleTopAppBar(
                    title = { Text(periodTitle) },
                    scrollBehavior = scrollBehavior,
                )
            }
        },
    ) { inner ->
        Box(
            Modifier
                .padding(inner)
                .fillMaxSize(),
        ) {
            val refreshState = rememberPullToRefreshState()
            PullToRefreshBox(
                isRefreshing = session.isRefreshing,
                onRefresh = { session.refreshAll() },
                modifier = Modifier.fillMaxSize(),
                state = refreshState,
            ) {
                // 空态三相：没服务→引导；有服务但首笔数据在路上→骨架；有数据→正文。
                // fade-through 让内容盖着骨架淡入（skeleton loader 定式的收尾）。
                val phase = when {
                    !dashboard.empty -> DashboardPhase.Populated
                    session.isRefreshing -> DashboardPhase.Loading
                    else -> DashboardPhase.Empty
                }
                FadeThroughContent(
                    targetState = phase,
                    modifier = Modifier.fillMaxSize(),
                ) { current ->
                    when (current) {
                        DashboardPhase.Empty -> DashboardEmptyView(
                            onAdd = { session.openAdd() },
                            modifier = Modifier.fillMaxSize(),
                            didClearAllData = session.didClearAllData,
                            persistenceStatus = persistenceStatus,
                            onDismissDemo = { session.dismissDemoBanner() },
                        )
                        DashboardPhase.Loading -> DashboardSkeleton()
                        DashboardPhase.Populated -> HierarchicalContent(
                            targetState = route,
                            depth = if (route == DashboardRoute.Home) 0 else 1,
                            modifier = Modifier.fillMaxSize(),
                            canPop = route != DashboardRoute.Home,
                            onPop = { route = DashboardRoute.Home },
                        ) { inner ->
                            when (inner) {
                                DashboardRoute.Composition -> CompositionDetailView(
                                    rows = composition,
                                    onBack = { route = DashboardRoute.Home },
                                    onOpenProvider = { session.openAccountOrProvider(it) },
                                )
                                DashboardRoute.Comparison -> ComparisonDetailView(
                                    dashboard = dashboard,
                                    onBack = { route = DashboardRoute.Home },
                                    onOpen = { session.openAccountOrProvider(it) },
                                )
                                DashboardRoute.Heatmap -> HeatmapDetailView(
                                    months = dashboard.heatmap,
                                    onBack = { route = DashboardRoute.Home },
                                )
                                DashboardRoute.Categories -> CategoriesDetailView(
                                    slices = dashboard.categories,
                                    onBack = { route = DashboardRoute.Home },
                                )
                                DashboardRoute.Subscriptions -> {
                                    val module = dashboard.subscriptions
                                    if (module != null) {
                                        SubscriptionsDetailView(
                                            module = module,
                                            onBack = { route = DashboardRoute.Home },
                                            onOpen = { session.openAccountOrProvider(it) },
                                        )
                                    } else {
                                        SubscriptionsDetailView(
                                            items = emptyList(),
                                            onBack = { route = DashboardRoute.Home },
                                        )
                                    }
                                }
                                DashboardRoute.Home -> DashboardPopulatedView(
                                    dashboard = dashboard,
                                    filter = session.filter,
                                    accounts = accounts,
                                    onOpenComposition = { route = DashboardRoute.Composition },
                                    onOpenComparison = { route = DashboardRoute.Comparison },
                                    onOpenProvider = { session.openAccountOrProvider(it) },
                                    onOpenHeatmap = { route = DashboardRoute.Heatmap },
                                    onOpenCategories = { route = DashboardRoute.Categories },
                                    onOpenSubscriptions = { route = DashboardRoute.Subscriptions },
                                    extraModules = session.preferences.extraModules,
                                    moduleOrder = session.preferences.enabledModuleOrder(),
                                    hidesCat = session.preferences.hidesCat,
                                    includesSubscriptions = session.filter.includesSubscriptions,
                                    onToggleSubscriptions = { include ->
                                        session.applyFilter(
                                            session.filter.copy(includesSubscriptions = include),
                                        )
                                    },
                                    onSelectSubscription = subscriptionAccountId?.let { id ->
                                        { session.openAccountOrProvider(id) }
                                    },
                                    staleCaption = dashboard.staleCaption,
                                    persistenceStatus = persistenceStatus,
                                    onDismissDemo = { session.dismissDemoBanner() },
                                    refreshFailed = session.refreshFailed,
                                )
                            }
                        }
                    }
                }
            }
            if (!dashboard.empty && route == DashboardRoute.Home) {
                // iOS 顶栏三颗：刷新、筛选、更多（分享和编辑进菜单）。添加走服务 tab。
                HorizontalFloatingToolbar(
                    expanded = true,
                    colors = FloatingToolbarDefaults.standardFloatingToolbarColors(),
                    modifier = Modifier.align(Alignment.BottomCenter),
                ) {
                    IconButton(
                        onClick = { session.refreshAll() },
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        if (session.isRefreshing) {
                            LoadingIndicator(modifier = Modifier.size(24.dp))
                        } else {
                            SymbolIcon(
                                MaterialSymbol.Refresh,
                                contentDescription = stringResource(R.string.action_refresh),
                            )
                        }
                    }
                    IconButton(
                        onClick = { showFilter = true },
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        val filterActive = session.filter.isActive
                        val filterNote = dashboardFilterNote(session.filter, accounts)
                        val period = dashboard.periodCaption.takeIf {
                            !session.filter.isCurrentMonth && it.isNotBlank()
                        }
                        val filterSummary = listOfNotNull(period, filterNote).joinToString(" · ")
                        val filterDescription = if (filterActive && filterSummary.isNotBlank()) {
                            stringResource(R.string.dashboard_filter_active, filterSummary)
                        } else {
                            stringResource(R.string.dashboard_filter)
                        }
                        SymbolIcon(
                            MaterialSymbol.FilterList,
                            contentDescription = filterDescription,
                            filled = filterActive,
                        )
                    }
                    Box {
                        IconButton(
                            onClick = { showMore = true },
                            shapes = IconButtonDefaults.shapes(),
                        ) {
                            SymbolIcon(
                                MaterialSymbol.MoreHoriz,
                                contentDescription = stringResource(R.string.action_more),
                            )
                        }
                        DropdownMenu(
                            expanded = showMore,
                            onDismissRequest = { showMore = false },
                        ) {
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.action_share)) },
                                onClick = {
                                    showMore = false
                                    ShareCardExporter.share(context, shareContent, shareChooser)
                                },
                                leadingIcon = {
                                    Icon(
                                        painter = painterResource(R.drawable.ic_share),
                                        contentDescription = null,
                                    )
                                },
                                modifier = Modifier.semantics {
                                    contentDescription = shareA11y
                                },
                            )
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.dashboard_edit)) },
                                onClick = {
                                    showMore = false
                                    showEdit = true
                                },
                                leadingIcon = {
                                    SymbolIcon(
                                        MaterialSymbol.GridView,
                                        contentDescription = null,
                                    )
                                },
                            )
                        }
                    }
                }
            }
        }
    }

    if (showEdit) {
        DashboardEditSheet(
            order = session.preferences.enabledModuleOrder(),
            pinned = session.preferences.pinnedAccountIds,
            budgetUsd = session.preferences.monthlyBudgetUsd,
            accounts = accounts,
            onOrderChange = { order ->
                session.applyDashboardLayout(
                    order,
                    session.preferences.pinnedAccountIds,
                    session.preferences.monthlyBudgetUsd,
                )
            },
            onPinnedChange = { pins ->
                session.applyDashboardLayout(
                    session.preferences.enabledModuleOrder(),
                    pins,
                    session.preferences.monthlyBudgetUsd,
                )
            },
            onBudgetChange = { budget ->
                session.applyDashboardLayout(
                    session.preferences.enabledModuleOrder(),
                    session.preferences.pinnedAccountIds,
                    budget,
                )
            },
            onDismiss = { showEdit = false },
        )
    }
    if (showFilter) {
        DashboardFilterSheet(
            state = session.filter,
            accounts = accounts,
            nowMillis = session.nowMillis(),
            monthsWithReadings = session.monthsBackWithReadings(),
            previewDashboard = { draft -> session.previewDashboard(draft) },
            onApply = { next ->
                session.applyFilter(next)
                showFilter = false
            },
            onDismiss = { showFilter = false },
        )
    }
}

private enum class DashboardPhase { Empty, Loading, Populated }
