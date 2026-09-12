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

@Composable
fun GalleryHomeDestination(
    onOpen: (SettingsDestination) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = stringResource(R.string.dev_gallery),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            GallerySection.entries.forEach { section ->
                SettingsSection(title = stringResource(section.titleRes)) {
                    section.items.forEach { item ->
                        SettingsNavRow(
                            title = stringResource(item.titleRes),
                            onClick = { onOpen(SettingsDestination.GalleryItem(item.raw)) },
                        )
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}
