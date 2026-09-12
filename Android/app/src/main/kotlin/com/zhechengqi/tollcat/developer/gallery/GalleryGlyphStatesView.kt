package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.services.ServiceGlyph

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun GalleryGlyphStatesView(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    GalleryScaffold(
        title = stringResource(R.string.dev_gallery_glyphs),
        onBack = onBack,
        modifier = modifier,
    ) {
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            session.catalog.providers.forEach { provider ->
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    ServiceGlyph(
                        name = provider.displayName,
                        colorKey = provider.colorKey.ifBlank { provider.id },
                    )
                    Text(
                        text = provider.displayName,
                        style = MaterialTheme.typography.labelSmall,
                    )
                }
            }
        }
    }
}
