package com.zhechengqi.tollcat

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsTopHeight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.core.view.WindowCompat
import com.zhechengqi.tollcat.dashboard.CategoriesDetailView
import com.zhechengqi.tollcat.dashboard.ComparisonDetailView
import com.zhechengqi.tollcat.dashboard.CompositionDetailView
import com.zhechengqi.tollcat.dashboard.DashboardEditSheet
import com.zhechengqi.tollcat.dashboard.DashboardEmptyView
import com.zhechengqi.tollcat.dashboard.DashboardFabMenu
import com.zhechengqi.tollcat.dashboard.DashboardFabScrim
import com.zhechengqi.tollcat.dashboard.DashboardFilterAccount
import com.zhechengqi.tollcat.dashboard.DashboardFilterSheet
import com.zhechengqi.tollcat.dashboard.DashboardPopulatedView
import com.zhechengqi.tollcat.dashboard.DashboardRoute
import com.zhechengqi.tollcat.dashboard.DashboardSkeleton
import com.zhechengqi.tollcat.dashboard.HeatmapDetailView
import com.zhechengqi.tollcat.dashboard.SubscriptionsDetailView
import com.zhechengqi.tollcat.dashboard.dashboardFilterNote
import com.zhechengqi.tollcat.services.ProviderSubscriptionSheet
import com.zhechengqi.tollcat.share.ShareCardBuilder
import com.zhechengqi.tollcat.share.ShareCardExporter
import com.zhechengqi.tollcat.ui.FadeThroughContent
import com.zhechengqi.tollcat.ui.HierarchicalContent

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun DashboardScreen(session: TollCatSession, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val dashboard = session.dashboard
    var route by rememberSaveable { mutableStateOf(DashboardRoute.Home) }
    var showFilter by remember { mutableStateOf(false) }
    var showEdit by remember { mutableStateOf(false) }
    var addingSubscription by remember { mutableStateOf(false) }
    var fabExpanded by rememberSaveable { mutableStateOf(false) }
    var heroBehindStatusBar by remember { mutableStateOf(true) }
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
    // 筛选是重算：JNI 返回的构成已经带着取景框，这里不再二次过滤。
    val composition = dashboard.composition
    val persistenceStatus = session.persistenceStatus()
    val homeScroll = rememberScrollState()

    val phase = when {
        !dashboard.empty -> DashboardPhase.Populated
        session.isRefreshing -> DashboardPhase.Loading
        else -> DashboardPhase.Empty
    }
    val showsHome = phase == DashboardPhase.Populated && route == DashboardRoute.Home
    // 顶栏还垫在状态栏底下时，图标颜色跟着顶栏（主色）走；滑过去以后回到页面底色的规则。
    DashboardStatusBarAppearance(overHero = showsHome && heroBehindStatusBar)

    TrackScreen(dashboardUsageScreen(route))
    Scaffold(
        modifier = modifier,
        floatingActionButton = {
            if (showsHome) {
                DashboardFabMenu(
                    expanded = fabExpanded,
                    onExpandedChange = { fabExpanded = it },
                    onAddService = { session.openAdd() },
                    onAddSubscription = { addingSubscription = true },
                    onEditDashboard = { showEdit = true },
                )
            }
        },
    ) { inner ->
        // 主页的顶栏自己钻到状态栏下面，不吃 Scaffold 的上边距；二级页照旧。
        val padding = if (showsHome) PaddingValues(bottom = inner.calculateBottomPadding()) else inner
        Box(
            Modifier
                .padding(padding)
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
                                    nowMillis = session.nowMillis(),
                                    includesSubscriptions = session.filter.includesSubscriptions,
                                    onToggleSubscriptions = { include ->
                                        session.applyFilter(
                                            session.filter.copy(includesSubscriptions = include),
                                        )
                                    },
                                    onFilter = { showFilter = true },
                                    onShare = { ShareCardExporter.share(context, shareContent, shareChooser) },
                                    isRefreshing = session.isRefreshing,
                                    persistenceStatus = persistenceStatus,
                                    onDismissDemo = { session.dismissDemoBanner() },
                                    refreshFailed = session.refreshFailed,
                                    scrollState = homeScroll,
                                    onHeroBehindStatusBar = { heroBehindStatusBar = it },
                                )
                            }
                        }
                    }
                }
            }
            if (showsHome && homeScroll.value > 0) {
                // 一滑动就在状态栏底下垫一条：顶栏还在时垫主色，滑走以后垫页面底色，
                // 字不从状态栏图标底下穿过去。
                Box(
                    Modifier
                        .align(Alignment.TopCenter)
                        .fillMaxWidth()
                        .windowInsetsTopHeight(WindowInsets.statusBars)
                        .background(
                            if (heroBehindStatusBar) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface,
                        ),
                )
            }
            DashboardFabScrim(expanded = showsHome && fabExpanded, onDismiss = { fabExpanded = false })
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
    if (addingSubscription) {
        ProviderSubscriptionSheet(
            providerId = null,
            accountId = null,
            editing = null,
            onDismiss = { addingSubscription = false },
            onSave = { row ->
                session.saveSubscription(row)
                addingSubscription = false
            },
            onDelete = null,
        )
    }
}

/**
 * 状态栏图标深浅：[overHero] 时看顶栏主色的亮度（浅色主题主色是深蓝→白图标；
 * 深色主题主色是浅紫→黑图标），否则看页面底色。离开主页时还原成页面底色的规则。
 */
@Composable
internal fun DashboardStatusBarAppearance(overHero: Boolean) {
    val view = LocalView.current
    if (view.isInEditMode) return
    val heroIsLight = MaterialTheme.colorScheme.primary.luminance() > 0.5f
    val surfaceIsLight = MaterialTheme.colorScheme.surface.luminance() > 0.5f
    DisposableEffect(overHero, heroIsLight, surfaceIsLight) {
        val window = view.context.findActivity()?.window
        val controller = window?.let { WindowCompat.getInsetsController(it, view) }
        controller?.isAppearanceLightStatusBars = if (overHero) heroIsLight else surfaceIsLight
        onDispose { controller?.isAppearanceLightStatusBars = surfaceIsLight }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

private enum class DashboardPhase { Empty, Loading, Populated }
