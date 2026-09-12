package com.zhechengqi.tollcat.settings

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

@Composable
fun ReminderDeniedRow(
    onOpenSystemSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsNavRow(
        title = stringResource(R.string.settings_reminder_open_system),
        icon = MaterialSymbol.Settings,
        semanticsLabel = stringResource(R.string.settings_reminder_open_system_hint),
        onClick = onOpenSystemSettings,
        modifier = modifier,
    )
}
