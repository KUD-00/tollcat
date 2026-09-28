package com.zhechengqi.tollcat

import android.content.res.Configuration
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.NavigationItemIconPosition
import androidx.compose.material3.ShortNavigationBar
import androidx.compose.material3.ShortNavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 手机上的底栏（画布 R3-1）：M3 Expressive 短导航栏，图标和文字横排、选中那项是一颗药丸。
 * 官方默认在紧凑宽度下是图标在上、文字在下；这里按设计稿横排，底栏更矮、内容多露一行。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AppShortNavigationBar(
    tab: AppTab,
    onSelect: (AppTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    ShortNavigationBar(modifier = modifier) {
        AppShortNavigationItems(tab = tab, onSelect = onSelect)
    }
}

/** 只有三个项目、不带底栏容器：交给 NavigationSuiteScaffold 的 navigationItems 槽，它自己画栏。 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AppShortNavigationItems(tab: AppTab, onSelect: (AppTab) -> Unit) {
    AppTab.entries.forEach { entry ->
        val label = stringResource(entry.labelRes)
        ShortNavigationBarItem(
            selected = tab == entry,
            onClick = { onSelect(entry) },
            icon = { SymbolIcon(entry.symbol, contentDescription = null, filled = tab == entry) },
            label = { Text(label) },
            iconPosition = NavigationItemIconPosition.Start,
            modifier = Modifier
                .semantics { contentDescription = label }
                .testTag(entry.testTag),
        )
    }
}

internal val AppTab.labelRes: Int
    get() = when (this) {
        AppTab.Dashboard -> R.string.tab_dashboard
        AppTab.Services -> R.string.tab_services
        AppTab.Settings -> R.string.tab_settings
    }

internal val AppTab.symbol: MaterialSymbol
    get() = when (this) {
        AppTab.Dashboard -> MaterialSymbol.Speed
        AppTab.Services -> MaterialSymbol.Widgets
        AppTab.Settings -> MaterialSymbol.Settings
    }

internal val AppTab.testTag: String
    get() = when (this) {
        AppTab.Dashboard -> UITestId.TAB_DASHBOARD
        AppTab.Services -> UITestId.TAB_SERVICES
        AppTab.Settings -> UITestId.TAB_SETTINGS
    }

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun AppShortNavigationBarPreview() {
    TollCatTheme {
        AppShortNavigationBar(tab = AppTab.Dashboard, onSelect = {})
    }
}
