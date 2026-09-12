package com.zhechengqi.tollcat.settings

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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.R

@Composable
fun UsageGuideListDestination(
    onOpen: (String) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = stringResource(R.string.settings_usage_guides),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsSection(title = stringResource(R.string.settings_money_kinds)) {
                UsageGuides.money.forEach { guide ->
                    SettingsNavRow(
                        title = stringResource(guide.title),
                        onClick = { onOpen(guide.id) },
                        semanticsLabel = stringResource(R.string.settings_guide_open_hint),
                    )
                }
            }
            SettingsSection(title = stringResource(R.string.settings_usage_guides)) {
                UsageGuides.product.forEach { guide ->
                    SettingsNavRow(
                        title = stringResource(guide.title),
                        onClick = { onOpen(guide.id) },
                        semanticsLabel = stringResource(R.string.settings_guide_open_hint),
                    )
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
fun UsageGuideArticleDestination(
    id: String,
    preferences: PreferencesStore,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val guide = UsageGuides.find(id)
    LaunchedEffect(id) {
        preferences.markUsageGuideSeen(id)
    }
    SettingsScaffold(
        title = if (guide == null) stringResource(R.string.settings_usage_guides) else stringResource(guide.title),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (guide != null) {
                Text(
                    text = stringResource(guide.body),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}
