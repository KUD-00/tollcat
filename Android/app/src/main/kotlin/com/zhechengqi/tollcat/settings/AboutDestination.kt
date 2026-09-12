package com.zhechengqi.tollcat.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringArrayResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@Composable
fun AboutDestination(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    val version = remember { appVersionCaption(context) }
    val hosts = stringArrayResource(R.array.settings_outbound_hosts)
    val purposes = stringArrayResource(R.array.settings_outbound_purposes)
    val rows = remember(hosts, purposes) {
        hosts.indices.map { index ->
            hosts[index] to purposes.getOrElse(index) { "" }
        }
    }
    SettingsScaffold(
        title = stringResource(R.string.settings_about),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        LazyColumn(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize(),
        ) {
            item {
                SettingsGroup(modifier = Modifier.padding(top = 12.dp)) {
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.settings_about_version)) },
                        trailingContent = {
                            Text(
                                text = version,
                                style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        },
                        modifier = Modifier.clip(SettingsRowShape),
                        colors = settingsRowColors(),
                    )
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.settings_about_license)) },
                        trailingContent = {
                            Text(
                                text = stringResource(R.string.settings_about_license_value),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        },
                        modifier = Modifier.clip(SettingsRowShape),
                        colors = settingsRowColors(),
                    )
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.settings_about_source)) },
                        trailingContent = {
                            SymbolIcon(
                                MaterialSymbol.OpenInNew,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        },
                        modifier = Modifier
                            .clip(SettingsRowShape)
                            .clickable { uriHandler.openUri(LegalURL.SOURCE) },
                        colors = settingsRowColors(),
                    )
                }
                Text(
                    text = stringResource(R.string.settings_about_footer),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
                )
            }
            item {
                SettingsGroup {
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.settings_about_privacy)) },
                        trailingContent = {
                            SymbolIcon(
                                MaterialSymbol.OpenInNew,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        },
                        modifier = Modifier
                            .clip(SettingsRowShape)
                            .clickable { uriHandler.openUri(LegalURL.privacy()) },
                        colors = settingsRowColors(),
                    )
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.settings_about_support)) },
                        trailingContent = {
                            SymbolIcon(
                                MaterialSymbol.OpenInNew,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        },
                        modifier = Modifier
                            .clip(SettingsRowShape)
                            .clickable { uriHandler.openUri(LegalURL.support()) },
                        colors = settingsRowColors(),
                    )
                }
            }
            item {
                Text(
                    text = stringResource(R.string.settings_outbound_header),
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(start = 32.dp, end = 16.dp, top = 12.dp, bottom = 8.dp),
                )
            }
            item {
                SettingsGroup {
                    rows.forEach { (host, purpose) ->
                        ListItem(
                            headlineContent = { Text(host) },
                            supportingContent = {
                                if (purpose.isNotBlank()) {
                                    Text(purpose)
                                }
                            },
                            modifier = Modifier.clip(SettingsRowShape),
                            colors = settingsRowColors(),
                        )
                    }
                }
            }
            item {
                Text(
                    text = stringResource(R.string.settings_outbound_footer),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}
