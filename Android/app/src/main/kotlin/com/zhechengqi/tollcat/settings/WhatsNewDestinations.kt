package com.zhechengqi.tollcat.settings

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.ProviderGlyph
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.EmptyState
import com.zhechengqi.tollcat.ui.EmptyStateGlyph
import com.zhechengqi.tollcat.ui.EmptyStateSize
import com.zhechengqi.tollcat.ui.TollCatSheet
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatView
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 更新后第一次冷启动那张弹出面。
 *
 * 跳版会合并：最新那条铺开，被跳过的版本只列一行标题——全文在设置 → 更新说明。
 * 外壳走 [TollCatSheet]（它自己再开一次 testTagsAsResourceId，弹出面是另一棵树）。
 */
@Composable
fun WhatsNewSheet(
    entries: List<WhatsNewEntry>,
    language: String,
    onDismiss: () -> Unit,
) {
    val latest = entries.firstOrNull() ?: return
    TollCatSheet(onDismiss = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
        ) {
            WhatsNewEntryBody(entry = latest, language = language, includesTitle = true)
            if (entries.size > 1) {
                Spacer(Modifier.height(20.dp))
                Text(
                    text = stringResource(R.string.whats_new_more),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                entries.drop(1).forEach { entry ->
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = "${entry.version} · ${entry.title.resolve(language)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                }
            }
            Spacer(Modifier.height(20.dp))
            Button(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.action_got_it))
            }
            Spacer(Modifier.height(20.dp))
        }
    }
}

/** 设置 → 更新说明：弹过的、跳过的、当初决定不弹的，这里都在。 */
@Composable
fun WhatsNewListDestination(
    entries: List<WhatsNewEntry>,
    language: String,
    onOpen: (String) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = stringResource(R.string.settings_whats_new),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            if (entries.isEmpty()) {
                WhatsNewEmpty()
            } else {
                SettingsSection(title = stringResource(R.string.settings_whats_new)) {
                    entries.forEach { entry ->
                        SettingsNavRow(
                            title = entry.version,
                            subtitle = entry.title.resolve(language),
                            onClick = { onOpen(entry.version) },
                            semanticsLabel = stringResource(R.string.whats_new_open_hint),
                        )
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

/** 某一版的全文。 */
@Composable
fun WhatsNewEntryDestination(
    entry: WhatsNewEntry,
    language: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SettingsScaffold(
        title = entry.title.resolve(language),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
        ) {
            WhatsNewEntryBody(entry = entry, language = language, includesTitle = false)
            Spacer(Modifier.height(24.dp))
        }
    }
}

/** hero + 标题 + 符号/标题/正文的列表。弹出面和详情页共用，两处不许各排一遍版。 */
@Composable
private fun WhatsNewEntryBody(
    entry: WhatsNewEntry,
    language: String,
    includesTitle: Boolean,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        entry.hero?.let { hero ->
            Spacer(Modifier.height(20.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                WhatsNewHeroContent(hero)
            }
        }
        if (includesTitle) {
            Spacer(Modifier.height(20.dp))
            Text(
                text = entry.title.resolve(language),
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
        entry.items.forEach { item ->
            Spacer(Modifier.height(20.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                // symbol.android 是 MaterialSymbol 的 case 名，生成器上有闸；
                // 没写或对不上就不画图标，那一条只有文字。
                symbol(item.symbol)?.let {
                    SymbolIcon(
                        symbol = it,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                    )
                    Spacer(Modifier.width(16.dp))
                }
                Column {
                    Text(
                        text = item.title.resolve(language),
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = item.body.resolve(language),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@Composable
private fun WhatsNewHeroContent(hero: WhatsNewHero) {
    when (hero) {
        is WhatsNewHero.Cat -> {
            val mood = CatMood.entries.firstOrNull { it.name.equals(hero.mood, ignoreCase = true) }
            if (mood != null) {
                CatView(mood = mood, size = 96.dp)
            }
        }
        is WhatsNewHero.Glyph -> ProviderGlyph(name = hero.provider, colorKey = hero.provider)
        // 位图 hero 只有最新一条能带；Android 的 drawable 由生成器铺进
        // res/drawable-nodpi，接线等第一条真的带图的条目落地。
        is WhatsNewHero.Shot -> Unit
    }
}

private fun symbol(name: String?): MaterialSymbol? {
    if (name == null) return null
    return MaterialSymbol.entries.firstOrNull { it.name.equals(name, ignoreCase = true) }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun WhatsNewEmpty(modifier: Modifier = Modifier) {
    EmptyState(
        title = stringResource(R.string.settings_whats_new_empty_title),
        modifier = modifier.padding(top = 8.dp),
        size = EmptyStateSize.Compact,
        body = stringResource(R.string.settings_whats_new_empty_body),
        glyph = {
            EmptyStateGlyph(
                symbol = MaterialSymbol.MenuBook,
                shape = MaterialShapes.Cookie12Sided.toShape(),
            )
        },
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun WhatsNewEmptyPreview() {
    TollCatTheme {
        WhatsNewEmpty()
    }
}
