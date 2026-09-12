package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SetupGuideDoc
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.services.SearchEmpty
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.services.categoryTitleRes
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.HierarchicalContent
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.bentoRowColors
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 接入向导画廊：按类别浏览各家教程，点进去看和向导同一份 [com.zhechengqi.tollcat.setup.SetupGuideStep]。
 */
@Composable
fun GallerySetupGuidesView(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var selected by remember { mutableStateOf<CatalogProvider?>(null) }
    val guides = remember(session.catalog) {
        session.catalog.providers.associate { it.id to session.setupGuide(it.id) }
    }
    HierarchicalContent(
        targetState = selected,
        depth = if (selected == null) 0 else 1,
        modifier = modifier.fillMaxSize(),
        canPop = selected != null,
        onPop = { selected = null },
        contentKey = { it?.id ?: "list" },
    ) { provider ->
        if (provider == null) {
            GallerySetupGuideList(
                providers = session.catalog.providers,
                categoryOrder = session.catalog.categoryOrder,
                guides = guides,
                onBack = onBack,
                onSelect = { selected = it },
            )
        } else {
            GallerySetupGuideDetailView(
                provider = provider,
                guide = guides[provider.id],
                onBack = { selected = null },
            )
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun GallerySetupGuideList(
    providers: List<CatalogProvider>,
    categoryOrder: List<String>,
    guides: Map<String, SetupGuideDoc?>,
    onBack: () -> Unit,
    onSelect: (CatalogProvider) -> Unit,
    modifier: Modifier = Modifier,
) {
    var query by rememberSaveable { mutableStateOf("") }
    val needle = query.trim()
    val visible = remember(providers, needle) {
        providers.filter { provider -> matchesGuideQuery(provider, needle) }
    }
    val order = categoryOrder.ifEmpty { visible.map { it.category }.distinct() }
    val grouped = order.mapNotNull { category ->
        val rows = visible.filter { it.category == category }
        if (rows.isEmpty()) null else category to rows
    }
    val showTitles = grouped.size > 1
    val emptySearch = needle.isNotEmpty() && visible.isEmpty()

    SettingsScaffold(
        title = stringResource(R.string.dev_gallery_setup),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize(),
        ) {
            TextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                singleLine = true,
                placeholder = { Text(stringResource(R.string.search_providers)) },
                leadingIcon = { SymbolIcon(MaterialSymbol.Search, contentDescription = null) },
                shape = SearchBarDefaults.inputFieldShape,
                colors = TextFieldDefaults.colors(
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    disabledIndicatorColor = Color.Transparent,
                    focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
                ),
            )
            if (emptySearch) {
                SearchEmpty(query = query, modifier = Modifier.fillMaxSize())
            } else {
                val reduceMotion = LocalReduceMotion.current
                val itemPlacement = MaterialTheme.motionScheme.defaultSpatialSpec<IntOffset>()
                    .takeUnless { reduceMotion }
                val itemFade = MaterialTheme.motionScheme.fastEffectsSpec<Float>()
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(Bento.gap),
                ) {
                    grouped.forEach { (category, rows) ->
                        if (showTitles) {
                            item(key = "header-$category") {
                                Text(
                                    text = stringResource(categoryTitleRes(category)),
                                    style = MaterialTheme.typography.titleMediumEmphasized,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier
                                        .animateItem(
                                            fadeInSpec = itemFade,
                                            placementSpec = itemPlacement,
                                            fadeOutSpec = itemFade,
                                        )
                                        .padding(start = 4.dp, top = 13.dp, bottom = 5.dp),
                                )
                            }
                        }
                        itemsIndexed(rows, key = { _, item -> item.id }) { index, item ->
                            val missing = guides[item.id] == null
                            val subtitle = when {
                                item.accessStatus == "declined" && item.declineReason.isNotBlank() ->
                                    item.declineReason
                                missing -> stringResource(R.string.services_setup_guide_missing)
                                else -> null
                            }
                            ListItem(
                                onClick = { onSelect(item) },
                                leadingContent = {
                                    ServiceGlyph(
                                        name = item.displayName,
                                        colorKey = item.colorKey.ifBlank { item.id },
                                    )
                                },
                                trailingContent = {
                                    SymbolIcon(
                                        MaterialSymbol.KeyboardArrowRight,
                                        contentDescription = null,
                                    )
                                },
                                supportingContent = subtitle?.let { { Text(it) } },
                                modifier = Modifier
                                    .animateItem(
                                        fadeInSpec = itemFade,
                                        placementSpec = itemPlacement,
                                        fadeOutSpec = itemFade,
                                    )
                                    .clip(
                                        Bento.groupShape(
                                            first = index == 0,
                                            last = index == rows.lastIndex,
                                        ),
                                    ),
                                colors = bentoRowColors(),
                                content = { Text(item.displayName) },
                            )
                        }
                    }
                }
            }
        }
    }
}

private fun matchesGuideQuery(provider: CatalogProvider, needle: String): Boolean {
    if (needle.isEmpty()) return true
    return provider.displayName.contains(needle, ignoreCase = true) ||
        provider.id.contains(needle, ignoreCase = true) ||
        provider.searchKeywords.any { it.contains(needle, ignoreCase = true) }
}
