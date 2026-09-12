package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.DashboardEmptyView
import com.zhechengqi.tollcat.services.SearchEmpty
import com.zhechengqi.tollcat.services.ServicesEmpty
import com.zhechengqi.tollcat.ui.EmptyState
import com.zhechengqi.tollcat.ui.EmptyStateGlyph
import com.zhechengqi.tollcat.ui.EmptyStateSize
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun GalleryEmptyStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(title = stringResource(R.string.dev_gallery_empty), onBack = onBack, modifier = modifier) {
        GalleryExhibit(stringResource(R.string.tab_dashboard)) {
            DashboardEmptyView(onAdd = {})
        }
        GalleryExhibit(stringResource(R.string.tab_services)) {
            ServicesEmpty(onAdd = {})
        }
        GalleryExhibit(stringResource(R.string.settings_inbox)) {
            EmptyState(
                title = stringResource(R.string.settings_inbox_empty_title),
                size = EmptyStateSize.Compact,
                body = stringResource(R.string.settings_inbox_empty_body),
                glyph = {
                    EmptyStateGlyph(
                        symbol = MaterialSymbol.Inbox,
                        shape = MaterialShapes.ClamShell.toShape(),
                    )
                },
            )
        }
        GalleryExhibit(stringResource(R.string.dev_gallery_search_empty)) {
            SearchEmpty(query = "zzzz")
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryEmptyStatesViewPreview() {
    TollCatTheme {
        GalleryEmptyStatesView(onBack = {})
    }
}
