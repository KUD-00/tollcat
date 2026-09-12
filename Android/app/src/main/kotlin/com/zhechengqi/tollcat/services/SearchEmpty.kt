package com.zhechengqi.tollcat.services

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
import com.zhechengqi.tollcat.ui.EmptyState
import com.zhechengqi.tollcat.ui.EmptyStateGlyph
import com.zhechengqi.tollcat.ui.EmptyStateSize
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SearchEmpty(query: String, modifier: Modifier = Modifier) {
    EmptyState(
        title = stringResource(R.string.services_search_empty, query),
        modifier = modifier,
        size = EmptyStateSize.Compact,
        body = stringResource(R.string.services_search_empty_hint),
        glyph = {
            EmptyStateGlyph(
                symbol = MaterialSymbol.Search,
                shape = MaterialShapes.Cookie4Sided.toShape(),
            )
        },
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SearchEmptyPreview() {
    TollCatTheme {
        SearchEmpty(query = "zzzz")
    }
}
