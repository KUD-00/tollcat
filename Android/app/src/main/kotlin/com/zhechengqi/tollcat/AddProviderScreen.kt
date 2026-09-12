package com.zhechengqi.tollcat

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.services.AddProviderConfirmSheet
import com.zhechengqi.tollcat.services.ProviderSubscriptionSheet
import com.zhechengqi.tollcat.services.SearchEmpty
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.services.categoryTitleRes
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.bentoRowColors
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

enum class AddProviderBrowse { Featured, More }

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun AddProviderScreen(
    session: TollCatSession,
    browse: AddProviderBrowse = AddProviderBrowse.Featured,
    modifier: Modifier = Modifier,
) {
    session.dataRevision
    var query by rememberSaveable { mutableStateOf("") }
    var pending by remember { mutableStateOf<CatalogProvider?>(null) }
    var addingManual by remember { mutableStateOf(false) }
    val taken = session.memberships().map { it.providerId }.toSet()
    val needle = query.trim()
    val matched = session.catalog.providers
        .filter { it.accessStatus != "declined" }
        .filter { it.id !in taken }
        .filter { provider -> matchesAddProviderQuery(provider, needle) }
    val visible = when {
        needle.isNotEmpty() -> matched
        browse == AddProviderBrowse.Featured -> matched.filter { it.belongsOnFeaturedPage() }
        else -> matched.filter { !it.belongsOnFeaturedPage() }
    }
        .sortedBy { it.displayName.lowercase() }
    val categoryOrder = session.catalog.categoryOrder.ifEmpty {
        visible.map { it.category }.distinct()
    }
    val grouped = categoryOrder.mapNotNull { category ->
        val rows = visible.filter { it.category == category }
        if (rows.isEmpty()) null else category to rows
    }
    val showTitles = grouped.size > 1
    val showsMore = browse == AddProviderBrowse.Featured &&
        needle.isEmpty() &&
        matched.any { !it.belongsOnFeaturedPage() }
    // 和 iOS `AddProviderSearch.matchesManualRow` 同一口径：只认本地化的行名。
    val manualLabel = stringResource(R.string.services_manual_subscription)
    val showsManual = needle.isEmpty() || manualLabel.contains(needle, ignoreCase = true)
    val emptySearch = needle.isNotEmpty() && visible.isEmpty() && !showsManual
    val titleRes = if (browse == AddProviderBrowse.More) {
        R.string.more_services
    } else {
        R.string.add_provider_title
    }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text(stringResource(titleRes)) },
                navigationIcon = {
                    IconButton(
                        onClick = { session.popServices() },
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(
                            MaterialSymbol.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                },
            )
        },
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
                // 药丸搜索框不要下划线——带指示线的是表单输入，不是搜索。
                colors = TextFieldDefaults.colors(
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    disabledIndicatorColor = Color.Transparent,
                    focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
                ),
            )
            if (emptySearch) {
                SearchEmpty(
                    query = query,
                    modifier = Modifier.padding(top = 24.dp),
                )
            } else {
                val reduceMotion = LocalReduceMotion.current
                val itemPlacement = MaterialTheme.motionScheme.defaultSpatialSpec<IntOffset>()
                    .takeUnless { reduceMotion }
                val itemFade = MaterialTheme.motionScheme.fastEffectsSpec<Float>()
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .testTag(UITestId.ADD_PROVIDER_LIST),
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
                                        .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                        .padding(start = 4.dp, top = 13.dp, bottom = 5.dp),
                                )
                            }
                        }
                        itemsIndexed(rows, key = { _, provider -> provider.id }) { index, provider ->
                            val addSpoken = stringResource(R.string.services_add_named, provider.displayName)
                            ListItem(
                                onClick = { pending = provider },
                                leadingContent = {
                                    ServiceGlyph(
                                        name = provider.displayName,
                                        colorKey = provider.colorKey.ifBlank { provider.id },
                                    )
                                },
                                supportingContent = {
                                    Text(provider.summary.ifBlank { stringResource(kindCaption(provider.kind)) })
                                },
                                modifier = Modifier
                                    .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                    .clip(
                                        Bento.groupShape(
                                            first = index == 0,
                                            last = index == rows.lastIndex,
                                        ),
                                    )
                                    .semantics { contentDescription = addSpoken }
                                    .testTag(UITestId.addProviderRow(provider.id)),
                                colors = bentoRowColors(),
                                content = { Text(provider.displayName) },
                            )
                        }
                    }
                    if (showsMore) {
                        item(key = "more") {
                            ListItem(
                                onClick = { session.openAddMore() },
                                leadingContent = {
                                    SymbolIcon(MaterialSymbol.MoreHoriz, contentDescription = null)
                                },
                                modifier = Modifier
                                    .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                    .padding(top = 13.dp)
                                    .clip(Bento.solo),
                                colors = bentoRowColors(),
                                content = { Text(stringResource(R.string.more_services)) },
                            )
                        }
                    }
                    if (showsManual) {
                        item(key = "manual") {
                            ListItem(
                                onClick = { addingManual = true },
                                leadingContent = {
                                    SymbolIcon(MaterialSymbol.CalendarMonth, contentDescription = null)
                                },
                                modifier = Modifier
                                    .animateItem(fadeInSpec = itemFade, placementSpec = itemPlacement, fadeOutSpec = itemFade)
                                    .padding(top = 13.dp)
                                    .clip(Bento.solo),
                                colors = bentoRowColors(),
                                content = { Text(manualLabel) },
                            )
                        }
                    }
                }
            }
        }
    }

    pending?.let { provider ->
        AddProviderConfirmSheet(
            provider = provider,
            onAdd = {
                pending = null
                session.addProvider(provider.id)
            },
            onDismiss = { pending = null },
        )
    }
    if (addingManual) {
        ProviderSubscriptionSheet(
            providerId = null,
            accountId = null,
            editing = null,
            onDismiss = { addingManual = false },
            onSave = { row ->
                session.saveSubscription(row)
                addingManual = false
                session.popServices()
            },
            onDelete = null,
        )
    }
}

/** 常见服务：市占档 1、2，刨去只支持读数信箱的。和 iOS `AddProviderSearch.isFeatured` 同一口径。 */
private fun CatalogProvider.belongsOnFeaturedPage(): Boolean =
    (tier == 1 || tier == 2) && !supportsInbox

private fun matchesAddProviderQuery(provider: CatalogProvider, needle: String): Boolean {
    if (needle.isEmpty()) return true
    return provider.displayName.contains(needle, ignoreCase = true) ||
        provider.id.contains(needle, ignoreCase = true) ||
        provider.summary.contains(needle, ignoreCase = true) ||
        // 中英别名来自编译期 descriptor（搜「克劳德」/「claude」都命中 Anthropic）。
        provider.searchKeywords.any { it.contains(needle, ignoreCase = true) }
}

private fun kindCaption(kind: String): Int {
    return when (kind) {
        "prepaid" -> R.string.kind_prepaid_title
        "subscription" -> R.string.kind_subscription_title
        "freeTier" -> R.string.kind_freetier_title
        "planAndUsage" -> R.string.kind_plan_usage_title
        else -> R.string.kind_usage_title
    }
}
