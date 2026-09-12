package com.zhechengqi.tollcat.developer

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.settings.SettingsScaffold

@Composable
fun DeveloperDashboardLabModuleDestination(
    id: String,
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    DeveloperDashboardLabModulePage(
        id = id,
        live = session.dashboard,
        onBack = onBack,
        modifier = modifier,
    )
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun DeveloperDashboardLabModulePage(
    id: String,
    live: DashboardSnapshot,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val title = stringResource(DashboardLabModules.titleRes(id))
    val liveHas = DashboardLabModules.has(live, id)
    val preferLive = !live.empty && liveHas
    // 当前账本非空且这块有数就先看真数；缺了才用设计稿。
    var source by remember(id) {
        mutableStateOf(if (preferLive) DashboardLabDataSource.Live else DashboardLabDataSource.Fixture)
    }
    val dashboard = when (source) {
        DashboardLabDataSource.Live -> live
        DashboardLabDataSource.Fixture -> DashboardLabFixtures.contents
    }
    val showsEmpty = source == DashboardLabDataSource.Live && !liveHas
    SettingsScaffold(title = title, onBack = onBack, modifier = modifier) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(top = 8.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                stringResource(DashboardLabModules.summaryRes(id)),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (DashboardLabModules.isRetired(id)) {
                Text(
                    stringResource(R.string.dev_lab_retired_note),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.tertiary,
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    stringResource(R.string.dev_data),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween),
                ) {
                    DashboardLabDataSource.entries.forEachIndexed { index, item ->
                        ToggleButton(
                            checked = source == item,
                            onCheckedChange = { checked -> if (checked) source = item },
                            modifier = Modifier.weight(1f),
                            shapes = when (index) {
                                0 -> ButtonGroupDefaults.connectedLeadingButtonShapes()
                                else -> ButtonGroupDefaults.connectedTrailingButtonShapes()
                            },
                        ) {
                            Text(stringResource(item.titleRes), maxLines = 1)
                        }
                    }
                }
            }
            if (source == DashboardLabDataSource.Fixture && !liveHas) {
                Text(
                    stringResource(R.string.dev_lab_using_fixture),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            if (showsEmpty) {
                Text(
                    stringResource(R.string.dev_lab_empty),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 24.dp),
                )
            } else {
                DeveloperDashboardLabSamples(id = id, dashboard = dashboard)
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DeveloperDashboardLabModuleDestinationPreview() {
    TollCatTheme {
        DeveloperDashboardLabModulePage(
            id = DashboardLabModules.MONTH_TO_DATE,
            live = DashboardSnapshot.vacant,
            onBack = {},
        )
    }
}

@Preview(name = "Live Light", showBackground = true)
@Preview(name = "Live Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DeveloperDashboardLabModuleDestinationLivePreview() {
    TollCatTheme {
        DeveloperDashboardLabModulePage(
            id = DashboardLabModules.MONTH_TO_DATE,
            live = DashboardLabFixtures.contents,
            onBack = {},
        )
    }
}
