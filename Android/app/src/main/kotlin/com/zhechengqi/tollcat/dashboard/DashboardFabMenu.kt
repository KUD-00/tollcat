@file:OptIn(ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingActionButtonMenu
import androidx.compose.material3.FloatingActionButtonMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleFloatingActionButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 仪表盘的 FAB 菜单（画布 R3-1）：一颗 M3 Expressive ToggleFloatingActionButton，
 * 点开竖着长出三项——添加服务 / 加一笔固定订阅 / 编辑仪表盘。分享挪到了顶栏。
 * 展开时加号转成叉；背后的遮罩和返回键收起由 [DashboardFabScrim] 负责。
 */
@Composable
fun DashboardFabMenu(
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    onAddService: () -> Unit,
    onAddSubscription: () -> Unit,
    onEditDashboard: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val menuLabel = stringResource(R.string.dashboard_fab_menu)
    val closeLabel = stringResource(R.string.dashboard_fab_close)
    FloatingActionButtonMenu(
        expanded = expanded,
        modifier = modifier,
        horizontalAlignment = Alignment.End,
        button = {
            ToggleFloatingActionButton(
                checked = expanded,
                onCheckedChange = onExpandedChange,
                modifier = Modifier
                    .testTag("dashboard.fab")
                    .semantics {
                        contentDescription = if (expanded) closeLabel else menuLabel
                        stateDescription = if (expanded) closeLabel else menuLabel
                    },
            ) {
                val from = MaterialTheme.colorScheme.onPrimaryContainer
                val to = MaterialTheme.colorScheme.onPrimary
                SymbolIcon(
                    MaterialSymbol.Add,
                    contentDescription = null,
                    tint = lerp(from, to, checkedProgress),
                    modifier = Modifier.graphicsLayer { rotationZ = 45f * checkedProgress },
                )
            }
        },
    ) {
        FloatingActionButtonMenuItem(
            onClick = {
                onExpandedChange(false)
                onAddService()
            },
            text = { Text(stringResource(R.string.action_add_service)) },
            icon = { SymbolIcon(MaterialSymbol.Add, contentDescription = null) },
        )
        FloatingActionButtonMenuItem(
            onClick = {
                onExpandedChange(false)
                onAddSubscription()
            },
            text = { Text(stringResource(R.string.dashboard_add_subscription)) },
            icon = { SymbolIcon(MaterialSymbol.Payments, contentDescription = null) },
        )
        FloatingActionButtonMenuItem(
            onClick = {
                onExpandedChange(false)
                onEditDashboard()
            },
            text = { Text(stringResource(R.string.dashboard_edit)) },
            icon = { SymbolIcon(MaterialSymbol.Widgets, contentDescription = null) },
        )
    }
}

/** 菜单展开时盖在内容上的遮罩：点空白或按返回都收起。 */
@Composable
fun DashboardFabScrim(expanded: Boolean, onDismiss: () -> Unit, modifier: Modifier = Modifier) {
    BackHandler(enabled = expanded, onBack = onDismiss)
    AnimatedVisibility(visible = expanded, enter = fadeIn(), exit = fadeOut(), modifier = modifier) {
        Box(
            Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.scrim.copy(alpha = 0.32f))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = onDismiss,
                ),
        )
    }
}

@Preview(name = "Light", showBackground = true, heightDp = 360)
@Preview(name = "Dark", showBackground = true, heightDp = 360, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardFabMenuPreview() {
    TollCatTheme {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomEnd) {
            DashboardFabMenu(
                expanded = true,
                onExpandedChange = {},
                onAddService = {},
                onAddSubscription = {},
                onEditDashboard = {},
            )
        }
    }
}
