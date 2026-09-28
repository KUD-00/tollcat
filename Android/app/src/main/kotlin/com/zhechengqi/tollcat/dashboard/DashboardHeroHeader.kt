@file:OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalLayoutApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.material3.ToggleButtonDefaults
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.AmountText
import com.zhechengqi.tollcat.ui.UITestId
import com.zhechengqi.tollcat.ui.heroAmountTextStyle
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 仪表盘顶栏（画布 H1 的内容 × A 的版式）：品牌主色铺满顶部、钻到状态栏下面，
 * 「到今天」窄体大数和「月底大约」并排，下面一条实心 + 斜纹的进度条表示这个月走到哪天，
 * 再下面是口径切换。内容区像一张纸从底下推上来盖住它的下沿
 * （[DashboardSheet]）。深色主题下 primary 自己变浅，同一套代码就是 H1 的深色版。
 *
 * [fullBleed] 为 false 时画成一张 32dp 圆角的卡，给引导页和画廊用：不吃状态栏、没有顶部操作。
 */
@Composable
fun DashboardHeroHeader(
    state: DashboardHeroState,
    modifier: Modifier = Modifier,
    fullBleed: Boolean = true,
    filterActive: Boolean = false,
    isRefreshing: Boolean = false,
    onFilter: (() -> Unit)? = null,
    onShare: (() -> Unit)? = null,
    onToggleSubscriptions: ((Boolean) -> Unit)? = null,
) {
    val container = MaterialTheme.colorScheme.primary
    val content = MaterialTheme.colorScheme.onPrimary
    if (fullBleed) {
        Column(
            modifier = modifier
                .fillMaxWidth()
                .background(container)
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(start = 24.dp, end = 12.dp, top = 4.dp, bottom = 28.dp + DashboardSheetOverlap),
        ) {
            HeroTopRow(
                title = state.periodTitle,
                content = content,
                filterActive = filterActive,
                isRefreshing = isRefreshing,
                onFilter = onFilter,
                onShare = onShare,
            )
            Spacer(Modifier.height(20.dp))
            Column(Modifier.padding(end = 12.dp)) {
                HeroBody(state, content, container, onToggleSubscriptions)
            }
        }
    } else {
        Surface(
            color = container,
            contentColor = content,
            shape = RoundedCornerShape(32.dp),
            modifier = modifier.fillMaxWidth(),
        ) {
            Column(Modifier.padding(horizontal = 22.dp, vertical = 22.dp)) {
                if (state.periodTitle.isNotBlank()) {
                    Text(
                        state.periodTitle,
                        style = MaterialTheme.typography.titleMediumEmphasized,
                        color = content,
                    )
                    Spacer(Modifier.height(12.dp))
                }
                HeroBody(state, content, container, onToggleSubscriptions)
            }
        }
    }
}

@Composable
private fun HeroTopRow(
    title: String,
    content: Color,
    filterActive: Boolean,
    isRefreshing: Boolean,
    onFilter: (() -> Unit)?,
    onShare: (() -> Unit)?,
) {
    val buttonColors = IconButtonDefaults.iconButtonColors(
        containerColor = content.copy(alpha = 0.14f),
        contentColor = content,
    )
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLargeEmphasized,
            color = content,
            maxLines = 1,
            modifier = Modifier.weight(1f),
        )
        if (isRefreshing) {
            LoadingIndicator(color = content, modifier = Modifier.size(32.dp))
        }
        if (onFilter != null) {
            IconButton(onClick = onFilter, colors = buttonColors, shapes = IconButtonDefaults.shapes()) {
                SymbolIcon(
                    MaterialSymbol.FilterList,
                    contentDescription = stringResource(R.string.dashboard_filter),
                    filled = filterActive,
                )
            }
        }
        if (onShare != null) {
            IconButton(onClick = onShare, colors = buttonColors, shapes = IconButtonDefaults.shapes()) {
                SymbolIcon(MaterialSymbol.Upload, contentDescription = stringResource(R.string.dashboard_share_a11y))
            }
        }
    }
}

