package com.zhechengqi.tollcat.developer

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection

@Composable
fun DeveloperLogDestination(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    var caption by remember { mutableStateOf<String?>(null) }
    var logRevision by remember { mutableStateOf(0) }
    val exchanges = remember(session.lastRefreshSummary, session.dataRevision, logRevision) {
        DeveloperDebugLog.exchanges()
    }
    SettingsScaffold(
        title = stringResource(R.string.dev_log),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsSection(title = stringResource(R.string.dev_log)) {
                SettingsNavRow(
                    title = stringResource(R.string.dev_copy_logs),
                    showChevron = false,
                    onClick = {
                        val text = DeveloperDebugLog.exportText(
                            storeDump = session.storeDump(),
                            lastRefresh = session.lastRefreshSummary.ifBlank { null },
                        )
                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        clipboard.setPrimaryClip(ClipData.newPlainText("tollcat-log", text))
                        caption = context.getString(R.string.dev_copied_logs)
                    },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_refresh_all),
                    showChevron = false,
                    onClick = { session.refreshAll() },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_clear_logs),
                    showChevron = false,
                    headlineColor = MaterialTheme.colorScheme.error,
                    onClick = {
                        DeveloperDebugLog.clear()
                        caption = null
                        logRevision += 1
                    },
                )
            }
            if (session.lastRefreshSummary.isNotBlank()) {
                Text(
                    text = session.lastRefreshSummary,
                    style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
                )
            }
            caption?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
                )
            }
            Text(
                text = stringResource(R.string.dev_log_footer),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
            )
            if (exchanges.isEmpty()) {
                Text(
                    text = stringResource(R.string.dev_log_empty),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
                )
            } else {
                SettingsSection(title = stringResource(R.string.dev_http)) {
                    exchanges.asReversed().forEach { exchange ->
                        Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                            Text(
                                text = exchange.summary,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Text(
                                text = exchange.body.ifBlank { stringResource(R.string.dev_empty_body) },
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.padding(top = 8.dp),
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}
