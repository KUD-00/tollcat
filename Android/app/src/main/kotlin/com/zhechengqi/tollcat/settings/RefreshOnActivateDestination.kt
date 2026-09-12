package com.zhechengqi.tollcat.settings

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
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R

@Composable
fun RefreshOnActivateDestination(
    enabled: Boolean,
    onEnabledChange: (Boolean) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = stringResource(R.string.settings_refresh_title),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsGroup(modifier = Modifier.padding(top = 8.dp)) {
                SettingsSwitchRow(
                    title = stringResource(R.string.settings_refresh_title),
                    subtitle = stringResource(R.string.settings_refresh_note),
                    checked = enabled,
                    onCheckedChange = onEnabledChange,
                )
            }
            Text(
                text = stringResource(R.string.settings_refresh_hint),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
            )
        }
    }
}
