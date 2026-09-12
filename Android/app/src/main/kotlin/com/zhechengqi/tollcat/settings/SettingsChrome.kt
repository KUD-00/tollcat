package com.zhechengqi.tollcat.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MediumFlexibleTopAppBar
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.material3.ToggleButtonDefaults
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SettingsScaffold(
    title: String,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
    snackbarHost: @Composable () -> Unit = {},
    bottomBar: @Composable () -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    Scaffold(
        modifier = modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        snackbarHost = snackbarHost,
        bottomBar = bottomBar,
        topBar = {
            MediumFlexibleTopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    if (onBack != null) {
                        IconButton(
                            onClick = onBack,
                            shapes = IconButtonDefaults.shapes(),
                        ) {
                            SymbolIcon(
                                MaterialSymbol.ArrowBack,
                                contentDescription = stringResource(R.string.action_back),
                            )
                        }
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
        content = content,
    )
}

@Composable
fun SettingsSection(
    title: String,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(start = 32.dp, end = 16.dp, top = 20.dp, bottom = 8.dp),
        )
        SettingsGroup(content = content)
    }
}

/** bento 行的统一缝角。首末行的 28dp 外沿由 [SettingsGroup] 的裁切补出来。 */
val SettingsRowShape = RoundedCornerShape(10.dp)

/**
 * 设置组不再是一整张卡：组透明、行自带底色，行间 3dp 缝，
 * 整组再裁一刀 28dp——行不需要知道自己是首是末。
 */
@Composable
fun SettingsGroup(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier
            .padding(horizontal = 16.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp)),
        verticalArrangement = Arrangement.spacedBy(3.dp),
        content = content,
    )
}

/** bento 行的统一底色。 */
@Composable
fun settingsRowColors() = ListItemDefaults.colors(
    containerColor = MaterialTheme.colorScheme.surfaceContainer,
)

/** 只读的键值行。数字走 tnum，同一列的位数才对得齐。 */
@Composable
fun SettingsValueRow(
    title: String,
    value: String,
    modifier: Modifier = Modifier,
) {
    ListItem(
        modifier = modifier.clip(SettingsRowShape),
        trailingContent = {
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
        colors = settingsRowColors(),
    ) {
        Text(title)
    }
}

@Composable
fun SettingsNavRow(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    icon: MaterialSymbol? = null,
    semanticsLabel: String? = null,
    headlineColor: Color = Color.Unspecified,
    showChevron: Boolean = true,
) {
    val clipped = modifier.clip(SettingsRowShape)
    ListItem(
        onClick = onClick,
        modifier = if (semanticsLabel == null) {
            clipped
        } else {
            clipped.semantics { contentDescription = semanticsLabel }
        },
        leadingContent = icon?.let {
            {
                SymbolIcon(
                    symbol = it,
                    contentDescription = null,
                    tint = if (headlineColor == Color.Unspecified) {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    } else {
                        headlineColor
                    },
                )
            }
        },
        trailingContent = if (showChevron) {
            { SymbolIcon(MaterialSymbol.KeyboardArrowRight, contentDescription = null) }
        } else {
            null
        },
        supportingContent = subtitle?.let { { Text(it) } },
        colors = settingsRowColors(),
        content = {
            Text(
                text = title,
                color = if (headlineColor == Color.Unspecified) {
                    Color.Unspecified
                } else {
                    headlineColor
                },
            )
        },
    )
}

/**
 * 少量互斥选项直接摆在行里的 connected 按钮组——不再为三个选项开一层子页。
 * 选中态由 ToggleButton 的形状变化 + 填色表达（M3 Expressive 的连体组）。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SettingsToggleGroupRow(
    title: String?,
    options: List<Pair<String, String>>,
    selected: String,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
    icon: MaterialSymbol? = null,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(SettingsRowShape)
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (title != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                icon?.let {
                    SymbolIcon(it, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text(title, style = MaterialTheme.typography.bodyLarge)
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween),
        ) {
            options.forEachIndexed { index, (label, value) ->
                ToggleButton(
                    checked = selected == value,
                    onCheckedChange = { checked -> if (checked) onSelect(value) },
                    modifier = Modifier.weight(1f),
                    // 行底是 surfaceContainer，未选态默认色会融进去，抬一档才读得出「这是一组按钮」。
                    colors = ToggleButtonDefaults.toggleButtonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
                    ),
                    shapes = when (index) {
                        0 -> ButtonGroupDefaults.connectedLeadingButtonShapes()
                        options.lastIndex -> ButtonGroupDefaults.connectedTrailingButtonShapes()
                        else -> ButtonGroupDefaults.connectedMiddleButtonShapes()
                    },
                ) {
                    Text(label, maxLines = 1)
                }
            }
        }
    }
}

@Composable
fun SettingsRadioRow(
    title: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
) {
    ListItem(
        onClick = onClick,
        modifier = modifier.clip(SettingsRowShape),
        trailingContent = {
            RadioButton(selected = selected, onClick = onClick)
        },
        supportingContent = subtitle?.let { { Text(it) } },
        colors = settingsRowColors(),
        content = { Text(title) },
    )
}

@Composable
fun SettingsSwitchRow(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
) {
    ListItem(
        onClick = { onCheckedChange(!checked) },
        modifier = modifier.clip(SettingsRowShape),
        trailingContent = {
            Switch(checked = checked, onCheckedChange = onCheckedChange)
        },
        supportingContent = subtitle?.let { { Text(it) } },
        colors = settingsRowColors(),
        content = { Text(title) },
    )
}
