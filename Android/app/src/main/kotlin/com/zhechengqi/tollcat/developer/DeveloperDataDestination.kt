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
import com.zhechengqi.tollcat.settings.SettingsSwitchRow
import com.zhechengqi.tollcat.ui.OnboardingPreferences

@Composable
fun DeveloperDataDestination(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val onboarding = remember { OnboardingPreferences(context) }
    var demoEnabled by remember { mutableStateOf(session.preferences.isDemoModeEnabled) }
    var caption by remember { mutableStateOf<String?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    val notEmpty = stringResource(R.string.dev_seed_not_empty)
    val seedFailed = stringResource(R.string.dev_seed_failed)
    val seeded = stringResource(R.string.dev_seed_ok)
    val cleared = stringResource(R.string.dev_cleared)
    val exported = stringResource(R.string.dev_exported, session.ledger.snapshots().size)
    SettingsScaffold(
        title = stringResource(R.string.dev_data_ops),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsSection(title = stringResource(R.string.dev_data)) {
                SettingsSwitchRow(
                    title = stringResource(R.string.dev_demo_mode),
                    subtitle = stringResource(R.string.dev_demo_mode_hint),
                    checked = demoEnabled,
                    onCheckedChange = { enabled ->
                        demoEnabled = enabled
                        session.preferences.isDemoModeEnabled = enabled
                        if (enabled) {
                            when (session.seedDemo()) {
                                DemoSeeder.Result.Seeded -> {
                                    error = null
                                    caption = seeded
                                }
                                DemoSeeder.Result.NotEmpty -> {
                                    error = notEmpty
                                    caption = null
                                }
                                is DemoSeeder.Result.Failed -> {
                                    error = seedFailed
                                    caption = null
                                }
                            }
                        }
                    },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_seed),
                    showChevron = false,
                    onClick = {
                        when (session.seedDemo()) {
                            DemoSeeder.Result.Seeded -> {
                                demoEnabled = true
                                error = null
                                caption = seeded
                            }
                            DemoSeeder.Result.NotEmpty -> {
                                error = notEmpty
                                caption = null
                            }
                            is DemoSeeder.Result.Failed -> {
                                error = seedFailed
                                caption = null
                            }
                        }
                    },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_clear),
                    showChevron = false,
                    headlineColor = MaterialTheme.colorScheme.error,
                    onClick = {
                        session.clearAll()
                        demoEnabled = false
                        error = null
                        caption = cleared
                    },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_export),
                    showChevron = false,
                    onClick = {
                        val dump = session.storeDump()
                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        clipboard.setPrimaryClip(ClipData.newPlainText("tollcat-store", dump))
                        android.util.Log.i("TollCat", dump)
                        caption = exported
                        error = null
                        DeveloperDebugLog.record("store", "exported ${session.ledger.snapshots().size} snapshots")
                    },
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
            error?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
                )
            }
            Text(
                text = stringResource(R.string.dev_data_footer),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 8.dp),
            )
            SettingsSection(title = stringResource(R.string.dev_cat)) {
                SettingsNavRow(
                    title = stringResource(R.string.dev_replay_onboarding),
                    showChevron = false,
                    onClick = { onboarding.reset() },
                )
                SettingsNavRow(
                    title = stringResource(R.string.dev_reset_guides),
                    showChevron = false,
                    onClick = { session.preferences.clearSeenUsageGuides() },
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}
