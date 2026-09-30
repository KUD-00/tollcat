package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.ui.AmountText
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.TollCatSheet
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId

/**
 * 筛选抽屉。两维各占一节：时间、服务。
 * 订阅口径不在这里——它是首屏大数字旁边那颗分段控件。
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun DashboardFilterSheet(
    state: DashboardFilterState,
    accounts: List<DashboardFilterAccount>,
    nowMillis: Long,
    onApply: (DashboardFilterState) -> Unit,
    onDismiss: () -> Unit,
    monthsWithReadings: Set<Int> = setOf(0),
    previewDashboard: (DashboardFilterState) -> DashboardSnapshot = { DashboardPreviewData.snapshot },
) {
    var draft by remember { mutableStateOf(state) }
    val preview = remember(draft) { previewDashboard(draft) }
    TollCatSheet(onDismiss = onDismiss) {
        DashboardFilterSheetBody(
            draft = draft,
            applied = state,
            accounts = accounts,
            nowMillis = nowMillis,
            monthsWithReadings = monthsWithReadings,
            preview = preview,
            onDraftChange = { draft = it },
            onApply = { onApply(draft) },
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun DashboardFilterSheetBody(
    draft: DashboardFilterState,
    applied: DashboardFilterState,
    accounts: List<DashboardFilterAccount>,
    nowMillis: Long,
    monthsWithReadings: Set<Int>,
    preview: DashboardSnapshot,
    onDraftChange: (DashboardFilterState) -> Unit,
    onApply: () -> Unit,
) {
    val monthBacks = remember(monthsWithReadings) {
        (monthsWithReadings + 0)
            .filter { it in 0..DashboardFilterState.MAX_MONTHS_BACK }
            .sorted()
    }
    val deepest = monthBacks.maxOrNull() ?: 0
    val spanOptions = remember(deepest, nowMillis) {
        filterSpanOptions(deepest, nowMillis)
    }
    val custom = isCustomRange(draft, spanOptions)
    var customExpanded by remember { mutableStateOf(custom) }
    val (oldestBack, newestBack) = draft.windowBacks(nowMillis, deepest)
    // 预览是按草稿取景框重算出来的，口径已经在里面。
    val previewAmount = preview.formattedTotal
    // 按草稿重算出来的那份自带限定语（共享层 `DashboardFilterSummary.full`，和 iOS 同一句）。
    // 什么都没筛时给一句占位，免得这一行时有时无地把布局顶来顶去。
    val previewNote = preview.filterNote ?: stringResource(R.string.dashboard_filter_preview_unfiltered)
    val previewSpoken = stringResource(R.string.dashboard_filter_preview_a11y, previewAmount, previewNote)
    val everythingExcluded = accounts.isNotEmpty() &&
        accounts.all { it.accountId in draft.excludedAccountIds }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = MeterSpacing.xl)
            .padding(bottom = MeterSpacing.xxl),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
    ) {
        Text(
            text = stringResource(R.string.dashboard_filter),
            style = MaterialTheme.typography.headlineSmall,
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .semantics(mergeDescendants = true) { contentDescription = previewSpoken },
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs),
        ) {
            AmountText(
                text = previewAmount,
                style = MaterialTheme.typography.displaySmallEmphasized,
            )
            Text(
                text = previewNote,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (everythingExcluded) {
                Text(
                    text = stringResource(R.string.dashboard_filter_exclude_all),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                )
            }
        }

        Text(
            text = stringResource(R.string.dashboard_filter_time),
            style = MaterialTheme.typography.titleMedium,
        )
        ChipRow {
            monthBacks.forEach { back ->
                FilterChip(
                    selected = draft.periodKind == DashboardFilterState.KIND_MONTHS &&
                        draft.monthCount == 1 && draft.monthsBack == back,
                    onClick = { onDraftChange(draft.singleMonth(back)) },
                    label = { Text(monthChipTitle(back, nowMillis)) },
                    leadingIcon = selectedCheck(
                        draft.periodKind == DashboardFilterState.KIND_MONTHS &&
                            draft.monthCount == 1 && draft.monthsBack == back,
                    ),
                )
            }
        }
        if (spanOptions.isNotEmpty()) {
            ChipRow {
                spanOptions.forEach { option ->
                    FilterChip(
                        selected = option.matches(draft),
                        onClick = { onDraftChange(option.applyTo(draft)) },
                        label = { Text(option.title()) },
                        leadingIcon = selectedCheck(option.matches(draft)),
                    )
                }
            }
        }
        DashboardFilterCustomRow(
            expanded = customExpanded,
            onExpandedChange = { customExpanded = it },
            oldestBack = oldestBack,
            newestBack = newestBack,
            nowMillis = nowMillis,
            isCustomRange = custom,
            onRangeChange = { oldest, newest ->
                onDraftChange(draft.customRange(oldest, newest))
            },
        )
        Text(
            text = stringResource(R.string.dashboard_filter_time_footer),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        if (accounts.isNotEmpty()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.dashboard_filter_services),
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f),
                )
                if (draft.excludedAccountIds.isNotEmpty()) {
                    TextButton(onClick = { onDraftChange(draft.includeAllAccounts()) }) {
                        Text(stringResource(R.string.dashboard_filter_all))
                    }
                }
            }
            // 一行一家，竖着排：横滑的胶囊一多就溢出屏外，看不见的那几家等于不存在。
            Column {
                accounts.forEach { account ->
                    AccountFilterRow(
                        account = account,
                        included = account.accountId !in draft.excludedAccountIds,
                        onToggle = { onDraftChange(draft.toggleAccount(account.accountId)) },
                        onOnlyThis = {
                            onDraftChange(
                                draft.copy(
                                    excludedAccountIds = accounts.map { it.accountId }.toSet() - account.accountId,
                                ),
                            )
                        },
                    )
                }
            }
        }
        Spacer(Modifier.height(MeterSpacing.xs))
        PrimaryButton(
            onClick = onApply,
            enabled = draft != applied,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.dashboard_filter_apply))
        }
    }
}

@Composable
private fun ChipRow(content: @Composable RowScope.() -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
        content = content,
    )
}

@Composable
private fun selectedCheck(selected: Boolean): (@Composable () -> Unit)? {
    if (!selected) return null
    return {
        SymbolIcon(
            MaterialSymbol.Check,
            contentDescription = null,
            size = FilterChipDefaults.IconSize,
        )
    }
}

/**
 * 服务一行：左边图标和名字，右边开关，整行都能点。长按弹「只看这一家」——
 * 和 iOS 那一行的 contextMenu 同一个动作；读屏走自定义操作。
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun AccountFilterRow(
    account: DashboardFilterAccount,
    included: Boolean,
    onToggle: () -> Unit,
    onOnlyThis: () -> Unit,
) {
    val label = accountLabel(account)
    val onlyLabel = stringResource(R.string.dashboard_filter_only, label)
    var menu by remember { mutableStateOf(false) }
    Box {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = MeterSpacing.minTap)
                .clip(MaterialTheme.shapes.medium)
                .combinedClickable(
                    role = Role.Switch,
                    onClick = onToggle,
                    onLongClick = { menu = true },
                )
                .semantics(mergeDescendants = true) {
                    toggleableState = ToggleableState(included)
                    customActions = listOf(
                        CustomAccessibilityAction(onlyLabel) {
                            onOnlyThis()
                            true
                        },
                    )
                }
                .padding(vertical = MeterSpacing.xxs),
        ) {
            ServiceGlyph(
                name = label,
                colorKey = account.colorKey.ifBlank { account.providerId },
                modifier = Modifier.alpha(if (included) 1f else 0.38f),
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodyLarge,
                color = if (included) {
                    MaterialTheme.colorScheme.onSurface
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            // 开关只是状态的样子，点击交给整行，免得点在开关上和点在行上走两条路。
            Switch(checked = included, onCheckedChange = null)
        }
        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
            DropdownMenuItem(
                text = { Text(onlyLabel) },
                onClick = {
                    menu = false
                    onOnlyThis()
                },
            )
        }
    }
}

@Composable
private fun monthChipTitle(monthsBack: Int, nowMillis: Long): String {
    if (monthsBack == 0) return stringResource(R.string.dashboard_comparison_this_month)
    return formatDashboardMonth(monthsBack, nowMillis)
}

private data class SpanOption(
    val kind: String,
    val monthsBack: Int = 0,
    val monthCount: Int = 1,
    val titleRes: Int,
) {
    fun matches(draft: DashboardFilterState): Boolean =
        draft.periodKind == kind &&
            (kind != DashboardFilterState.KIND_MONTHS || (draft.monthsBack == monthsBack && draft.monthCount == monthCount))

    fun applyTo(draft: DashboardFilterState): DashboardFilterState = draft.copy(
        periodKind = kind,
        monthsBack = monthsBack,
        monthCount = monthCount,
    )
}

@Composable
private fun SpanOption.title(): String = stringResource(titleRes)

private fun filterSpanOptions(deepest: Int, nowMillis: Long): List<SpanOption> {
    if (deepest < 1) return emptyList()
    val options = mutableListOf<SpanOption>()
    if (deepest >= 2) {
        options += SpanOption(
            kind = DashboardFilterState.KIND_MONTHS,
            monthsBack = 0,
            monthCount = 3,
            titleRes = R.string.dashboard_filter_last_3,
        )
    }
    if (deepest >= 5) {
        options += SpanOption(
            kind = DashboardFilterState.KIND_MONTHS,
            monthsBack = 0,
            monthCount = 6,
            titleRes = R.string.dashboard_filter_last_6,
        )
    }
    val monthValue = YearMonth.from(
        Instant.ofEpochMilli(nowMillis).atZone(ZoneId.systemDefault()),
    ).monthValue
    if (monthValue > 1) {
        options += SpanOption(
            kind = DashboardFilterState.KIND_YEAR_TO_DATE,
            titleRes = R.string.dashboard_filter_ytd,
        )
    }
    options += SpanOption(
        kind = DashboardFilterState.KIND_ALL_TIME,
        titleRes = R.string.dashboard_filter_all_time,
    )
    return options
}

private fun isCustomRange(draft: DashboardFilterState, spanOptions: List<SpanOption>): Boolean {
    if (draft.periodKind != DashboardFilterState.KIND_MONTHS) return false
    if (draft.monthCount == 1) return false
    return spanOptions.none { it.matches(draft) }
}

private fun DashboardFilterState.customRange(oldestBack: Int, newestBack: Int): DashboardFilterState {
    val oldest = maxOf(oldestBack, newestBack).coerceIn(0, DashboardFilterState.MAX_MONTHS_BACK)
    val newest = minOf(oldestBack, newestBack).coerceIn(0, DashboardFilterState.MAX_MONTHS_BACK)
    return copy(
        periodKind = DashboardFilterState.KIND_MONTHS,
        monthsBack = newest,
        monthCount = oldest - newest + 1,
    )
}

private fun DashboardFilterState.windowBacks(nowMillis: Long, deepestBack: Int): Pair<Int, Int> {
    val newest: Int
    val count: Int
    when (periodKind) {
        DashboardFilterState.KIND_YEAR_TO_DATE -> {
            newest = 0
            count = YearMonth.from(
                Instant.ofEpochMilli(nowMillis).atZone(ZoneId.systemDefault()),
            ).monthValue
        }
        DashboardFilterState.KIND_ALL_TIME -> {
            newest = 0
            count = deepestBack + 1
        }
        else -> {
            newest = monthsBack
            count = monthCount.coerceAtLeast(1)
        }
    }
    val oldest = (newest + count - 1).coerceIn(0, DashboardFilterState.MAX_MONTHS_BACK)
    return oldest to newest.coerceIn(0, DashboardFilterState.MAX_MONTHS_BACK)
}

/** 同厂商多账号时带序号，和 iOS 的账号标题口径一致。 */
private fun accountLabel(account: DashboardFilterAccount): String {
    if (account.siblingCount <= 1) return account.displayName
    return "${account.displayName} ${account.siblingIndex + 1}"
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardFilterSheetPreview() {
    TollCatTheme {
        DashboardFilterSheetBody(
            draft = DashboardFilterState(),
            applied = DashboardFilterState(),
            accounts = listOf(
                DashboardFilterAccount("aws", "aws", "AWS", "aws", 0, 1),
                DashboardFilterAccount("openai", "openai", "OpenAI", "openai", 0, 1),
            ),
            nowMillis = System.currentTimeMillis(),
            monthsWithReadings = setOf(0, 1, 2, 4),
            preview = DashboardPreviewData.snapshot,
            onDraftChange = {},
            onApply = {},
        )
    }
}
