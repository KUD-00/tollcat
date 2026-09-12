package com.zhechengqi.tollcat

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ListItem
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialExpressiveTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MotionScheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.developer.DeveloperBuildDestination
import com.zhechengqi.tollcat.developer.DeveloperClockDestination
import com.zhechengqi.tollcat.developer.DeveloperDashboardLabDestination
import com.zhechengqi.tollcat.developer.DeveloperDashboardLabModuleDestination
import com.zhechengqi.tollcat.developer.DeveloperDataDestination
import com.zhechengqi.tollcat.developer.DeveloperLogDestination
import com.zhechengqi.tollcat.developer.DeveloperToolsDestination
import com.zhechengqi.tollcat.developer.DeveloperWhatsNewDestination
import com.zhechengqi.tollcat.developer.GalleryHomeDestination
import com.zhechengqi.tollcat.developer.GalleryItemDestination
import com.zhechengqi.tollcat.developer.isDebuggable
import com.zhechengqi.tollcat.settings.AboutDestination
import com.zhechengqi.tollcat.settings.AppearanceDestination
import com.zhechengqi.tollcat.settings.AppearancePreference
import com.zhechengqi.tollcat.settings.ColorSourcePreference
import com.zhechengqi.tollcat.settings.CurrencyDestination
import com.zhechengqi.tollcat.settings.DeviceTransferDestination
import com.zhechengqi.tollcat.settings.FeedbackDestination
import com.zhechengqi.tollcat.settings.InboxSettingsDestination
import com.zhechengqi.tollcat.settings.RefreshOnActivateDestination
import com.zhechengqi.tollcat.settings.ReminderDeniedRow
import com.zhechengqi.tollcat.settings.ReminderDestination
import com.zhechengqi.tollcat.settings.ReminderEnableController
import com.zhechengqi.tollcat.settings.ReminderOptInSheet
import com.zhechengqi.tollcat.settings.SettingsDeepLink
import com.zhechengqi.tollcat.settings.SettingsDestination
import com.zhechengqi.tollcat.settings.SettingsGroup
import com.zhechengqi.tollcat.settings.SettingsRowShape
import com.zhechengqi.tollcat.settings.rememberReminderEnableController
import com.zhechengqi.tollcat.settings.reminderScheduleSummary
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection
import com.zhechengqi.tollcat.settings.SettingsSwitchRow
import com.zhechengqi.tollcat.settings.SettingsToggleGroupRow
import com.zhechengqi.tollcat.settings.TipDestination
import com.zhechengqi.tollcat.settings.TipTreatKind
import com.zhechengqi.tollcat.settings.TipTreatView
import com.zhechengqi.tollcat.settings.UsageGuideArticleDestination
import com.zhechengqi.tollcat.settings.WhatsNewCatalog
import com.zhechengqi.tollcat.settings.WhatsNewEntryDestination
import com.zhechengqi.tollcat.settings.WhatsNewLaunch
import com.zhechengqi.tollcat.settings.WhatsNewListDestination
import com.zhechengqi.tollcat.settings.UsageGuideListDestination
import com.zhechengqi.tollcat.settings.appVersionCaption
import com.zhechengqi.tollcat.settings.appearanceTitle
import com.zhechengqi.tollcat.settings.currencyLabel
import com.zhechengqi.tollcat.settings.settingsRowColors
import com.zhechengqi.tollcat.ui.HierarchicalContent
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@Composable
fun SettingsScreen(session: TollCatSession, modifier: Modifier = Modifier) {
    var stack by rememberSaveable(stateSaver = SettingsDestination.Saver) {
        mutableStateOf(listOf<SettingsDestination>(SettingsDestination.Root))
    }
    var appearance by rememberSaveable { mutableStateOf(session.preferences.appearance) }
    var colorSource by rememberSaveable { mutableStateOf(session.preferences.colorSource) }
    var refreshOnActivate by rememberSaveable { mutableStateOf(session.preferences.refreshOnActivate) }
    var hidesCat by rememberSaveable { mutableStateOf(session.preferences.hidesCat) }
    var confirming by rememberSaveable { mutableStateOf(false) }
    val reminder = rememberReminderEnableController(session.preferences)
    val context = LocalContext.current
    val current = stack.lastOrNull() ?: SettingsDestination.Root
    val canPop = stack.size > 1
    val pop = {
        if (stack.size > 1) {
            stack = stack.dropLast(1)
        }
    }
    val push = { dest: SettingsDestination ->
        stack = stack + dest
    }
    TrackScreen(settingsUsageScreen(current))
    val pendingDeepLink = session.pendingSettingsDeepLink
    LaunchedEffect(pendingDeepLink) {
        val event = session.consumeSettingsDeepLink() ?: return@LaunchedEffect
        stack = SettingsDeepLink.stack(event.path)
    }
    LaunchedEffect(session.didClearAllData) {
        reminder.refresh()
    }
    SettingsAppearance(appearance) {
        HierarchicalContent(
            targetState = current,
            depth = stack.size,
            modifier = modifier.fillMaxSize(),
            canPop = canPop,
            onPop = pop,
            contentKey = { it.encode() },
        ) { dest ->
            when (dest) {
            // 打赏：Play Billing，对 iOS StoreKit 那三档。
            SettingsDestination.Tip -> TipDestination(
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Root -> SettingsRoot(
                session = session,
                appearance = appearance,
                colorSource = colorSource,
                refreshOnActivate = refreshOnActivate,
                hidesCat = hidesCat,
                reminder = reminder,
                onAppearanceSelect = { value ->
                    appearance = value
                    session.preferences.appearance = value
                    session.preferences.applyAppearance(context)
                },
                onColorSourceSelect = { value ->
                    colorSource = value
                    session.preferences.colorSource = value
                },
                onRefreshChange = { enabled ->
                    refreshOnActivate = enabled
                    session.preferences.refreshOnActivate = enabled
                },
                onHidesCatChange = { hidden ->
                    hidesCat = hidden
                    session.preferences.hidesCat = hidden
                },
                onOpen = push,
                onConfirmClear = { confirming = true },
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Appearance -> AppearanceDestination(
                selected = appearance,
                onSelect = { value ->
                    appearance = value
                    session.preferences.appearance = value
                    session.preferences.applyAppearance(context)
                },
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Currency -> CurrencyDestination(
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.RefreshOnActivate -> RefreshOnActivateDestination(
                enabled = refreshOnActivate,
                onEnabledChange = { enabled ->
                    refreshOnActivate = enabled
                    session.preferences.refreshOnActivate = enabled
                },
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.UsageGuides -> UsageGuideListDestination(
                onOpen = { id -> push(SettingsDestination.UsageGuideArticle(id)) },
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.WhatsNew -> WhatsNewListDestination(
                entries = WhatsNewLaunch.history(),
                language = MoneyDisplay.localeTag(),
                onOpen = { version -> push(SettingsDestination.WhatsNewEntryPage(version)) },
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            is SettingsDestination.WhatsNewEntryPage -> {
                val entry = WhatsNewCatalog.entries.firstOrNull { it.version == dest.version }
                if (entry == null) {
                    pop()
                } else {
                    WhatsNewEntryDestination(
                        entry = entry,
                        language = MoneyDisplay.localeTag(),
                        onBack = pop,
                        modifier = Modifier.fillMaxSize(),
                    )
                }
            }
            is SettingsDestination.UsageGuideArticle -> UsageGuideArticleDestination(
                id = dest.id,
                preferences = session.preferences,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Reminders -> ReminderDestination(
                preferences = session.preferences,
                controller = reminder,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Inbox -> InboxSettingsDestination(
                session = session,
                onBack = pop,
                onOpenManualUsage = { session.tab = AppTab.Services },
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Transfer -> DeviceTransferDestination(
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Feedback -> FeedbackDestination(
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.About -> AboutDestination(
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Developer -> DeveloperToolsDestination(
                onOpen = push,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.DeveloperClock -> DeveloperClockDestination(
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.DeveloperData -> DeveloperDataDestination(
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.DeveloperLog -> DeveloperLogDestination(
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.DeveloperBuild -> DeveloperBuildDestination(
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.DeveloperWhatsNew -> DeveloperWhatsNewDestination(
                preferences = session.preferences,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.Gallery -> GalleryHomeDestination(
                onOpen = push,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            is SettingsDestination.GalleryItem -> GalleryItemDestination(
                id = dest.id,
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            SettingsDestination.DashboardLab -> DeveloperDashboardLabDestination(
                session = session,
                onOpen = push,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
            is SettingsDestination.DashboardLabModule -> DeveloperDashboardLabModuleDestination(
                id = dest.id,
                session = session,
                onBack = pop,
                modifier = Modifier.fillMaxSize(),
            )
        }
        }
    }
    if (confirming) {
        AlertDialog(
            onDismissRequest = { confirming = false },
            title = { Text(stringResource(R.string.settings_clear_title)) },
            text = { Text(stringResource(R.string.settings_clear_body)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        session.clearAll()
                        appearance = AppearancePreference.DARK
                        colorSource = ColorSourcePreference.DYNAMIC
                        refreshOnActivate = false
                        hidesCat = true
                        reminder.refresh()
                        stack = listOf(SettingsDestination.Root)
                        confirming = false
                    },
                ) {
                    Text(
                        stringResource(R.string.settings_clear_confirm),
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { confirming = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        )
    }
    if (reminder.presentingOptIn) {
        ReminderOptInSheet(
            onAllow = reminder::confirmOptIn,
            onDecline = reminder::declineOptIn,
        )
    }
}

@Composable
private fun SettingsRoot(
    session: TollCatSession,
    appearance: String,
    colorSource: String,
    refreshOnActivate: Boolean,
    hidesCat: Boolean,
    reminder: ReminderEnableController,
    onAppearanceSelect: (String) -> Unit,
    onColorSourceSelect: (String) -> Unit,
    onRefreshChange: (Boolean) -> Unit,
    onHidesCatChange: (Boolean) -> Unit,
    onOpen: (SettingsDestination) -> Unit,
    onConfirmClear: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val version = appVersionCaption(context)
    SettingsScaffold(
        title = stringResource(R.string.tab_settings),
        onBack = null,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .testTag(UITestId.SETTINGS_LIST),
        ) {
            // 打赏单独一节置顶。糖是这一行唯一的画，和 iOS 同一颗。
            val tipSpoken = stringResource(R.string.settings_tip_open_hint)
            SettingsGroup(modifier = Modifier.padding(top = 12.dp)) {
                ListItem(
                    onClick = { onOpen(SettingsDestination.Tip) },
                    modifier = Modifier
                        .clip(SettingsRowShape)
                        .semantics { contentDescription = tipSpoken },
                    leadingContent = { TipTreatView(kind = TipTreatKind.Candy, size = 36.dp) },
                    trailingContent = {
                        SymbolIcon(MaterialSymbol.KeyboardArrowRight, contentDescription = null)
                    },
                    supportingContent = { Text(stringResource(R.string.settings_tip_hint)) },
                    colors = settingsRowColors(),
                    content = { Text(stringResource(R.string.settings_tip)) },
                )
            }
            SettingsSection(title = stringResource(R.string.settings_general)) {
                // 三个选项没必要进一层——connected 按钮组直接摆在行里。
                SettingsToggleGroupRow(
                    title = stringResource(R.string.settings_appearance),
                    icon = MaterialSymbol.DarkMode,
                    options = listOf(
                        stringResource(R.string.settings_appearance_light) to AppearancePreference.LIGHT,
                        stringResource(R.string.settings_appearance_dark) to AppearancePreference.DARK,
                        stringResource(R.string.settings_appearance_system) to AppearancePreference.SYSTEM,
                    ),
                    selected = appearance,
                    onSelect = onAppearanceSelect,
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    SettingsToggleGroupRow(
                        title = stringResource(R.string.settings_color_source),
                        icon = MaterialSymbol.Palette,
                        options = listOf(
                            stringResource(R.string.settings_color_dynamic) to ColorSourcePreference.DYNAMIC,
                            stringResource(R.string.settings_color_brand) to ColorSourcePreference.BRAND,
                        ),
                        selected = colorSource,
                        onSelect = onColorSourceSelect,
                    )
                }
                SettingsNavRow(
                    title = stringResource(R.string.settings_currency),
                    subtitle = currencyLabel(session.displayCurrency),
                    icon = MaterialSymbol.Payments,
                    semanticsLabel = stringResource(R.string.settings_currency),
                    onClick = { onOpen(SettingsDestination.Currency) },
                )
                // 一个开关也没必要进一层。
                SettingsSwitchRow(
                    title = stringResource(R.string.settings_refresh_title),
                    subtitle = stringResource(R.string.settings_refresh_note),
                    checked = refreshOnActivate,
                    onCheckedChange = onRefreshChange,
                )
                SettingsSwitchRow(
                    title = stringResource(R.string.settings_hide_cat),
                    subtitle = stringResource(R.string.settings_hide_cat_note),
                    checked = !hidesCat,
                    onCheckedChange = { onHidesCatChange(!it) },
                    modifier = Modifier.testTag(UITestId.SETTINGS_HIDE_CAT),
                )
                SettingsNavRow(
                    title = stringResource(R.string.settings_usage_guides),
                    subtitle = stringResource(R.string.settings_usage_guides_hint),
                    icon = MaterialSymbol.MenuBook,
                    semanticsLabel = stringResource(R.string.settings_usage_guides),
                    onClick = { onOpen(SettingsDestination.UsageGuides) },
                )
                SettingsNavRow(
                    title = stringResource(R.string.settings_whats_new),
                    subtitle = stringResource(R.string.settings_whats_new_hint),
                    icon = MaterialSymbol.MenuBook,
                    semanticsLabel = stringResource(R.string.settings_whats_new),
                    onClick = { onOpen(SettingsDestination.WhatsNew) },
                )
            }
            SettingsSection(title = stringResource(R.string.settings_reminder)) {
                // 开关就地拨，只有频率/时间这类细节才进层。
                SettingsSwitchRow(
                    title = stringResource(R.string.settings_reminder),
                    subtitle = if (reminder.showsDenied) {
                        stringResource(R.string.settings_reminder_denied)
                    } else {
                        stringResource(R.string.settings_reminder_note)
                    },
                    checked = reminder.enabled,
                    onCheckedChange = reminder::onToggle,
                )
                if (reminder.showsDenied) {
                    ReminderDeniedRow(onOpenSystemSettings = reminder::openSystemNotificationSettings)
                }
                if (reminder.enabled) {
                    SettingsNavRow(
                        title = stringResource(R.string.settings_reminder_detail),
                        subtitle = reminderScheduleSummary(session.preferences),
                        icon = MaterialSymbol.Notifications,
                        semanticsLabel = stringResource(R.string.settings_reminder_detail),
                        onClick = { onOpen(SettingsDestination.Reminders) },
                    )
                }
            }
            SettingsSection(title = stringResource(R.string.settings_data)) {
                SettingsNavRow(
                    title = stringResource(R.string.settings_inbox),
                    subtitle = stringResource(R.string.settings_inbox_hint),
                    icon = MaterialSymbol.Inbox,
                    semanticsLabel = stringResource(R.string.settings_inbox),
                    onClick = { onOpen(SettingsDestination.Inbox) },
                )
                SettingsNavRow(
                    title = stringResource(R.string.settings_transfer),
                    subtitle = stringResource(R.string.settings_transfer_hint),
                    icon = MaterialSymbol.SwapHoriz,
                    semanticsLabel = stringResource(R.string.settings_transfer),
                    onClick = { onOpen(SettingsDestination.Transfer) },
                )
            }
            SettingsSection(title = stringResource(R.string.settings_other)) {
                SettingsNavRow(
                    title = stringResource(R.string.settings_feedback),
                    subtitle = stringResource(R.string.settings_feedback_hint),
                    icon = MaterialSymbol.Mail,
                    semanticsLabel = stringResource(R.string.settings_feedback),
                    onClick = { onOpen(SettingsDestination.Feedback) },
                )
                SettingsNavRow(
                    title = stringResource(R.string.settings_about),
                    subtitle = version,
                    icon = MaterialSymbol.Info,
                    semanticsLabel = stringResource(R.string.settings_about),
                    onClick = { onOpen(SettingsDestination.About) },
                )
                if (isDebuggable(context)) {
                    SettingsNavRow(
                        title = stringResource(R.string.dev_title),
                        subtitle = stringResource(R.string.dev_hint),
                        icon = MaterialSymbol.Code,
                        semanticsLabel = stringResource(R.string.dev_title),
                        onClick = { onOpen(SettingsDestination.Developer) },
                    )
                }
            }
            SettingsSection(title = stringResource(R.string.settings_danger)) {
                SettingsNavRow(
                    title = stringResource(R.string.settings_clear),
                    subtitle = stringResource(R.string.settings_clear_hint),
                    icon = MaterialSymbol.DeleteForever,
                    semanticsLabel = stringResource(R.string.settings_clear),
                    headlineColor = MaterialTheme.colorScheme.error,
                    showChevron = false,
                    onClick = onConfirmClear,
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun SettingsAppearance(appearance: String, content: @Composable () -> Unit) {
    val systemDark = isSystemInDarkTheme()
    val dark = when (appearance) {
        AppearancePreference.DARK -> true
        AppearancePreference.LIGHT -> false
        else -> systemDark
    }
    val colorScheme = tollCatColorScheme(dark)
    ProvideTollCatColors(colorScheme) {
        MaterialExpressiveTheme(
            colorScheme = colorScheme,
            motionScheme = MotionScheme.expressive(),
            shapes = MaterialTheme.shapes,
            typography = MaterialTheme.typography,
            content = content,
        )
    }
}
