package com.zhechengqi.tollcat.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.OverflowButtonGroup

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AppearanceDestination(
    selected: String,
    onSelect: (String) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val light = stringResource(R.string.settings_appearance_light)
    val dark = stringResource(R.string.settings_appearance_dark)
    val system = stringResource(R.string.settings_appearance_system)
    SettingsScaffold(
        title = stringResource(R.string.settings_appearance),
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
                OverflowButtonGroup(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                ) {
                    toggleableItem(
                        checked = selected == AppearancePreference.LIGHT,
                        label = light,
                        onCheckedChange = { checked ->
                            if (checked) onSelect(AppearancePreference.LIGHT)
                        },
                    )
                    toggleableItem(
                        checked = selected == AppearancePreference.DARK,
                        label = dark,
                        onCheckedChange = { checked ->
                            if (checked) onSelect(AppearancePreference.DARK)
                        },
                    )
                    toggleableItem(
                        checked = selected == AppearancePreference.SYSTEM,
                        label = system,
                        onCheckedChange = { checked ->
                            if (checked) onSelect(AppearancePreference.SYSTEM)
                        },
                    )
                }
            }
            Text(
                text = stringResource(R.string.settings_appearance_hint),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
            )
        }
    }
}

@Composable
fun appearanceTitle(value: String): String {
    return when (value) {
        AppearancePreference.LIGHT -> stringResource(R.string.settings_appearance_light)
        AppearancePreference.DARK -> stringResource(R.string.settings_appearance_dark)
        else -> stringResource(R.string.settings_appearance_system)
    }
}