@Composable
private fun ColumnScope.HeroBody(
    state: DashboardHeroState,
    content: Color,
    container: Color,
    onToggleSubscriptions: ((Boolean) -> Unit)?,
) {
    val spoken = stringResource(R.string.dashboard_month_to_date_a11y, state.amount)
    val size = heroAmountSize(state.amount)
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        itemVerticalAlignment = Alignment.Bottom,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column {
            Text(
                // 回看过去的月份没有「今天」：那个月已经结束，写「合计」。
                stringResource(if (state.projected != null) R.string.dashboard_hero_now else R.string.dashboard_scope_total),
                style = MaterialTheme.typography.labelLarge,
                color = content.copy(alpha = 0.86f),
            )
            AmountText(
                text = state.amount,
                style = heroAmountTextStyle(size),
                color = content,
                modifier = Modifier
                    .semantics { contentDescription = spoken }
                    .testTag(UITestId.DASHBOARD_TOTAL),
            )
        }
        state.projected?.let { projected ->
            val projectedSpoken = stringResource(R.string.projected_caption, projected)
            Row(
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.semantics(mergeDescendants = true) { contentDescription = projectedSpoken },
            ) {
                SymbolIcon(
                    MaterialSymbol.ArrowForward,
                    contentDescription = null,
                    tint = content.copy(alpha = 0.5f),
                    modifier = Modifier.padding(bottom = (size.value * 0.18f).dp),
                )
                Column {
                    Text(
                        stringResource(R.string.dashboard_hero_projected),
                        style = MaterialTheme.typography.labelLarge,
                        color = content.copy(alpha = 0.78f),
                    )
                    Text(
                        projected,
                        style = heroAmountTextStyle(size * 0.46f),
                        color = content.copy(alpha = 0.78f),
                        maxLines = 1,
                        modifier = Modifier.padding(bottom = (size.value * 0.08f).dp),
                    )
                }
            }
        }
    }
    state.monthProgress?.let { progress ->
        Spacer(Modifier.height(20.dp))
        MonthProgressBar(fraction = progress.fraction, color = content)
        Spacer(Modifier.height(6.dp))
        Row(Modifier.fillMaxWidth()) {
            Text(
                progress.startLabel,
                style = MaterialTheme.typography.labelSmall,
                color = content.copy(alpha = 0.8f),
            )
            Text(
                stringResource(R.string.dashboard_hero_today, progress.todayLabel),
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = content,
                modifier = Modifier.weight(1f).padding(horizontal = 8.dp),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Text(
                progress.endLabel,
                style = MaterialTheme.typography.labelSmall,
                color = content.copy(alpha = 0.8f),
            )
        }
    }
    val notes = buildList {
        state.subscriptionNote?.takeIf { it.isNotBlank() }?.let { add(HeroNote(it, MaterialSymbol.Payments, false)) }
        state.filterNote?.takeIf { it.isNotBlank() }?.let { add(HeroNote(it, MaterialSymbol.FilterList, false)) }
        state.staleCaption?.takeIf { it.isNotBlank() }?.let { add(HeroNote(it, MaterialSymbol.Sync, true)) }
    }
    if (notes.isNotEmpty()) {
        Spacer(Modifier.height(16.dp))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            notes.forEach { note ->
                val colors = if (note.warning) {
                    MaterialTheme.colorScheme.errorContainer to MaterialTheme.colorScheme.onErrorContainer
                } else {
                    content.copy(alpha = 0.14f) to content
                }
                HeroChip(text = note.text, symbol = note.symbol, container = colors.first, contentColor = colors.second)
            }
        }
    }
    state.currencyNote?.takeIf { it.isNotBlank() }?.let { note ->
        Spacer(Modifier.height(8.dp))
        Text(note, style = MaterialTheme.typography.bodySmall, color = content.copy(alpha = 0.8f))
    }
    val toggle = onToggleSubscriptions.takeIf { state.showsScopeToggle }
    if (toggle != null) {
        Spacer(Modifier.height(18.dp))
        HeroScopeToggle(
            includesSubscriptions = state.includesSubscriptions,
            onChange = toggle,
            content = content,
            container = container,
        )
    }
}

/**
 * 这个月走到哪天（画布 R1-1）：已经过去的天数是实心段，剩下的天数是斜纹段，中间 3dp 缝。
 * 斜纹说「还没发生」——和月底预计那个数是同一件事。
 */
