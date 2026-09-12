package com.zhechengqi.tollcat.developer

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.settings.SettingsDestination
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

private data class DeveloperTool(
    val destination: SettingsDestination,
    val title: Int,
    val icon: MaterialSymbol,
)

@Composable
fun DeveloperToolsDestination(
    onOpen: (SettingsDestination) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = stringResource(R.string.dev_title),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsSection(title = stringResource(R.string.dev_gallery)) {
                SettingsNavRow(
                    title = stringResource(R.string.dev_gallery),
                    icon = MaterialSymbol.GridView,
                    semanticsLabel = stringResource(R.string.dev_gallery),
                    onClick = { onOpen(SettingsDestination.Gallery) },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_dashboard_lab),
                    icon = MaterialSymbol.Widgets,
                    semanticsLabel = stringResource(R.string.dev_dashboard_lab),
                    onClick = { onOpen(SettingsDestination.DashboardLab) },
                )
            }
            SettingsSection(title = stringResource(R.string.dev_runtime)) {
                toolRow(
                    DeveloperTool(
                        SettingsDestination.DeveloperClock,
                        R.string.dev_clock,
                        MaterialSymbol.CalendarMonth,
                    ),
                    onOpen,
                )
                toolRow(
                    DeveloperTool(
                        SettingsDestination.DeveloperWhatsNew,
                        R.string.settings_whats_new,
                        MaterialSymbol.MenuBook,
                    ),
                    onOpen,
                )
            }
            SettingsSection(title = stringResource(R.string.dev_data)) {
                toolRow(
                    DeveloperTool(
                        SettingsDestination.DeveloperData,
                        R.string.dev_data_ops,
                        MaterialSymbol.Storage,
                    ),
                    onOpen,
                )
                toolRow(
                    DeveloperTool(
                        SettingsDestination.DeveloperLog,
                        R.string.dev_log,
                        MaterialSymbol.ListAlt,
                    ),
                    onOpen,
                )
            }
            SettingsSection(title = stringResource(R.string.dev_build)) {
                toolRow(
                    DeveloperTool(
                        SettingsDestination.DeveloperBuild,
                        R.string.dev_build_info,
                        MaterialSymbol.Info,
                    ),
                    onOpen,
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun toolRow(tool: DeveloperTool, onOpen: (SettingsDestination) -> Unit) {
    SettingsNavRow(
        title = stringResource(tool.title),
        icon = tool.icon,
        semanticsLabel = stringResource(tool.title),
        onClick = { onOpen(tool.destination) },
    )
}
