package com.zhechengqi.tollcat.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.TollCatSheet

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

    fun commit(next: List<String>) {
        val normalized = DashboardModules.normalized(next)
        modules = normalized
        onOrderChange(normalized)
    }

    TollCatSheet(onDismiss = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(stringResource(R.string.dashboard_edit), style = MaterialTheme.typography.headlineSmall)
            Text(
                stringResource(R.string.dashboard_edit_showing),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary,
            )
            enabled.forEach { id ->
                ModuleRow(
                    id = id,
                    checked = true,
                    canMoveUp = canMove(enabled, id, -1),
                    canMoveDown = canMove(enabled, id, 1),
                    onChecked = { on ->
                        commit(if (on) enabled + id else enabled - id)
                    },
                    onMove = { delta ->
                        val index = enabled.indexOf(id)
                        val next = enabled.toMutableList()
                        next[index] = next[index + delta].also { next[index + delta] = next[index] }
                        commit(next)
                    },
                )
            }
            Text(
                stringResource(R.string.dashboard_edit_reorder),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            if (disabled.isNotEmpty()) {
                Text(
                    stringResource(R.string.dashboard_edit_more),
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.primary,
                )
                disabled.forEach { id ->
                    ModuleRow(
                        id = id,
                        checked = false,
                        canMoveUp = false,
                        canMoveDown = false,
                        onChecked = { on ->
                            commit(if (on) enabled + id else enabled - id)
                        },
                        onMove = {},
                    )
                }
            }
            if (DashboardModules.BUDGET in enabled) {
                OutlinedTextField(
                    value = budget,
                    onValueChange = {
                        budget = it
                        onBudgetChange(it)
                    },
                    label = { Text(stringResource(R.string.dashboard_budget_usd)) },
                    supportingText = { Text(stringResource(R.string.dashboard_budget_hint)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (DashboardModules.SERVICES in enabled && accounts.isNotEmpty()) {
                Text(stringResource(R.string.module_pinned), style = MaterialTheme.typography.titleMedium)
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

@Composable
private fun ModuleRow(
    id: String,
    checked: Boolean,
    canMoveUp: Boolean,
    canMoveDown: Boolean,
    onChecked: (Boolean) -> Unit,
    onMove: (Int) -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.weight(1f)) {
                Text(stringResource(DashboardModules.titleRes(id)), style = MaterialTheme.typography.titleMedium)
                Text(
                    stringResource(DashboardModules.summaryRes(id)),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Switch(checked = checked, onCheckedChange = onChecked)
        }
        if (id !in DashboardModules.fixedSlot && checked && (canMoveUp || canMoveDown)) {
            Row {
                TextButton(onClick = { onMove(-1) }, enabled = canMoveUp) {
                    Text(stringResource(R.string.dashboard_edit_move_up))
                }
                TextButton(onClick = { onMove(1) }, enabled = canMoveDown) {
                    Text(stringResource(R.string.dashboard_edit_move_down))
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
