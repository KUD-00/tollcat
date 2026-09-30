package com.zhechengqi.tollcat.dashboard

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.LazyReorderState
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.TollCatSheet
import com.zhechengqi.tollcat.ui.rememberLazyReorderState
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 「编辑仪表盘」：开关模块、拖动排序；「特别关心」钉哪几家、「预算线」多少钱也在这里。
 *
 * 排序和 iOS 那一面同一套手感：显示中的每一行右边有拖动把手，按住就拖；长按整行也能抬起来拖。
 * 构成那块画在固定槽位，不给拖，别的行也换不到它上面去。读屏走「上移 / 下移」两个自定义操作。
 * 顺序在手指抬起时落盘，拖的过程中只动界面。
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardEditSheet(
    order: List<String>,
    pinned: Set<String>,
    budgetUsd: String,
    accounts: List<DashboardFilterAccount>,
    onOrderChange: (List<String>) -> Unit,
    onPinnedChange: (Set<String>) -> Unit,
    onBudgetChange: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    var modules by remember(order) { mutableStateOf(DashboardModules.normalized(order)) }
    var pins by remember { mutableStateOf(pinned) }
    var budget by remember { mutableStateOf(budgetUsd) }
    val enabled = modules
    val disabled = DashboardModules.editable.filter { it !in enabled.toSet() }
    val haptics = LocalHapticFeedback.current

    fun commit(next: List<String>) {
        val normalized = DashboardModules.normalized(next)
        modules = normalized
        onOrderChange(normalized)
    }

    fun move(id: String, delta: Int) {
        val index = enabled.indexOf(id)
        val next = enabled.toMutableList()
        next[index] = next[index + delta].also { next[index + delta] = next[index] }
        commit(next)
    }

    val listState = rememberLazyListState()
    val reorder = rememberLazyReorderState(
        listState = listState,
        canMoveTo = { key -> key is String && key in modules && key !in DashboardModules.fixedSlot },
        onMove = { from, to ->
            val list = modules.toMutableList()
            val fromIndex = list.indexOf(from)
            val toIndex = list.indexOf(to)
            if (fromIndex >= 0 && toIndex >= 0) {
                list.add(toIndex, list.removeAt(fromIndex))
                modules = list
            }
        },
    )

    TollCatSheet(onDismiss = onDismiss) {
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxWidth(),
            contentPadding = PaddingValues(start = MeterSpacing.xl, end = MeterSpacing.xl, bottom = MeterSpacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Bento.gap),
        ) {
            item(key = "title") {
                Text(
                    stringResource(R.string.dashboard_edit),
                    style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier.padding(bottom = MeterSpacing.xs),
                )
            }
            item(key = "enabledHeader") { SectionHeader(stringResource(R.string.dashboard_edit_showing)) }
            itemsIndexed(enabled, key = { _, id -> id }) { index, id ->
                val movable = id !in DashboardModules.fixedSlot
                val dragging = reorder.draggingKey == id
                ModuleRow(
                    id = id,
                    checked = true,
                    reservesHandle = true,
                    first = index == 0,
                    last = index == enabled.lastIndex,
                    dragging = dragging,
                    reorder = reorder.takeIf { movable },
                    moveUp = if (canMove(enabled, id, -1)) ({ move(id, -1) }) else null,
                    moveDown = if (canMove(enabled, id, 1)) ({ move(id, 1) }) else null,
                    onDragStart = { haptics.performHapticFeedback(HapticFeedbackType.LongPress) },
                    onReordered = { haptics.performHapticFeedback(HapticFeedbackType.SegmentTick) },
                    onDragEnd = {
                        haptics.performHapticFeedback(HapticFeedbackType.GestureEnd)
                        commit(modules)
                    },
                    onChecked = { on -> commit(if (on) enabled + id else enabled - id) },
                    // 被拖的那一行跟着手指走，不参与让位动画；别的行平滑挪开。
                    modifier = if (dragging) Modifier.zIndex(1f) else Modifier.animateItem(),
                )
            }
            item(key = "reorderFooter") {
                Text(
                    stringResource(R.string.dashboard_edit_reorder),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = MeterSpacing.md, top = MeterSpacing.xs),
                )
            }
            if (disabled.isNotEmpty()) {
                item(key = "moreHeader") { SectionHeader(stringResource(R.string.dashboard_edit_more)) }
                itemsIndexed(disabled, key = { _, id -> "more-$id" }) { index, id ->
                    ModuleRow(
                        id = id,
                        checked = false,
                        first = index == 0,
                        last = index == disabled.lastIndex,
                        dragging = false,
                        reorder = null,
                        moveUp = null,
                        moveDown = null,
                        onDragStart = {},
                        onReordered = {},
                        onDragEnd = {},
                        onChecked = { on -> commit(if (on) enabled + id else enabled - id) },
                        modifier = Modifier.animateItem(),
                    )
                }
            }
            if (DashboardModules.BUDGET in enabled) {
                item(key = "budget") {
                    OutlinedTextField(
                        value = budget,
                        onValueChange = {
                            budget = it
                            onBudgetChange(it)
                        },
                        label = { Text(stringResource(R.string.dashboard_budget_usd)) },
                        supportingText = { Text(stringResource(R.string.dashboard_budget_hint)) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = MeterSpacing.md),
                    )
                }
            }
            if (DashboardModules.SERVICES in enabled && accounts.isNotEmpty()) {
                item(key = "pins") {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
                        modifier = Modifier.padding(top = MeterSpacing.md),
                    ) {
                        Text(stringResource(R.string.module_pinned), style = MaterialTheme.typography.titleMedium)
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs)) {
                            accounts.forEach { account ->
                                FilterChip(
                                    selected = account.accountId in pins,
                                    onClick = {
                                        pins = if (account.accountId in pins) {
                                            pins - account.accountId
                                        } else {
                                            pins + account.accountId
                                        }
                                        onPinnedChange(pins)
                                    },
                                    label = { Text(account.displayName) },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = MeterSpacing.md, top = MeterSpacing.md, bottom = MeterSpacing.xs),
    )
}

/**
 * 一行模块：标题 + 一句说明，右边开关；能排序的行最右边是拖动把手。
 * 拖起来时这一行抬高（阴影、圆角整张变圆、微微放大），其余行照常贴成一组。
 */
@Composable
private fun ModuleRow(
    id: String,
    checked: Boolean,
    first: Boolean,
    last: Boolean,
    dragging: Boolean,
    reorder: LazyReorderState?,
    /** 显示中那一组：固定槽那行没有把手，但要留出把手的位置，开关才和下面几行对齐。 */
    reservesHandle: Boolean = false,
    moveUp: (() -> Unit)?,
    moveDown: (() -> Unit)?,
    onDragStart: () -> Unit,
    onReordered: () -> Unit,
    onDragEnd: () -> Unit,
    onChecked: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val elevation by animateDpAsState(if (dragging) 8.dp else 0.dp, label = "drag-elevation")
    val scale by animateFloatAsState(if (dragging) 1.02f else 1f, label = "drag-scale")
    val upLabel = stringResource(R.string.dashboard_edit_move_up)
    val downLabel = stringResource(R.string.dashboard_edit_move_down)
    val dragModifier = reorder?.let { state ->
        Modifier.pointerInput(id, state) {
            detectDragGestures(
                onDragStart = { if (state.start(id)) onDragStart() },
                onDrag = { change, amount ->
                    change.consume()
                    if (state.dragBy(amount.y)) onReordered()
                },
                onDragEnd = {
                    state.end()
                    onDragEnd()
                },
                onDragCancel = {
                    state.end()
                    onDragEnd()
                },
            )
        }
    }
    val longPressModifier = reorder?.let { state ->
        Modifier.pointerInput(id, state) {
            detectDragGesturesAfterLongPress(
                onDragStart = { if (state.start(id)) onDragStart() },
                onDrag = { change, amount ->
                    change.consume()
                    if (state.dragBy(amount.y)) onReordered()
                },
                onDragEnd = {
                    state.end()
                    onDragEnd()
                },
                onDragCancel = {
                    state.end()
                    onDragEnd()
                },
            )
        }
    }
    Surface(
        shape = if (dragging) RoundedCornerShape(Bento.outerRadius) else Bento.groupShape(first = first, last = last),
        color = if (dragging) MaterialTheme.colorScheme.surfaceContainerHighest else MaterialTheme.colorScheme.surfaceContainer,
        shadowElevation = elevation,
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                translationY = reorder?.translationFor(id) ?: 0f
                scaleX = scale
                scaleY = scale
            }
            .semantics {
                customActions = listOfNotNull(
                    moveUp?.let { action -> CustomAccessibilityAction(upLabel) { action(); true } },
                    moveDown?.let { action -> CustomAccessibilityAction(downLabel) { action(); true } },
                )
            },
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .heightIn(min = MeterSpacing.minTap)
                .padding(start = MeterSpacing.md, end = if (reservesHandle) 0.dp else MeterSpacing.md),
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(vertical = MeterSpacing.sm)
                    .then(longPressModifier ?: Modifier),
            ) {
                Text(stringResource(DashboardModules.titleRes(id)), style = MaterialTheme.typography.titleMedium)
                Text(
                    stringResource(DashboardModules.summaryRes(id)),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Switch(checked = checked, onCheckedChange = onChecked)
            if (dragModifier == null && reservesHandle) {
                Spacer(Modifier.size(MeterSpacing.minTap))
            }
            if (dragModifier != null) {
                // 把手本身就是热区：48dp 见方，按下即拖，不用等长按。
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(MeterSpacing.minTap)
                        .then(dragModifier),
                ) {
                    SymbolIcon(
                        MaterialSymbol.DragHandle,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

private fun canMove(enabled: List<String>, id: String, delta: Int): Boolean {
    if (id in DashboardModules.fixedSlot) return false
    val index = enabled.indexOf(id)
    val target = index + delta
    if (index < 0 || target !in enabled.indices) return false
    return enabled[target] !in DashboardModules.fixedSlot
}
