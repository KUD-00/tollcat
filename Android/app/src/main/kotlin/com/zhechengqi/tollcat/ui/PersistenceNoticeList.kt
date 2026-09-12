package com.zhechengqi.tollcat.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

data class PersistenceStatus(
    val containsDemoData: Boolean = false,
    val didFailToRead: Boolean = false,
    val didFailToWrite: Boolean = false,
    val isDemoBannerDismissed: Boolean = false,
) {
    val showsDemo: Boolean get() = containsDemoData && !isDemoBannerDismissed
    val isEmpty: Boolean get() = !showsDemo && !didFailToRead && !didFailToWrite
}

@Composable
fun PersistenceNoticeList(
    status: PersistenceStatus,
    modifier: Modifier = Modifier,
    onDismissDemo: (() -> Unit)? = null,
) {
    if (status.isEmpty) return
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs),
    ) {
        if (status.didFailToRead) {
            Text(
                text = stringResource(R.string.persistence_read_failed),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (status.didFailToWrite) {
            Text(
                text = stringResource(R.string.persistence_write_failed),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (status.showsDemo) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.persistence_demo),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1f),
                )
                if (onDismissDemo != null) {
                    IconButton(onClick = onDismissDemo) {
                        SymbolIcon(
                            MaterialSymbol.Close,
                            contentDescription = stringResource(R.string.persistence_dismiss_demo),
                        )
                    }
                }
            }
        }
    }
}
