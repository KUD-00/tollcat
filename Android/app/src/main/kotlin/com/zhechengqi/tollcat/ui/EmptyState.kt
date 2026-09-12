package com.zhechengqi.tollcat.ui

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

/**
 * 仪表 / 服务 / 信箱 / 搜索共用的空态骨架。
 *
 * iOS 走 ContentUnavailableView 的居中四件套。Android 用 M3 Expressive
 * 的强调字号、形状容器、左对齐——居中会把这块收成 iOS 空态的皮。
 * 间距只走这一处，页面自己只填插画、文案和动作。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun EmptyState(
    title: String,
    modifier: Modifier = Modifier,
    size: EmptyStateSize = EmptyStateSize.Hero,
    body: String? = null,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    actionModifier: Modifier = Modifier,
    actionEnabled: Boolean = true,
    glyph: @Composable () -> Unit,
) {
    val compact = size == EmptyStateSize.Compact
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(
                horizontal = 24.dp,
                vertical = if (compact) 8.dp else 0.dp,
            ),
        horizontalAlignment = Alignment.Start,
        verticalArrangement = Arrangement.Top,
    ) {
        glyph()
        Spacer(Modifier.height(if (compact) 16.dp else 24.dp))
        Text(
            text = title,
            style = if (compact) {
                MaterialTheme.typography.headlineSmallEmphasized
            } else {
                MaterialTheme.typography.displaySmallEmphasized
            },
            color = MaterialTheme.colorScheme.onSurface,
        )
        if (!body.isNullOrBlank()) {
            Spacer(Modifier.height(if (compact) 8.dp else 12.dp))
            Text(
                text = body,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (actionLabel != null && onAction != null) {
            Spacer(Modifier.height(if (compact) 20.dp else 28.dp))
            val buttonModifier = if (compact) {
                actionModifier.fillMaxWidth()
            } else {
                actionModifier
            }
            PrimaryButton(
                onClick = onAction,
                enabled = actionEnabled,
                modifier = buttonModifier,
            ) {
                Text(actionLabel)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Preview(name = "Hero Light", showBackground = true)
@Preview(name = "Hero Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun EmptyStateHeroPreview() {
    TollCatTheme {
        EmptyState(
            title = "还没有账单",
            body = "接入第一家云服务之后，本月已经花了多少会显示在这里。",
            actionLabel = "添加第一个服务",
            onAction = {},
            glyph = {
                EmptyStateGlyph(
                    symbol = MaterialSymbol.Pets,
                    shape = MaterialShapes.Arch.toShape(),
                    size = 168.dp,
                    iconSize = 64.dp,
                )
            },
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Preview(name = "Compact Light", showBackground = true)
@Preview(name = "Compact Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun EmptyStateCompactPreview() {
    TollCatTheme {
        EmptyState(
            title = "还没有信箱",
            size = EmptyStateSize.Compact,
            body = "接入没有公开账单接口的服务时，会自动为你建一个。",
            actionLabel = "建信箱",
            onAction = {},
            glyph = {
                EmptyStateGlyph(
                    symbol = MaterialSymbol.Inbox,
                    shape = MaterialShapes.ClamShell.toShape(),
                )
            },
        )
    }
}