@Composable
private fun MonthProgressBar(fraction: Float, color: Color) {
    val solid = fraction.coerceIn(0.02f, 0.98f)
    Canvas(
        Modifier
            .fillMaxWidth()
            .height(12.dp),
    ) {
        val gap = 3.dp.toPx()
        val outer = CornerRadius(size.height / 2f)
        val inner = CornerRadius(3.dp.toPx())
        val split = size.width * solid
        drawPath(
            Path().apply {
                addRoundRect(
                    RoundRect(
                        left = 0f, top = 0f, right = split - gap / 2f, bottom = size.height,
                        topLeftCornerRadius = outer, bottomLeftCornerRadius = outer,
                        topRightCornerRadius = inner, bottomRightCornerRadius = inner,
                    ),
                )
            },
            color = color,
        )
        val rest = Path().apply {
            addRoundRect(
                RoundRect(
                    left = split + gap / 2f, top = 0f, right = size.width, bottom = size.height,
                    topLeftCornerRadius = inner, bottomLeftCornerRadius = inner,
                    topRightCornerRadius = outer, bottomRightCornerRadius = outer,
                ),
            )
        }
        clipPath(rest) {
            drawRect(color.copy(alpha = 0.12f))
            val step = 10.dp.toPx()
            val stroke = 5.dp.toPx()
            var x = split - size.height
            while (x < size.width + size.height) {
                drawLine(
                    color = color.copy(alpha = 0.26f),
                    start = Offset(x, size.height),
                    end = Offset(x + size.height, 0f),
                    strokeWidth = stroke,
                )
                x += step
            }
        }
    }
}

/** 数字越长字越小：窄体下六位（$47.20）能和月底那个数并排，再长就让月底那个数折到下一行。 */
private fun heroAmountSize(amount: String): TextUnit = when {
    amount.length <= 6 -> 76.sp
    amount.length <= 8 -> 64.sp
    amount.length <= 11 -> 52.sp
    else -> 40.sp
}

private data class HeroNote(val text: String, val symbol: MaterialSymbol, val warning: Boolean)

@Composable
private fun HeroChip(
    text: String,
    symbol: MaterialSymbol,
    container: Color,
    contentColor: Color,
    onClick: (() -> Unit)? = null,
) {
    val body: @Composable () -> Unit = {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier
                .heightIn(min = 32.dp)
                .padding(horizontal = 10.dp, vertical = 6.dp),
        ) {
            SymbolIcon(symbol, contentDescription = null, size = 16.dp)
            Text(text, style = MaterialTheme.typography.labelLarge)
        }
    }
    if (onClick != null) {
        Surface(
            onClick = onClick,
            color = container,
            contentColor = contentColor,
            shape = RoundedCornerShape(8.dp),
            modifier = Modifier.minimumInteractiveComponentSize(),
            content = body,
        )
    } else {
        Surface(color = container, contentColor = contentColor, shape = RoundedCornerShape(8.dp), content = body)
    }
}

/** 合计 / 按量：M3 connected button group，选中那颗反色（onPrimary 底、primary 字）。 */
@Composable
private fun HeroScopeToggle(
    includesSubscriptions: Boolean,
    onChange: (Boolean) -> Unit,
    content: Color,
    container: Color,
) {
    val colors = ToggleButtonDefaults.toggleButtonColors(
        containerColor = content.copy(alpha = 0.14f),
        contentColor = content,
        checkedContainerColor = content,
        checkedContentColor = container,
    )
    Row(horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween)) {
        ToggleButton(
            checked = includesSubscriptions,
            onCheckedChange = { if (it) onChange(true) },
            colors = colors,
            shapes = ButtonGroupDefaults.connectedLeadingButtonShapes(),
        ) {
            if (includesSubscriptions) {
                SymbolIcon(MaterialSymbol.Check, contentDescription = null, size = 18.dp)
                Spacer(Modifier.size(ToggleButtonDefaults.IconSpacing))
            }
            Text(stringResource(R.string.dashboard_scope_total))
        }
        ToggleButton(
            checked = !includesSubscriptions,
            onCheckedChange = { if (it) onChange(false) },
            colors = colors,
            shapes = ButtonGroupDefaults.connectedTrailingButtonShapes(),
        ) {
            if (!includesSubscriptions) {
                SymbolIcon(MaterialSymbol.Check, contentDescription = null, size = 18.dp)
                Spacer(Modifier.size(ToggleButtonDefaults.IconSpacing))
            }
            Text(stringResource(R.string.dashboard_scope_variable))
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardHeroHeaderPreview() {
    TollCatTheme {
        Column {
            DashboardHeroHeader(
                state = DashboardHeroPreview.state,
                onFilter = {},
                onShare = {},
                onToggleSubscriptions = {},
            )
            DashboardSheet {
                Text("…", modifier = Modifier.padding(16.dp))
            }
        }
    }
}

@Preview(name = "Card Light", showBackground = true)
@Preview(name = "Card Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardHeroCardPreview() {
    TollCatTheme {
        DashboardHeroHeader(
            state = DashboardHeroPreview.state.copy(staleCaption = "有 1 家没更新上"),
            fullBleed = false,
            modifier = Modifier.padding(16.dp),
            onToggleSubscriptions = {},
        )
    }
}
