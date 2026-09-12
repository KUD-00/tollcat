package com.zhechengqi.tollcat.ui

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 失败 / 空读数 / 环境提示共用的状态条。
 *
 * iOS 靠图标颜色、不铺色块。Android 的 M3 Expressive 相反：
 * 辨识度来自 containment——errorContainer / secondaryContainer 整块填色，
 * 再配 extraLarge 圆角。不要在 surface 上写一行红字，那是网页 alert。
 * 次要说明也走 onContainer，不走 onSurfaceVariant，免得色块上浮一层灰。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun StatusBanner(
    title: String,
    symbol: MaterialSymbol,
    modifier: Modifier = Modifier,
    tone: StatusTone = StatusTone.Error,
    body: String? = null,
    nextStep: String? = null,
) {
    val colors = tone.colors()
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {},
        shape = MaterialTheme.shapes.extraLargeIncreased,
        color = colors.container,
        contentColor = colors.onContainer,
    ) {
        Row(
            modifier = Modifier.padding(20.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.Top,
        ) {
            Surface(
                modifier = Modifier.size(40.dp),
                shape = CircleShape,
                color = colors.iconContainer,
                contentColor = colors.onIcon,
            ) {
                Box(contentAlignment = Alignment.Center) {
                    SymbolIcon(symbol, contentDescription = null, filled = true, size = 20.dp)
                }
            }
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(title, style = MaterialTheme.typography.titleMediumEmphasized)
                if (!body.isNullOrBlank()) {
                    Text(body, style = MaterialTheme.typography.bodyMedium)
                }
                if (!nextStep.isNullOrBlank()) {
                    Text(nextStep, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
private fun StatusTone.colors(): StatusPalette {
    val scheme = MaterialTheme.colorScheme
    val semantic = LocalTollCatColors.current
    return when (this) {
        StatusTone.Error -> StatusPalette(
            container = scheme.errorContainer,
            onContainer = scheme.onErrorContainer,
            iconContainer = scheme.error,
            onIcon = scheme.onError,
        )
        StatusTone.Caution -> StatusPalette(
            container = scheme.secondaryContainer,
            onContainer = scheme.onSecondaryContainer,
            iconContainer = scheme.secondary,
            onIcon = scheme.onSecondary,
        )
        StatusTone.Neutral -> StatusPalette(
            container = scheme.surfaceContainerHigh,
            onContainer = scheme.onSurface,
            iconContainer = scheme.surfaceContainerHighest,
            onIcon = scheme.onSurfaceVariant,
        )
        StatusTone.Success -> StatusPalette(
            container = semantic.spendDown.container,
            onContainer = semantic.spendDown.onContainer,
            iconContainer = semantic.spendDown.main,
            onIcon = semantic.spendDown.onMain,
        )
    }
}

private data class StatusPalette(
    val container: Color,
    val onContainer: Color,
    val iconContainer: Color,
    val onIcon: Color,
)

@Preview(name = "Error Light", showBackground = true)
@Preview(name = "Error Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun StatusBannerErrorPreview() {
    TollCatTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatusBanner(
                title = "401",
                symbol = MaterialSymbol.Error,
                tone = StatusTone.Error,
                body = "这个 token 无效，或者已经被撤销了。",
                nextStep = "回上一步重新创建一把，创建后立刻复制——它只显示一次。",
            )
            StatusBanner(
                title = "连上了，但没有读到金额",
                symbol = MaterialSymbol.Info,
                tone = StatusTone.Caution,
                body = "这次返回里没有任何账单数字，不能当成 $0。",
                nextStep = "先别保存，回上一步检查权限后再测一次。",
            )
            StatusBanner(
                title = "网络不可用",
                symbol = MaterialSymbol.Warning,
                tone = StatusTone.Neutral,
                body = "请求没有到达服务器，不是凭据或权限的问题。",
                nextStep = "过一会儿再试。如果一直这样，先确认设备在线。",
            )
            StatusBanner(
                title = "本周期至今 $11.05",
                symbol = MaterialSymbol.CheckCircle,
                tone = StatusTone.Success,
                body = "周期 8/1 – 8/31 · 日粒度可用",
            )
        }
    }
}
