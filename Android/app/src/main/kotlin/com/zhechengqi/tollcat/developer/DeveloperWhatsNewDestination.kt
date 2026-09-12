package com.zhechengqi.tollcat.developer

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
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection
import com.zhechengqi.tollcat.settings.SettingsValueRow
import com.zhechengqi.tollcat.settings.WhatsNewEntry
import com.zhechengqi.tollcat.settings.WhatsNewLaunch
import com.zhechengqi.tollcat.settings.WhatsNewSheet
import com.zhechengqi.tollcat.settings.appVersionShort

/**
 * 更新说明弹出面的试验台。和 iOS 的 `DeveloperWhatsNewView` 是同一份东西。
 *
 * 弹出面一年只有几次机会自己出现（更新后第一次冷启动），而模拟器 / 测试机上的
 * 库永远是新装的——判据永远不成立。所以真正能验收的方式是**改写「看到哪一版」**，
 * 让真判据成立，而不是找个后门强行弹一张。
 */
@Composable
fun DeveloperWhatsNewDestination(
    preferences: PreferencesStore,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val current = remember { appVersionShort(context) }
    val language = MoneyDisplay.localeTag()
    var lastSeen by remember { mutableStateOf(preferences.lastSeenWhatsNewVersion) }
    var presented by remember { mutableStateOf<List<WhatsNewEntry>>(emptyList()) }
    var note by remember { mutableStateOf<String?>(null) }

    val history = WhatsNewLaunch.history()
    // 和 TollCatApp 里那次调用同一个入口，参数也一样。
    val pending = WhatsNewLaunch.pending(
        currentVersion = current,
        lastSeenVersion = lastSeen,
        hasCompletedOnboarding = true,
        completedOnboardingThisLaunch = false,
        skipSheet = false,
    )

    fun write(version: String) {
        preferences.lastSeenWhatsNewVersion = version
        lastSeen = version
        note = null
    }

    SettingsScaffold(
        title = stringResource(R.string.settings_whats_new),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsSection(title = stringResource(R.string.dev_whats_new_state)) {
                SettingsValueRow(
                    title = stringResource(R.string.dev_whats_new_build),
                    value = current,
                )
                SettingsValueRow(
                    title = stringResource(R.string.dev_whats_new_seen),
                    value = lastSeen.ifEmpty { stringResource(R.string.dev_whats_new_never) },
                )
                SettingsValueRow(
                    title = stringResource(R.string.dev_whats_new_would_show),
                    value = if (pending.isEmpty()) {
                        stringResource(R.string.dev_whats_new_nothing)
                    } else {
                        pending.joinToString(" · ") { it.version }
                    },
                )
                SettingsValueRow(
                    title = stringResource(R.string.dev_whats_new_count),
                    value = history.size.toString(),
                )
            }
            SettingsSection(title = stringResource(R.string.dev_whats_new_rewrite)) {
                SettingsNavRow(
                    title = stringResource(R.string.dev_whats_new_clear),
                    onClick = { write("") },
                    showChevron = false,
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_whats_new_zero),
                    onClick = { write("0.0.0") },
                    showChevron = false,
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_whats_new_set_current),
                    onClick = { write(current) },
                    showChevron = false,
                )
            }
            SettingsSection(title = stringResource(R.string.dev_whats_new_fire)) {
                SettingsNavRow(
                    title = stringResource(R.string.dev_whats_new_fire_real),
                    onClick = {
                        if (pending.isEmpty()) {
                            note = context.getString(R.string.dev_whats_new_quiet)
                        } else {
                            presented = pending
                        }
                    },
                    showChevron = false,
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_whats_new_fire_data),
                    onClick = {
                        if (history.isEmpty()) {
                            note = context.getString(R.string.dev_whats_new_empty_catalog)
                        } else {
                            presented = history.take(1)
                        }
                    },
                    showChevron = false,
                )
            }
            note?.let { message ->
                Spacer(Modifier.height(12.dp))
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 32.dp),
                )
            }
            Spacer(Modifier.height(12.dp))
            Text(
                text = stringResource(R.string.dev_whats_new_footer),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp),
            )
            Spacer(Modifier.height(24.dp))
        }
    }

    if (presented.isNotEmpty()) {
        WhatsNewSheet(
            entries = presented,
            language = language,
            onDismiss = {
                presented = emptyList()
                // 和线上一样：关掉面板就把「看到哪一版」推到当前版本。
                preferences.lastSeenWhatsNewVersion = WhatsNewLaunch.advanced(
                    lastSeenVersion = preferences.lastSeenWhatsNewVersion,
                    currentVersion = current,
                )
                lastSeen = preferences.lastSeenWhatsNewVersion
            },
        )
    }
}
