package com.zhechengqi.tollcat.developer

import android.content.res.Configuration
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.settings.SettingsDestination
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection

@Composable
fun DeveloperDashboardLabDestination(
    session: TollCatSession,
    onOpen: (SettingsDestination) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    DeveloperDashboardLabIndex(
        dashboard = session.dashboard,
        onOpen = onOpen,
        onBack = onBack,
        modifier = modifier,
    )
}

@Composable
private fun DeveloperDashboardLabIndex(
    dashboard: DashboardSnapshot,
    onOpen: (SettingsDestination) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = stringResource(R.string.dev_dashboard_lab),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            DashboardLabSection.entries.forEach { section ->
                SettingsSection(title = stringResource(section.titleRes)) {
                    section.ids.forEach { id ->
                        SettingsNavRow(
                            title = stringResource(DashboardLabModules.titleRes(id)),
                            subtitle = stringResource(statusRes(id, dashboard)),
                            onClick = { onOpen(SettingsDestination.DashboardLabModule(id)) },
                        )
                    }
                }
                if (section == DashboardLabSection.Hero) {
                    Text(
                        stringResource(R.string.dev_dashboard_lab_footer),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
                    )
                }
            }
        }
    }
}

private fun statusRes(id: String, dashboard: DashboardSnapshot): Int = when {
    DashboardLabModules.isRetired(id) -> R.string.dev_lab_retired
    DashboardLabModules.has(dashboard, id) -> R.string.dev_lab_has_data
    else -> R.string.dev_lab_no_data
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DeveloperDashboardLabDestinationPreview() {
    TollCatTheme {
        DeveloperDashboardLabIndex(
            dashboard = DashboardSnapshot.vacant,
            onOpen = {},
            onBack = {},
        )
    }
}
