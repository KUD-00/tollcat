package com.zhechengqi.tollcat

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.only
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Text
import androidx.compose.material3.adaptive.currentWindowAdaptiveInfoV2
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffoldDefaults
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteType
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import com.zhechengqi.tollcat.services.PastServicesScreen
import com.zhechengqi.tollcat.ui.FadeThroughContent
import com.zhechengqi.tollcat.ui.HierarchicalContent
import com.zhechengqi.tollcat.ui.OnboardingPreferences
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.settings.ReminderAlarmScheduler
import com.zhechengqi.tollcat.settings.WhatsNewEntry
import com.zhechengqi.tollcat.settings.WhatsNewLaunch
import com.zhechengqi.tollcat.settings.WhatsNewSheet
import com.zhechengqi.tollcat.settings.appVersionShort
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalComposeUiApi::class)
@Composable
fun TollCatApp(session: TollCatSession) {
    val context = LocalContext.current
    WidgetSnapshot.install(context)
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner, session) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_START) {
                session.refreshIfNeededOnActivate()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    val onboarding = remember { OnboardingPreferences(context) }
    DisposableEffect(onboarding) {
        onDispose { onboarding.dispose() }
    }
    LaunchedEffect(Unit) {
        if (!onboarding.completed && session.memberships().isNotEmpty()) {
            onboarding.complete()
        }
        ReminderAlarmScheduler.sync(context)
    }
    // 更新后第一次冷启动那张面板。判据和 iOS 的 WhatsNewLaunch 同一套，
    // 一次冷启动只算一遍——弹没弹都把「看到哪一版」推到当前版本。
    var pendingWhatsNew by remember { mutableStateOf<List<WhatsNewEntry>>(emptyList()) }
    var completedOnboardingThisLaunch by remember { mutableStateOf(false) }
    LaunchedEffect(onboarding.completed) {
        if (!onboarding.completed) return@LaunchedEffect
        val current = appVersionShort(context)
        pendingWhatsNew = WhatsNewLaunch.pending(
            currentVersion = current,
            lastSeenVersion = session.preferences.lastSeenWhatsNewVersion,
            hasCompletedOnboarding = true,
            completedOnboardingThisLaunch = completedOnboardingThisLaunch,
            skipSheet = false,
        )
        session.preferences.lastSeenWhatsNewVersion = WhatsNewLaunch.advanced(
            lastSeenVersion = session.preferences.lastSeenWhatsNewVersion,
            currentVersion = current,
        )
    }
    if (pendingWhatsNew.isNotEmpty()) {
        WhatsNewSheet(
            entries = pendingWhatsNew,
            language = MoneyDisplay.localeTag(),
            onDismiss = { pendingWhatsNew = emptyList() },
        )
    }
    FadeThroughContent(
        targetState = onboarding.completed,
        modifier = Modifier
            .fillMaxSize()
            // testTag 默认只在 Compose 测试里可见；开了这个才会当 resource-id 挂到
            // 无障碍节点上，Maestro / UiAutomator 才能按 id 找到（maestro/ 的锚点）。
            .semantics { testTagsAsResourceId = true },
    ) { completed ->
        if (!completed) {
            TrackScreen(UsageScreens.ONBOARDING)
            OnboardingScreen(
                onSkip = {
                    completedOnboardingThisLaunch = true
                    onboarding.complete()
                },
                onAddFirstProvider = {
                    completedOnboardingThisLaunch = true
                    onboarding.complete()
                    session.openAdd()
                },
                currencies = session.catalog.currencies.ifEmpty { listOf("USD") },
                selectedCurrency = session.displayCurrency,
                onCurrencyChange = session::setCurrency,
            )
            return@FadeThroughContent
        }
        val tab = session.tab
        val layoutType = NavigationSuiteScaffoldDefaults.navigationSuiteType(currentWindowAdaptiveInfoV2())
        val tabContent: @Composable () -> Unit = {
            // ShortNavigationBar 已经把系统底 inset 算进自己的高度；内容是它的兄弟，
            // 不在这里消耗的话，里面的 Scaffold 会再垫一次，栏顶上留一条空缝。
            Box(
                Modifier
                    .fillMaxSize()
                    .consumeWindowInsets(WindowInsets.navigationBars.only(WindowInsetsSides.Bottom)),
            ) {
                FadeThroughContent(
                    targetState = tab,
                    modifier = Modifier.fillMaxSize(),
                ) { current ->
                    when (current) {
                        AppTab.Dashboard -> DashboardScreen(session)
                        AppTab.Services -> ServicesHost(session)
                        AppTab.Settings -> SettingsScreen(session)
                    }
                }
            }
        }
        if (layoutType == NavigationSuiteType.ShortNavigationBarCompact) {
            // 手机：短导航栏，项目横排（AppShortNavigationItems）。
            NavigationSuiteScaffold(
                navigationItems = { AppShortNavigationItems(tab = tab, onSelect = { session.tab = it }) },
                navigationSuiteType = layoutType,
                content = tabContent,
            )
        } else {
            // 平板 / 折叠屏展开：交给自适应导航（侧边 rail），项目还是那三个。
            NavigationSuiteScaffold(
                layoutType = layoutType,
                navigationSuiteItems = {
                    AppTab.entries.forEach { entry ->
                        item(
                            selected = tab == entry,
                            onClick = { session.tab = entry },
                            icon = { SymbolIcon(entry.symbol, contentDescription = null, filled = tab == entry) },
                            label = { Text(stringResource(entry.labelRes)) },
                            modifier = Modifier.testTag(entry.testTag),
                        )
                    }
                },
                content = tabContent,
            )
        }
    }
}

@Composable
private fun ServicesHost(session: TollCatSession) {
    val stack = session.servicesStack
    val route = stack.lastOrNull() ?: ServicesRoute.List
    TrackScreen(servicesUsageScreen(route))
    HierarchicalContent(
        targetState = route,
        depth = stack.size,
        modifier = Modifier.fillMaxSize(),
        canPop = stack.size > 1,
        onPop = { session.popServices() },
        contentKey = { it.encode() },
    ) { current ->
        when (current) {
            ServicesRoute.List -> ServicesScreen(session)
            ServicesRoute.Add -> AddProviderScreen(session, browse = AddProviderBrowse.Featured)
            ServicesRoute.AddMore -> AddProviderScreen(session, browse = AddProviderBrowse.More)
            ServicesRoute.Past -> PastServicesScreen(session)
            is ServicesRoute.Detail -> ProviderDetailScreen(session, current.providerId)
            is ServicesRoute.Setup -> SetupCredentialsScreen(
                session,
                current.providerId,
                current.accountId,
            )
        }
    }
}

private fun ServicesRoute.encode(): String {
    return when (this) {
        ServicesRoute.List -> "list"
        ServicesRoute.Add -> "add"
        ServicesRoute.AddMore -> "add-more"
        ServicesRoute.Past -> "past"
        is ServicesRoute.Detail -> "detail:$providerId"
        is ServicesRoute.Setup -> "setup:$providerId:$accountId"
    }
}
