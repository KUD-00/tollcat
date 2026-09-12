package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection
import com.zhechengqi.tollcat.settings.UsageGuideArticleDestination
import com.zhechengqi.tollcat.settings.UsageGuides

@Composable
fun GalleryUsageGuidesView(
    preferences: PreferencesStore,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var article by remember { mutableStateOf<String?>(null) }
    val id = article
    if (id != null) {
        UsageGuideArticleDestination(
            id = id,
            preferences = preferences,
            onBack = { article = null },
            modifier = modifier,
        )
        return
    }
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
                        onClick = { article = guide.id },
                    )
                }
            }
            SettingsSection(title = stringResource(R.string.settings_usage_guides)) {
                UsageGuides.product.forEach { guide ->
                    SettingsNavRow(
                        title = stringResource(guide.title),
                        onClick = { article = guide.id },
                    )
                }
            }
        }
    }
}
