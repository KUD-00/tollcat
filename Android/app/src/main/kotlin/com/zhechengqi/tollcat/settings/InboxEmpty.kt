package com.zhechengqi.tollcat.settings

import android.content.res.Configuration
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.EmptyState
import com.zhechengqi.tollcat.ui.EmptyStateGlyph
import com.zhechengqi.tollcat.ui.EmptyStateSize
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol

/**
 * 设置 → 读数信箱，还没建过时的空态。iOS 没有主按钮：信箱是接入没有
 * 公开账单接口的服务时自动建的。
 *
 * [onCreate] / [enabled] 留给画廊旧调用；空态本身不画动作。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun InboxEmpty(
    @Suppress("UNUSED_PARAMETER") onCreate: () -> Unit = {},
    modifier: Modifier = Modifier,
    @Suppress("UNUSED_PARAMETER") enabled: Boolean = true,
) {
    EmptyState(
        title = stringResource(R.string.settings_inbox_empty_title),
        modifier = modifier,
        size = EmptyStateSize.Compact,
        body = stringResource(R.string.settings_inbox_empty_body),
        glyph = {
            EmptyStateGlyph(
                symbol = MaterialSymbol.Inbox,
                shape = MaterialShapes.ClamShell.toShape(),
            )
        },
    )
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun InboxEmptyPreview() {
    TollCatTheme {
        InboxEmpty()
    }
}
